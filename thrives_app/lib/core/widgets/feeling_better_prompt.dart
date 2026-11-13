import 'package:flutter/material.dart';

import '../models/tolerance_state.dart';
import '../state/wot_scope.dart';
import '../storage/prefs_service.dart';
import '../storage/session_log.dart';
import '../storage/tier_service.dart';
import '../theme/app_theme.dart';

// CLINICAL SAFETY — feeling-better check
// What this does: After an exercise ends, asks whether the user feels better.
//   Yes records today's reading as present. Not yet leaves the reading as it is.
// Why it exists: The user is the authority on their own state. The app does
//   not decide they have settled. Gated tools and trusted-person setup open
//   only after they say yes.
// What happens if removed: A finished exercise cannot move today's reading
//   to present, so setup and gated tools stay closed after overwhelm.

enum PresentMark { recorded, already, unavailable }

/// Records today's reading as present. Already-present is a no-op.
Future<PresentMark> recordPresentReading(BuildContext context) async {
  final notifier =
      context.dependOnInheritedWidgetOfExactType<WoTScope>()?.notifier;
  if (notifier == null) return PresentMark.unavailable;
  if (notifier.value == ToleranceState.regulated) return PresentMark.already;
  notifier.value = ToleranceState.regulated;
  await PrefsService.saveWotState(ToleranceState.regulated);
  await SessionLog.logTolerance(ToleranceEntry(
    state: ToleranceState.regulated.name,
    timestamp: DateTime.now(),
  ));
  TierService.recheck();
  return PresentMark.recorded;
}

/// Shown when an exercise has actually finished.
class FeelingBetterPrompt extends StatefulWidget {
  const FeelingBetterPrompt({super.key});

  @override
  State<FeelingBetterPrompt> createState() => _FeelingBetterPromptState();
}

class _FeelingBetterPromptState extends State<FeelingBetterPrompt> {
  PresentMark? _mark;
  bool _notYet = false;
  bool _busy = false;

  Future<void> _yes() async {
    if (_busy || _mark != null || _notYet) return;
    setState(() => _busy = true);
    final mark = await recordPresentReading(context);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _mark = mark;
    });
  }

  void _notYetPressed() {
    if (_busy || _mark != null || _notYet) return;
    setState(() => _notYet = true);
  }

  @override
  Widget build(BuildContext context) {
    final result = _resultText;
    if (result != null) {
      return Text(
        result,
        key: const Key('feeling-better-result'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Are you feeling better?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('feeling-better-yes'),
                  onPressed: _busy ? null : _yes,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: const Color(0xFF1A140C),
                    disabledBackgroundColor: AppColors.amberDim,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  key: const Key('feeling-better-not-yet'),
                  onPressed: _busy ? null : _notYetPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.amber),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Not yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? get _resultText {
    if (_notYet) return 'The reading stays as it is.';
    switch (_mark) {
      case PresentMark.recorded:
        return 'Marked as present.';
      case PresentMark.already:
        return 'Still marked as present.';
      case PresentMark.unavailable:
        return 'The reading could not be saved.';
      case null:
        return null;
    }
  }
}
