import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';

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

class PhysiologicalSighScreen extends StatefulWidget {
  const PhysiologicalSighScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
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
    endTracking();
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _phaseTimer?.cancel();
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

    switch (phase) {
      case _SighPhase.inhale1:
        _circleController.animateTo(
          0.62,
          duration: const Duration(milliseconds: _inhale1Ms),
          curve: Curves.easeInOut,
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
          curve: Curves.easeOut,
        );
        _phaseTimer = Timer(
          const Duration(milliseconds: _inhale2Ms),
          () => _runPhase(_SighPhase.exhale),
        );

      case _SighPhase.exhale:
        _circleController.animateTo(
          0.0,
          duration: const Duration(milliseconds: _exhaleMs),
          curve: Curves.easeInOut,
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

  String get _phaseLabel {
    if (_done) return 'done';
    if (!_running && _round == 0) return '';
    switch (_phase) {
      case _SighPhase.inhale1:
        return 'breathe in through your nose';
      case _SighPhase.inhale2:
        return 'one more sniff';
      case _SighPhase.exhale:
        return 'breathe out slowly';
      case _SighPhase.rest:
        return '';
    }
  }

  String get _buttonLabel {
    if (_done) return 'again';
    if (_running) return 'pause';
    if (_round > 0) return 'resume';
    return 'begin';
  }

  @override
  Widget build(BuildContext context) {
    final circleSize = _done ? 88.0 : 180.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physiological sigh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Double inhale through the nose, then a long slow exhale. '
                  'One of the fastest ways to calm your nervous system.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // ── Breathing circle ────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Round counter
                    AnimatedOpacity(
                      opacity: _round > 0 && !_done ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '$_round / $_targetRounds',
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
                        final scale = 0.45 + _circleController.value * 0.55;
                        final size = circleSize * scale;
                        final alpha = 0.08 + _circleController.value * 0.14;
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
                                color: AppColors.teal.withValues(alpha: alpha),
                                border: Border.all(
                                  color: AppColors.teal
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
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _phaseLabel,
                          key: ValueKey(_phaseLabel),
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
            ),

            // ── Controls ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  if (!_running && _round == 0 && !_done) ...[
                    const Text(
                      'ROUNDS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final n in [3, 5, 10])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _targetRounds = n),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 56,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _targetRounds == n
                                      ? AppColors.teal.withValues(alpha: 0.15)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _targetRounds == n
                                        ? AppColors.teal
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$n',
                                    style: TextStyle(
                                      color: _targetRounds == n
                                          ? AppColors.teal
                                          : AppColors.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
                            ? AppColors.surfaceVariant
                            : AppColors.teal,
                        foregroundColor: _running
                            ? AppColors.textPrimary
                            : AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(_buttonLabel),
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
