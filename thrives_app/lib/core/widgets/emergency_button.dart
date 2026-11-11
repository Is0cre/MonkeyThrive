import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/session_tracker.dart';
import '../../core/theme/app_theme.dart';
import '../../features/regulate/screens/panic_screen.dart';

// CLINICAL SAFETY — Emergency button (Bailout)
// What this does: Always-visible FAB that immediately halts any active audio,
//   tactile vibration, or visual stimulation via
//   SessionActivity.triggerEmergencyBailout() and launches the panic sequence
//   (physiological sigh × 3) without requiring navigation or decision-making.
// Why it exists: A person in acute distress cannot navigate menus, make
//   decisions, or tolerate ongoing bilateral/sensory stimulation while trying
//   to bail out. Uses rootNavigator so it works from any screen regardless of
//   navigation stack depth.
// What happens if removed: Person in crisis has no immediate intervention
//   available, and background stimulation may continue underneath.
// Informed by: Marit Leito, clinical advisor.

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  static void trigger(BuildContext context) {
    SessionActivity.triggerEmergencyBailout();
    HapticFeedback.heavyImpact();

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const PanicScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 80),
        reverseTransitionDuration: const Duration(milliseconds: 120),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => trigger(context),
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      tooltip: 'Emergency grounding',
      heroTag: null,
      child: const Icon(Icons.anchor_rounded, size: 28),
    );
  }
}
