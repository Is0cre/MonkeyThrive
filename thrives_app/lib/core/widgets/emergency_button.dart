import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/session_tracker.dart';
import '../../core/theme/app_theme.dart';
import '../../features/regulate/screens/panic_screen.dart';

// CLINICAL SAFETY — Emergency button (Bailout)
// What this does: A docked anchor, and the Android volume keys, immediately
//   halt any active audio, tactile vibration, or visual stimulation via
//   SessionActivity.triggerEmergencyBailout() and launch the panic sequence
//   (physiological sigh × 3) without requiring navigation or decision-making.
// Why it exists: A person in acute distress cannot navigate menus, make
//   decisions, or tolerate ongoing bilateral/sensory stimulation while trying
//   to bail out. The control sits in the bottom bar so it stays reachable
//   and does not cover the screen. Volume keys allow a no-look press.
//   Uses rootNavigator so it works from any screen regardless of navigation
//   stack depth.
// What happens if removed: Person in crisis has no immediate intervention
//   available, and background stimulation may continue underneath.
// Informed by: Marit Leito, clinical advisor.

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  static bool _visible = false;

  static void trigger(BuildContext context) {
    open(Navigator.of(context, rootNavigator: true));
  }

  /// Opens the sigh on [navigator]. Volume keys use the root navigator state
  /// directly; a dock tap arrives with a context under that navigator.
  static void open(NavigatorState navigator) {
    if (_visible) return;
    _visible = true;
    SessionActivity.triggerEmergencyBailout();
    HapticFeedback.heavyImpact();

    navigator
        .push(
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
    )
        .whenComplete(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Anchor',
      child: Material(
        color: AppColors.danger,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => trigger(context),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.anchor_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

/// Bottom safe-area slot for screens that cover the main dock.
class AnchorBar extends StatelessWidget {
  const AnchorBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: const SizedBox(
          height: 72,
          child: Center(child: EmergencyButton()),
        ),
      ),
    );
  }
}
