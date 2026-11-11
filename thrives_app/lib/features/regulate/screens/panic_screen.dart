import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_shell.dart';
import '../../settings/screens/crisis_directory_screen.dart';

// CLINICAL SAFETY — Panic sequence / physiological sigh
// What this does: On emergency button press, auto-plays 3 cycles of the
//   physiological sigh without requiring any input from the user. After
//   3 cycles, offers access to Regulate tools.
// Why it exists: A person in acute distress cannot navigate menus, make
//   decisions, or find tools. The panic button must require zero cognitive
//   load. The physiological sigh is the fastest known method to reduce
//   acute physiological stress — double inhale engages lung stretch receptors,
//   long exhale activates the parasympathetic nervous system via the vagus
//   nerve. Three cycles is enough to produce measurable HRV change.
// What happens if removed or modified: Person in crisis is left navigating
//   a menu system when they cannot think. This is a failure mode.
// Informed by: Marit Leito, clinical advisor / Huberman Lab physiological
//   sigh research (Balban et al., 2023) / Porges, Polyvagal Theory.

enum _Phase { inhale1, inhale2, exhale, between }

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen>
    with SingleTickerProviderStateMixin, SessionTracking {
  static const _totalCycles = 3;
  static const _inhale1Ms = 3000;
  static const _inhale2Ms = 1200;
  static const _exhaleMs = 6000;
  static const _betweenMs = 800;

  late AnimationController _circleController;
  late Animation<double> _circleAnim;

  int _cycle = 1;
  _Phase _phase = _Phase.inhale1;
  bool _done = false;
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    beginTracking('Panic / Physiological Sigh', 'Regulate');
    _circleController = AnimationController(vsync: this);
    _circleAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_circleController);
    _startPhase(_Phase.inhale1);
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  void _startPhase(_Phase phase) {
    setState(() => _phase = phase);

    switch (phase) {
      case _Phase.inhale1:
        _circleController.animateTo(
          0.65,
          duration: const Duration(milliseconds: _inhale1Ms),
          curve: Curves.easeInOut,
        );
        _phaseTimer = Timer(const Duration(milliseconds: _inhale1Ms), () {
          if (mounted) _startPhase(_Phase.inhale2);
        });

      case _Phase.inhale2:
        _circleController.animateTo(
          1.0,
          duration: const Duration(milliseconds: _inhale2Ms),
          curve: Curves.easeOut,
        );
        _phaseTimer = Timer(const Duration(milliseconds: _inhale2Ms), () {
          if (mounted) _startPhase(_Phase.exhale);
        });

      case _Phase.exhale:
        _circleController.animateTo(
          0.0,
          duration: const Duration(milliseconds: _exhaleMs),
          curve: Curves.easeInOut,
        );
        _phaseTimer = Timer(const Duration(milliseconds: _exhaleMs), () {
          if (mounted) _startPhase(_Phase.between);
        });

      case _Phase.between:
        _phaseTimer = Timer(const Duration(milliseconds: _betweenMs), () {
          if (!mounted) return;
          if (_cycle >= _totalCycles) {
            setState(() => _done = true);
          } else {
            setState(() => _cycle++);
            _startPhase(_Phase.inhale1);
          }
        });
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _Phase.inhale1:
        return 'breathe in';
      case _Phase.inhale2:
        return 'one more sniff';
      case _Phase.exhale:
        return 'breathe out slowly';
      case _Phase.between:
        return '';
    }
  }

  void _goToRegulate() {
    Navigator.of(context, rootNavigator: true).pop();
    MainShell.emergencyJumpToRegulate(context);
  }

  void _dismiss() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _openDirectory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CrisisDirectoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: _done
                  ? _DoneView(
                      onGoRegulate: _goToRegulate,
                      onOpenDirectory: _openDirectory,
                    )
                  : _BreathView(
                      cycle: _cycle,
                      totalCycles: _totalCycles,
                      phaseLabel: _phaseLabel,
                      circleAnim: _circleAnim,
                    ),
            ),

            // Unobtrusive dismiss — for accidental taps
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: _dismiss,
                child: const Text(
                  'I\'m ok',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathView extends StatelessWidget {
  final int cycle;
  final int totalCycles;
  final String phaseLabel;
  final Animation<double> circleAnim;

  const _BreathView({
    required this.cycle,
    required this.totalCycles,
    required this.phaseLabel,
    required this.circleAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$cycle of $totalCycles',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 48),
        AnimatedBuilder(
          animation: circleAnim,
          builder: (context, _) {
            final size = 120.0 + (circleAnim.value * 100.0);
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal
                    .withValues(alpha: 0.08 + circleAnim.value * 0.12),
                border: Border.all(
                  color: AppColors.teal
                      .withValues(alpha: 0.3 + circleAnim.value * 0.4),
                  width: 1.5,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            phaseLabel,
            key: ValueKey(phaseLabel),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  final VoidCallback onGoRegulate;
  final VoidCallback onOpenDirectory;

  const _DoneView({
    required this.onGoRegulate,
    required this.onOpenDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'you\'re here.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'take your time.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 56),
        GestureDetector(
          onTap: onGoRegulate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: const Text(
              'go to regulate',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onOpenDirectory,
          child: const Text(
            'call a crisis line',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
