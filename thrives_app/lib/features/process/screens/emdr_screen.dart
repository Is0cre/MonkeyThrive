import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import '../../../core/audio/acoustic_synthesis_gate.dart';
import '../../../core/audio/bilateral_cue_source.dart';
import '../../../core/audio/local_audio_cache.dart';
import '../../../core/widgets/acoustic_coming_soon.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

// CLINICAL SAFETY — Bilateral Stimulation (BLS)
// What this does: Provides alternating left/right visual, auditory, and tactile
//   bilateral stimulation with strict Window of Tolerance gating.
// Why it exists: Bilateral stimulation requires a regulated nervous system as a
//   container. In hyperaroused or hypoaroused states, processing tools risk
//   flooding or retraumatisation. Never labelled as EMDR in the UI.
// What happens if removed or modified: Users in dysregulated states could
//   trigger uncontained trauma processing.
// Informed by: Marit Leito, clinical advisor / Francine Shapiro, EMDR
//   preparation phase guidelines.

enum EmdrMode { visual, audio, tactile, visualAudio, visualTactile, all }

extension EmdrModeAudio on EmdrMode {
  bool get usesAcousticSynthesis =>
      this == EmdrMode.audio ||
      this == EmdrMode.visualAudio ||
      this == EmdrMode.all;
}

enum EmdrSpeed { slow, medium, fast }

// Session length options in minutes; 0 = unlimited
const _sessionOptions = [0, 5, 10, 15, 20, 30];

class EmdrScreen extends StatefulWidget {
  const EmdrScreen({super.key});

  @override
  State<EmdrScreen> createState() => _EmdrScreenState();
}

