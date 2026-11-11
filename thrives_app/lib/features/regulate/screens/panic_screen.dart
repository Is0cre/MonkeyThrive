import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_shell.dart';
import '../../settings/screens/crisis_directory_screen.dart';

// CLINICAL SAFETY — Panic sequence / physiological sigh
// What this does: On emergency button press, auto-plays 3 cycles of the
//   physiological sigh without requiring any input from the user. The screen
//   is black. One dim circle grows on the double inhale and shrinks on the
//   long exhale. Words, cards, and choices stay off until the three cycles
//   finish. After 3 cycles, offers access to Regulate tools.
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
  bool _done = false;
  bool _canVibrate = false;
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    beginTracking('Panic / Physiological Sigh', 'Regulate');
    _circleController = AnimationController(vsync: this);
    _circleAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_circleController);
    unawaited(_prepareHaptics());
    _startPhase(_Phase.inhale1);
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  Future<void> _prepareHaptics() async {
    try {
      final available = await Vibration.hasVibrator();
      if (!mounted) return;
      _canVibrate = available == true;
    } catch (_) {
      _canVibrate = false;
    }
  }

  void _pulse(int milliseconds) {
    HapticFeedback.lightImpact();
    if (!_canVibrate) return;
    unawaited(
      Vibration.vibrate(duration: milliseconds, amplitude: 48).catchError((_) {}),
    );
  }

  void _startPhase(_Phase phase) {
    switch (phase) {
      case _Phase.inhale1:
        _pulse(45);
      case _Phase.inhale2:
        _pulse(25);
      case _Phase.exhale:
        _pulse(70);
      case _Phase.between:
        break;
    }
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
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _done
                  ? _DoneView(
                      onGoRegulate: _goToRegulate,
                      onOpenDirectory: _openDirectory,
                    )
                  : _BreathView(circleAnim: _circleAnim),
            ),
            if (!_done)
              Positioned(
                left: 8,
                bottom: 8,
                child: Semantics(
                  button: true,
                  label: 'Leave',
                  child: GestureDetector(
                    onTap: _dismiss,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(width: 48, height: 48),
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
  final Animation<double> circleAnim;

  const _BreathView({required this.circleAnim});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Double inhale, long exhale',
      child: AnimatedBuilder(
        animation: circleAnim,
        builder: (context, _) {
          final t = circleAnim.value;
          final size = 150.0 + (t * 150.0);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8A6228).withValues(alpha: 0.16 + t * 0.20),
              border: Border.all(
                color: const Color(0xFFE8A645).withValues(alpha: 0.22 + t * 0.18),
                width: 1.5,
              ),
            ),
          );
        },
      ),
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
        TextButton(
          onPressed: onGoRegulate,
          child: const Text(
            'go to regulate',
            style: TextStyle(
              color: Color(0xFFE8A645),
              fontSize: 15,
              fontWeight: FontWeight.w500,
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
