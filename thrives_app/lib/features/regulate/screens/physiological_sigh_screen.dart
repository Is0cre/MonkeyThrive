import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/haptics/breath_haptics_controller.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/count_slider.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';
import '../../../l10n/l10n.dart';

// CLINICAL SAFETY — Physiological sigh
// What this does: Guides the user through the physiological sigh — a double
//   nasal inhale followed by a long, slow exhale. Auto-plays without requiring
//   any input between cycles.
// Why it exists: The physiological sigh is the fastest known method to reduce
//   acute physiological stress in a single breath cycle. The second sniff
//   reinflates collapsed alveoli and maximises lung stretch receptor activation.
//   The long exhale activates the parasympathetic nervous system via the vagus
//   nerve, producing measurable HRV change within seconds.
//   Available in all Window of Tolerance states — safe for hyperarousal,
//   hypoarousal, and regulated states.
// What happens if removed or modified: A fast, accessible tool for acute
//   distress is lost. The panic button uses the same mechanism for this reason.
// Informed by: Marit Leito, clinical advisor / Balban et al. (2023),
//   "Brief structured respiration practices enhance mood and reduce physiological
//   arousal" — Cell Reports Medicine / Huberman Lab.

enum _SighPhase { inhale1, inhale2, exhale, rest }

const _inhale1Ms = 3000;
const _inhale2Ms = 1200;
const _exhaleMs = 7000;
const _restMs = 1000;
const _defaultRounds = 5;
const _minRounds = 2;
const _maxRounds = 30;

class PhysiologicalSighScreen extends StatefulWidget {
  final BreathHapticsController? haptics;

  const PhysiologicalSighScreen({super.key, this.haptics});

  @override
  State<PhysiologicalSighScreen> createState() =>
      _PhysiologicalSighScreenState();
}