class _EmdrScreenState extends State<EmdrScreen>
    with TickerProviderStateMixin, SessionTracking {
  // ── settings ──────────────────────────────────────────────────────────────
  EmdrMode _mode = EmdrMode.visual;
  EmdrSpeed _speed = EmdrSpeed.medium;
  int _sessionMinutes = 0;
  double _dotSize = 28;
  Color _dotColor = AppColors.teal;

  // ── state ─────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _showSettings = true; // start on settings before first run
  final ValueNotifier<int> _sessionSecondsLeft = ValueNotifier<int>(0);
  Timer? _sessionTimer;

  // ── animation ─────────────────────────────────────────────────────────────
  late final AnimationController _dotController;
  late final Animation<double>
      _dotAnimation; // 0.0 = left edge, 1.0 = right edge

  // Players stay null while synthesis is gated, including during initState.
  AudioPlayer? _leftPlayer;
  AudioPlayer? _rightPlayer;
  bool _audioReady = false;

  // ── vibration ─────────────────────────────────────────────────────────────
  bool _canVibrate = false;

  // ── colour presets ────────────────────────────────────────────────────────
  final _colorOptions = const [
    AppColors.teal,
    AppColors.amber,
    Color(0xFF8B6FD4),
    Color(0xFF4A9EDA),
    Colors.white,
  ];

  int get _durationMs {
    switch (_speed) {
      case EmdrSpeed.slow:
        return 2000;
      case EmdrSpeed.medium:
        return 1200;
      case EmdrSpeed.fast:
        return 700;
    }
  }

  bool get _useVisual =>
      _mode == EmdrMode.visual ||
      _mode == EmdrMode.visualAudio ||
      _mode == EmdrMode.visualTactile ||
      _mode == EmdrMode.all;

  bool get _useTactile =>
      _mode == EmdrMode.tactile ||
      _mode == EmdrMode.visualTactile ||
      _mode == EmdrMode.all;

  bool get _useAudio =>
      AcousticSynthesisGate.enabled && _mode.usesAcousticSynthesis;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
    _dotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOutSine),
    );
    _dotController.addStatusListener(_onDotStatus);
    if (AcousticSynthesisGate.enabled) {
      unawaited(_initAudio());
    }
    unawaited(_checkVibration());
  }

  Future<void> _initAudio() async {
    if (!AcousticSynthesisGate.enabled) return;
    try {
      final leftSource = await LocalAudioCache.audioSource(
        'bilateral_left_v2',
        () => BilateralCueSource(right: false).bytes,
      );
      final rightSource = await LocalAudioCache.audioSource(
        'bilateral_right_v2',
        () => BilateralCueSource(right: true).bytes,
      );
      if (!mounted || !AcousticSynthesisGate.enabled) return;
      final leftPlayer = AudioPlayer();
      final rightPlayer = AudioPlayer();
      _leftPlayer = leftPlayer;
      _rightPlayer = rightPlayer;
      await leftPlayer.setAudioSource(leftSource, preload: true);
      await rightPlayer.setAudioSource(rightSource, preload: true);
      await leftPlayer.setVolume(0.9);
      await rightPlayer.setVolume(0.9);
      await leftPlayer.seek(Duration.zero);
      await rightPlayer.seek(Duration.zero);
      _audioReady = true;
    } catch (_) {
      _audioReady = false;
    }
  }

  Future<void> _checkVibration() async {
    try {
      _canVibrate = (await Vibration.hasVibrator()) == true;
    } catch (_) {
      _canVibrate = false;
    }
  }

  @override
  void dispose() {
    _dotController.removeStatusListener(_onDotStatus);
    _dotController.dispose();
    _sessionTimer?.cancel();
    _sessionSecondsLeft.dispose();
    _leftPlayer?.dispose();
    _rightPlayer?.dispose();
    super.dispose();
  }

  void _onDotStatus(AnimationStatus status) {
    if (!_running) return;
    if (status == AnimationStatus.completed) {
      // Dot reached right edge (1.0) -> trigger right stereo cue and reverse
      _triggerSide(right: true);
      _dotController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      // Dot reached left edge (0.0) -> trigger left stereo cue and move forward
      _triggerSide(right: false);
      _dotController.forward();
    }
  }

  void _triggerSide({required bool right}) {
    if (_useTactile && _canVibrate) {
      unawaited(Vibration.vibrate(duration: 40, amplitude: 80));
    }
    if (_useAudio) {
      _firePreCuedAudio(right: right);
    }
    if (!_useTactile && !_useAudio) {
      HapticFeedback.selectionClick();
    }
  }

  /// Plays the pre-rewound audio player immediately (zero seek latency at turn
  /// boundary) and rewinds the opposite channel while the dot travels across.
  void _firePreCuedAudio({required bool right}) {
    final activePlayer = right ? _rightPlayer : _leftPlayer;
    final idlePlayer = right ? _leftPlayer : _rightPlayer;
    if (!AcousticSynthesisGate.enabled ||
        !_audioReady ||
        activePlayer == null ||
        idlePlayer == null) {
      HapticFeedback.selectionClick();
      return;
    }

    unawaited(activePlayer.play().catchError((_) {
      HapticFeedback.selectionClick();
    }));

    unawaited(() async {
      try {
        await idlePlayer.pause();
        await idlePlayer.seek(Duration.zero);
      } catch (_) {}
    }());
  }

  void _start() {
    if (_mode.usesAcousticSynthesis && !AcousticSynthesisGate.enabled) {
      AcousticComingSoon.show(context);
      return;
    }
    final wot = WoTScope.stateOf(context);
    if (wot == null || !wot.canBilateral) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Bilateral stimulation is only available when present.'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    beginTracking(
      'Bilateral Stimulation',
      'Process',
      onEmergencyStop: _stop,
    );
    _dotController.duration = Duration(milliseconds: _durationMs);
    setState(() {
      _running = true;
      _showSettings = false;
      if (_sessionMinutes > 0 && _sessionSecondsLeft.value <= 0) {
        _sessionSecondsLeft.value = _sessionMinutes * 60;
      }
    });
    _triggerSide(right: false);
    _dotController.forward(from: 0);
    if (_sessionMinutes > 0) {
      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final next = _sessionSecondsLeft.value - 1;
        _sessionSecondsLeft.value = next;
        if (next <= 0) {
          _stop();
          _showCompletionMessage();
        }
      });
    }
  }

  void _stop() {
    _dotController.stop();
    _sessionTimer?.cancel();
    try {
      unawaited(Vibration.cancel());
    } catch (_) {}
    final leftPlayer = _leftPlayer;
    final rightPlayer = _rightPlayer;
    if (leftPlayer != null) unawaited(leftPlayer.pause());
    if (rightPlayer != null) unawaited(rightPlayer.pause());
    endTracking();
    if (mounted && _running) {
      setState(() => _running = false);
    }
  }

  void _showCompletionMessage() {
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Session complete',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Take a moment. Notice what came up, if anything.\n\n'
          'There is no right way to feel.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wot = WoTScope.of(context).value;
    if (_running && (wot == null || !wot.canBilateral)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _stop());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilateral Stimulation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_showSettings)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Settings',
              onPressed: () {
                _stop();
                setState(() => _showSettings = true);
              },
            ),
        ],
      ),
      floatingActionButton: const EmergencyButton(),
      body: SafeArea(
        child: _showSettings ? _buildSettings() : _buildSession(),
      ),
    );
  }

  // ── Settings panel ─────────────────────────────────────────────────────────

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      children: [
        // CLINICAL SAFETY — Required pre-session disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4A9EDA).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF4A9EDA), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy.\n'
                  'Bilateral stimulation — between-session support, not therapy.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const _SettingsSection('Mode'),
        _ModeSelector(
            selected: _mode, onSelect: (m) => setState(() => _mode = m)),
        const SizedBox(height: 24),
        const _SettingsSection('Speed'),
        _SpeedSelector(
            selected: _speed, onSelect: (s) => setState(() => _speed = s)),
        const SizedBox(height: 24),
        const _SettingsSection('Session length'),
        _SessionSelector(
          selected: _sessionMinutes,
          onSelect: (m) => setState(() {
            _sessionMinutes = m;
            _sessionSecondsLeft.value = m * 60;
          }),
        ),
        const SizedBox(height: 24),
        if (_useVisual) ...[
          const _SettingsSection('Dot size'),
          _SizeSlider(
            value: _dotSize,
            onChanged: (v) => setState(() => _dotSize = v),
          ),
          const SizedBox(height: 24),
          const _SettingsSection('Dot colour'),
          _ColorPicker(
            colors: _colorOptions,
            selected: _dotColor,
            onSelect: (c) => setState(() => _dotColor = c),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EDA),
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            child: const Text('Begin session'),
          ),
        ),
      ],
    );
  }

  // ── Session panel ─────────────────────────────────────────────────────────

  Widget _buildSession() {
    return Column(
      children: [
        // Session timer (isolated ValueListenableBuilder so ticks never rebuild canvas)
        if (_sessionMinutes > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ValueListenableBuilder<int>(
              valueListenable: _sessionSecondsLeft,
              builder: (_, secs, __) {
                final m = (secs ~/ 60).toString().padLeft(2, '0');
                final s = (secs % 60).toString().padLeft(2, '0');
                return Text(
                  '$m:$s',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),

        // Hardware-accelerated 60/120 fps canvas area
        Expanded(
          child: RepaintBoundary(
            child: _useVisual
                ? CustomPaint(
                    painter: _BilateralDotPainter(
                      animation: _dotAnimation,
                      dotSize: _dotSize,
                      dotColor: _dotColor,
                      trackColor: AppColors.surfaceVariant,
                    ),
                    size: Size.infinite,
                  )
                : Center(
                    child: AnimatedBuilder(
                      animation: _dotAnimation,
                      builder: (context, child) {
                        final pulse = math.sin(_dotAnimation.value * math.pi);
                        return Opacity(
                          opacity: 0.3 + pulse * 0.4,
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF4A9EDA),
                        size: 64,
                      ),
                    ),
                  ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
          child: Column(
            children: [
              // Mode chips
              Wrap(
                spacing: 8,
                children: [
                  _ModeChip(label: _modeName, color: const Color(0xFF4A9EDA)),
                  _ModeChip(label: _speedName, color: AppColors.textMuted),
                  if (_sessionMinutes > 0)
                    _ModeChip(
                        label: '${_sessionMinutes}m',
                        color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _running ? _stop : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: _running
                        ? AppColors.surfaceVariant
                        : const Color(0xFF4A9EDA),
                    foregroundColor:
                        _running ? AppColors.textPrimary : AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  child: Text(_running ? 'Pause' : 'Resume'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _modeName {
    switch (_mode) {
      case EmdrMode.visual:
        return 'Visual';
      case EmdrMode.audio:
        return 'Audio';
      case EmdrMode.tactile:
        return 'Tactile';
      case EmdrMode.visualAudio:
        return 'Visual + Audio';
      case EmdrMode.visualTactile:
        return 'Visual + Tactile';
      case EmdrMode.all:
        return 'Visual + Audio + Tactile';
    }
  }

  String get _speedName {
    switch (_speed) {
      case EmdrSpeed.slow:
        return 'Slow';
      case EmdrSpeed.medium:
        return 'Medium';
      case EmdrSpeed.fast:
        return 'Fast';
    }
  }
}

/// Renders the bilateral track and dot directly on the GPU canvas using
/// `super(repaint: animation)`, avoiding widget rebuilds and layout passes.
class _BilateralDotPainter extends CustomPainter {
  final Animation<double> animation;
  final double dotSize;
  final Color dotColor;
  final Color trackColor;

  late final Paint _trackPaint = Paint()
    ..color = trackColor
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  late final Paint _glowPaint = Paint()
    ..color = dotColor.withValues(alpha: 0.28)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  late final Paint _dotPaint = Paint()
    ..color = dotColor
    ..style = PaintingStyle.fill;

  _BilateralDotPainter({
    required this.animation,
    required this.dotSize,
    required this.dotColor,
    required this.trackColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 24.0;
    final cy = size.height / 2;
    final radius = dotSize / 2;

    canvas.drawLine(
      Offset(horizontalPadding, cy),
      Offset(size.width - horizontalPadding, cy),
      _trackPaint,
    );

    final usableWidth =
        math.max(0.0, size.width - (horizontalPadding * 2) - dotSize);
    final cx = horizontalPadding + radius + (animation.value * usableWidth);
    final center = Offset(cx, cy);

    canvas.drawCircle(center, radius + 3, _glowPaint);
    canvas.drawCircle(center, radius, _dotPaint);
  }

  @override
  bool shouldRepaint(_BilateralDotPainter oldDelegate) =>
      oldDelegate.dotSize != dotSize ||
      oldDelegate.dotColor != dotColor ||
      oldDelegate.trackColor != trackColor;
}

// ─── Settings widgets ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label;
  const _SettingsSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final EmdrMode selected;
  final ValueChanged<EmdrMode> onSelect;

  const _ModeSelector({required this.selected, required this.onSelect});

  static const _modes = [
    (EmdrMode.visual, 'Visual only', Icons.visibility_rounded),
    (EmdrMode.audio, 'Audio only', Icons.headphones_rounded),
    (EmdrMode.tactile, 'Tactile only', Icons.vibration_rounded),
    (EmdrMode.visualAudio, 'Visual + Audio', Icons.multitrack_audio_rounded),
    (EmdrMode.visualTactile, 'Visual + Tactile', Icons.touch_app_rounded),
    (EmdrMode.all, 'All three', Icons.layers_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final mode in _modes) ...[
          _ModeTile(
            label: mode.$2,
            icon: mode.$3,
            selected: selected == mode.$1,
            unavailable:
                mode.$1.usesAcousticSynthesis && !AcousticSynthesisGate.enabled,
            onTap: () {
              if (mode.$1.usesAcousticSynthesis &&
                  !AcousticSynthesisGate.enabled) {
                AcousticComingSoon.show(context);
                return;
              }
              onSelect(mode.$1);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool unavailable;
  final VoidCallback onTap;

  const _ModeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.unavailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = selected && !unavailable;
    return Opacity(
      opacity: unavailable ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFF4A9EDA).withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted ? const Color(0xFF4A9EDA) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: highlighted
                      ? const Color(0xFF4A9EDA)
                      : AppColors.textMuted,
                  size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: highlighted
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14)),
                    if (unavailable) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Coming soon',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (unavailable)
                const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textMuted, size: 16)
              else if (highlighted)
                const Icon(Icons.check_rounded,
                    color: Color(0xFF4A9EDA), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  final EmdrSpeed selected;
  final ValueChanged<EmdrSpeed> onSelect;

  const _SpeedSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in EmdrSpeed.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected == s
                      ? const Color(0xFF4A9EDA).withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == s
                        ? const Color(0xFF4A9EDA)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  s.name[0].toUpperCase() + s.name.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected == s
                        ? const Color(0xFF4A9EDA)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          if (s != EmdrSpeed.fast) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _SessionSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _SessionSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in _sessionOptions)
          GestureDetector(
            onTap: () => onSelect(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected == m
                    ? const Color(0xFF4A9EDA).withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected == m
                      ? const Color(0xFF4A9EDA)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                m == 0 ? 'Open' : '${m}m',
                style: TextStyle(
                  color: selected == m
                      ? const Color(0xFF4A9EDA)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _SizeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, color: AppColors.textMuted, size: 10),
        Expanded(
          child: Slider(
            value: value,
            min: 16,
            max: 52,
            divisions: 9,
            activeColor: const Color(0xFF4A9EDA),
            inactiveColor: AppColors.surfaceVariant,
            onChanged: onChanged,
          ),
        ),
        const Icon(Icons.circle, color: AppColors.textSecondary, size: 22),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const _ColorPicker(
      {required this.colors, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final c in colors) ...[
          GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected == c
                    ? [
                        BoxShadow(
                            color: c.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ModeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
