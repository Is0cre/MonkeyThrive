import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

enum BreathingMode { box, fourSevenEight }

// Describes one phase of a breathing cycle
class _Phase {
  final String label;
  final int durationSeconds;
  const _Phase(this.label, this.durationSeconds);
}

class BreathingScreen extends StatefulWidget {
  final BreathingMode mode;
  const BreathingScreen({super.key, required this.mode});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin, SessionTracking {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  bool _running = false;
  int _phaseIndex = 0;
  int _secondsLeft = 0;
  int _cycleCount = 0;
  Timer? _timer;

  // Box breathing variants
  int _boxCount = 4; // 3, 4, or 5

  List<_Phase> get _phases {
    switch (widget.mode) {
      case BreathingMode.box:
        return [
          _Phase('Inhale', _boxCount),
          _Phase('Hold', _boxCount),
          _Phase('Exhale', _boxCount),
          _Phase('Hold', _boxCount),
        ];
      case BreathingMode.fourSevenEight:
        return [
          _Phase('Inhale', 4),
          _Phase('Hold', 7),
          _Phase('Exhale', 8),
        ];
    }
  }

  _Phase get _currentPhase => _phases[_phaseIndex];

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this);
    _circleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  void _startStop() {
    if (_running) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    final wot = WoTScope.stateOf(context);
    if (widget.mode == BreathingMode.fourSevenEight &&
        (wot == null || !wot.can4_7_8)) {
      _showLockedMessage(wot);
      return;
    }

    final toolName =
        widget.mode == BreathingMode.box ? 'Box Breathing' : '4-7-8 Breathing';
    beginTracking(toolName, 'Regulate', onEmergencyStop: _pause);
    setState(() {
      _running = true;
      _phaseIndex = 0;
      _secondsLeft = _currentPhase.durationSeconds;
    });
    _animatePhase();
    _startTimer();
  }

  void _showLockedMessage(ToleranceState? wot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wot == null
              ? 'Check in before using 4-7-8 breathing.'
              : '4-7-8 breathing is ${wot.lockedReason}.',
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _pause() {
    _timer?.cancel();
    _circleController.stop();
    endTracking();
    if (mounted) setState(() => _running = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _nextPhase();
        }
      });
    });
  }

  void _nextPhase() {
    _phaseIndex = (_phaseIndex + 1) % _phases.length;
    if (_phaseIndex == 0) {
      _cycleCount++;
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    _secondsLeft = _currentPhase.durationSeconds;
    _animatePhase();
  }

  void _animatePhase() {
    _circleController.stop();
    final phaseName = _currentPhase.label;
    final duration = Duration(seconds: _currentPhase.durationSeconds);

    if (phaseName == 'Inhale') {
      _circleController.animateTo(1.0,
          duration: duration, curve: Curves.easeInOut);
    } else if (phaseName == 'Exhale') {
      _circleController.animateTo(0.4,
          duration: duration, curve: Curves.easeInOut);
    }
    // Hold phases — circle stays still
  }

  void _reset() {
    _pause();
    setState(() {
      _phaseIndex = 0;
      _secondsLeft = 0;
      _cycleCount = 0;
      _circleController.value = 0.4;
    });
  }

  String get _title {
    switch (widget.mode) {
      case BreathingMode.box:
        return 'Box Breathing';
      case BreathingMode.fourSevenEight:
        return '4-7-8 Breathing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBox = widget.mode == BreathingMode.box;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _reset();
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.mode == BreathingMode.fourSevenEight)
              _InfoBanner(
                '4-7-8 breathing is very effective for acute anxiety and sleep. '
                'If you feel dizzy, stop and breathe normally.',
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated circle
                  AnimatedBuilder(
                    animation: _circleAnimation,
                    builder: (context, _) {
                      final size = MediaQuery.of(context).size.width * 0.55;
                      return SizedBox(
                        width: size,
                        height: size,
                        child: CustomPaint(
                          painter: _BreathCirclePainter(
                            progress: _circleAnimation.value,
                            color: AppColors.teal,
                            isRunning: _running,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Phase label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _running ? _currentPhase.label : '',
                      key: ValueKey(_running ? _currentPhase.label : 'idle'),
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seconds countdown — gentle, not aggressive
                  Text(
                    _running ? '$_secondsLeft' : '',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cycleCount > 0 ? 'Cycle $_cycleCount' : '',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  if (isBox) ...[
                    _CountSelector(
                      current: _boxCount,
                      enabled: !_running,
                      onChanged: (v) => setState(() => _boxCount = v),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _startStop,
                      style: FilledButton.styleFrom(
                        backgroundColor: _running
                            ? AppColors.surfaceVariant
                            : AppColors.teal,
                        foregroundColor: _running
                            ? AppColors.textPrimary
                            : AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _running
                            ? 'Pause'
                            : (_cycleCount > 0 ? 'Resume' : 'Begin'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRunning;

  _BreathCirclePainter({
    required this.progress,
    required this.color,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final radius = maxRadius * progress;

    // Outer glow ring
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centre, maxRadius, glowPaint);

    // Main circle
    final circlePaint = Paint()
      ..color = color.withValues(alpha: isRunning ? 0.18 : 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centre, radius, circlePaint);

    // Border ring
    final borderPaint = Paint()
      ..color = color.withValues(alpha: isRunning ? 0.7 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(centre, radius, borderPaint);
  }

  @override
  bool shouldRepaint(_BreathCirclePainter old) =>
      old.progress != progress || old.isRunning != isRunning;
}

class _CountSelector extends StatelessWidget {
  final int current;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _CountSelector({
    required this.current,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Count',
          style: TextStyle(
            color: enabled ? AppColors.textSecondary : AppColors.textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        for (final count in [3, 4, 5]) ...[
          GestureDetector(
            onTap: enabled ? () => onChanged(count) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: current == count
                    ? AppColors.teal.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: current == count
                      ? AppColors.teal
                      : AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: current == count
                      ? AppColors.teal
                      : (enabled
                          ? AppColors.textSecondary
                          : AppColors.textMuted),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}