class _PhysiologicalSighScreenState extends State<PhysiologicalSighScreen>
    with SingleTickerProviderStateMixin, SessionTracking {
  late AnimationController _circleController;

  int _targetRounds = _defaultRounds;
  int _round = 0;
  _SighPhase _phase = _SighPhase.inhale1;
  bool _running = false;
  bool _done = false;
  Timer? _phaseTimer;
  late final BreathHapticsController _haptics;
  bool _hapticsEnabled = true;
  DateTime? _phaseStarted;
  int _phaseMs = _inhale1Ms;

  @override
  void initState() {
    super.initState();
    _haptics = widget.haptics ?? BreathHapticsController();
    _circleController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _haptics.stopBreathingHaptics();
    _phaseTimer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  void _startStop() {
    if (_running) {
      _pause();
    } else if (_done) {
      _reset();
    } else {
      _start();
    }
  }

  void _start() {
    beginTracking('Physiological Sigh', 'Regulate', onEmergencyStop: _pause);
    setState(() {
      _running = true;
      _done = false;
      if (_round == 0) _round = 1;
    });
    _runPhase(_phase);
    HapticFeedback.lightImpact();
  }

  void _pause() {
    _phaseTimer?.cancel();
    _circleController.stop();
    _haptics.stopBreathingHaptics();
    endTracking();
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _phaseTimer?.cancel();
    _haptics.stopBreathingHaptics();
    _circleController.reset();
    setState(() {
      _round = 0;
      _phase = _SighPhase.inhale1;
      _running = false;
      _done = false;
    });
  }

  void _runPhase(_SighPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
    _phaseMs = _milliseconds(phase);
    _phaseStarted = DateTime.now();
    _paceHaptics(fromStart: true);

    switch (phase) {
      case _SighPhase.inhale1:
        _circleController.animateTo(
          0.62,
          duration: const Duration(milliseconds: _inhale1Ms),
          curve: AppMotion.breathe,
        );
        HapticFeedback.selectionClick();
        _phaseTimer = Timer(
          const Duration(milliseconds: _inhale1Ms),
          () => _runPhase(_SighPhase.inhale2),
        );

      case _SighPhase.inhale2:
        _circleController.animateTo(
          1.0,
          duration: const Duration(milliseconds: _inhale2Ms),
          curve: AppMotion.arrive,
        );
        _phaseTimer = Timer(
          const Duration(milliseconds: _inhale2Ms),
          () => _runPhase(_SighPhase.exhale),
        );

      case _SighPhase.exhale:
        _circleController.animateTo(
          0.0,
          duration: const Duration(milliseconds: _exhaleMs),
          curve: AppMotion.breathe,
        );
        HapticFeedback.selectionClick();
        _phaseTimer = Timer(
          const Duration(milliseconds: _exhaleMs),
          () => _runPhase(_SighPhase.rest),
        );

      case _SighPhase.rest:
        _phaseTimer = Timer(
          const Duration(milliseconds: _restMs),
          () {
            if (!mounted) return;
            if (_round >= _targetRounds) {
              _haptics.stopBreathingHaptics();
              setState(() {
                _running = false;
                _done = true;
              });
              HapticFeedback.mediumImpact();
            } else {
              setState(() {
                _round++;
                _phase = _SighPhase.inhale1;
              });
              _runPhase(_SighPhase.inhale1);
            }
          },
        );
    }
  }

  void _toggleHaptics() {
    setState(() => _hapticsEnabled = !_hapticsEnabled);
    if (_running) _paceHaptics(fromStart: false);
  }

  /// The motor follows this sigh. The rest is silence.
  void _paceHaptics({required bool fromStart}) {
    if (!_hapticsEnabled || !_running) {
      _haptics.stopBreathingHaptics();
      return;
    }
    var ms = _phaseMs;
    final started = _phaseStarted;
    if (!fromStart && started != null) {
      ms -= DateTime.now().difference(started).inMilliseconds;
    }
    unawaited(_haptics.playPhase(durationMs: ms, motion: _motion(_phase)));
  }

  int _milliseconds(_SighPhase phase) {
    switch (phase) {
      case _SighPhase.inhale1:
        return _inhale1Ms;
      case _SighPhase.inhale2:
        return _inhale2Ms;
      case _SighPhase.exhale:
        return _exhaleMs;
      case _SighPhase.rest:
        return _restMs;
    }
  }

  BreathHapticMotion _motion(_SighPhase phase) {
    switch (phase) {
      case _SighPhase.inhale1:
      case _SighPhase.inhale2:
        return BreathHapticMotion.rise;
      case _SighPhase.exhale:
        return BreathHapticMotion.fall;
      case _SighPhase.rest:
        return BreathHapticMotion.still;
    }
  }

  String _phaseLabel(AppLocalizations l10n) {
    if (_done) return l10n.sighDone;
    if (!_running && _round == 0) return '';
    switch (_phase) {
      case _SighPhase.inhale1:
        return l10n.sighCueIn;
      case _SighPhase.inhale2:
        return l10n.sighCueSniff;
      case _SighPhase.exhale:
        return l10n.sighCueOut;
      case _SighPhase.rest:
        return '';
    }
  }

  String _buttonLabel(AppLocalizations l10n) {
    if (_done) return l10n.sighAgain;
    if (_running) return l10n.sighPause;
    if (_round > 0) return l10n.sighResume;
    return l10n.sighBegin;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final circleSize = _done ? 88.0 : 180.0;
    final phaseLabel = _phaseLabel(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sighTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: const Key('breath-haptics-toggle'),
            tooltip:
                _hapticsEnabled ? l10n.breathHapticsOn : l10n.breathHapticsOff,
            onPressed: _toggleHaptics,
            icon: Icon(
              Icons.vibration,
              color: _hapticsEnabled
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Info banner ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.sighIntro,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // ── Breathing circle ────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Round counter
                          AnimatedOpacity(
                            opacity: _round > 0 && !_done ? 1.0 : 0.0,
                            duration: AppMotion.settle,
                            curve: AppMotion.arrive,
                            child: Text(
                              l10n.breathFraction(_round, _targetRounds),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Animated circle
                          AnimatedBuilder(
                            animation: _circleController,
                            builder: (context, _) {
                              final scale =
                                  0.45 + _circleController.value * 0.55;
                              final size = circleSize * scale;
                              final alpha =
                                  0.08 + _circleController.value * 0.14;
                              final borderAlpha =
                                  0.25 + _circleController.value * 0.5;
                              return SizedBox(
                                width: circleSize,
                                height: circleSize,
                                child: Center(
                                  child: Container(
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: alpha),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: borderAlpha),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Phase label
                          SizedBox(
                            height: 28,
                            child: AnimatedSwitcher(
                              duration: AppMotion.press,
                              switchInCurve: AppMotion.arrive,
                              switchOutCurve: AppMotion.depart,
                              child: Text(
                                phaseLabel,
                                key: ValueKey(phaseLabel),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Controls ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  if (!_running && _round == 0 && !_done) ...[
                    CountSlider(
                      label: l10n.sighRounds,
                      valueLabel: '$_targetRounds',
                      minLabel: '$_minRounds',
                      maxLabel: '$_maxRounds',
                      value: _targetRounds.toDouble(),
                      min: _minRounds.toDouble(),
                      max: _maxRounds.toDouble(),
                      divisions: _maxRounds - _minRounds,
                      enabled: true,
                      activeColor: Theme.of(context).colorScheme.primary,
                      sliderKey: const Key('sigh-round-slider'),
                      onChanged: (v) =>
                          setState(() => _targetRounds = v.round()),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_done) ...[
                    const FeelingBetterPrompt(),
                    const SizedBox(height: 16),
                  ],

                  // Begin / pause / resume / again
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _startStop,
                      style: FilledButton.styleFrom(
                        backgroundColor: _running
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: _running
                            ? AppColors.textPrimary
                            : Theme.of(context).scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(_buttonLabel(l10n)),
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
