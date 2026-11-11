import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/storage/session_log.dart';
import '../../../core/storage/tier_service.dart';
import '../../../core/theme/app_theme.dart';

// CLINICAL SAFETY — Window of Tolerance check-in
// What this does: Asks the user how they are right now before they enter the
//   app. The answer gates which tools are available in this session.
// Why it exists: Trauma tools are not interchangeable. The right tool in the
//   wrong state makes things worse. This check-in is the clinical intervention —
//   it routes the user to what is safe and appropriate for their current state.
// What happens if removed or modified: Users in acute dysregulated states may
//   access tools that are contraindicated, increasing risk of harm.
// Informed by: Marit Leito, clinical advisor / Siegel, Window of Tolerance.

class CheckInScreen extends StatefulWidget {
  final void Function(ToleranceState state) onComplete;

  const CheckInScreen({super.key, required this.onComplete});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  ToleranceState? _selected;
  bool _confirming = false;

  void _select(ToleranceState state) {
    setState(() => _selected = state);
  }

  Future<void> _confirm() async {
    if (_selected == null || _confirming) return;
    setState(() => _confirming = true);

    await PrefsService.saveWotState(_selected!);
    await SessionLog.logTolerance(ToleranceEntry(
      state: _selected!.name,
      timestamp: DateTime.now(),
    ));
    TierService.recheck(); // fire-and-forget

    widget.onComplete(_selected!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'how are you\nright now?',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'this shapes what\'s available to you',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              _StateOption(
                label: 'overwhelmed',
                description:
                    'anxious, scattered, can\'t settle, racing thoughts',
                color: const Color(0xFFDA3633),
                state: ToleranceState.hyperaroused,
                selected: _selected == ToleranceState.hyperaroused,
                onTap: () => _select(ToleranceState.hyperaroused),
              ),
              const SizedBox(height: 14),
              _StateOption(
                label: 'present',
                description: 'here and aware, able to make choices',
                color: AppColors.teal,
                state: ToleranceState.regulated,
                selected: _selected == ToleranceState.regulated,
                onTap: () => _select(ToleranceState.regulated),
              ),
              const SizedBox(height: 14),
              _StateOption(
                label: 'flat or numb',
                description: 'disconnected, low energy, hard to feel anything',
                color: const Color(0xFF6B8EAD),
                state: ToleranceState.hypoaroused,
                selected: _selected == ToleranceState.hypoaroused,
                onTap: () => _select(ToleranceState.hypoaroused),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _confirm,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: _confirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.teal,
                              ),
                            )
                          : const Text(
                              'continue',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateOption extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final ToleranceState state;
  final bool selected;
  final VoidCallback onTap;

  const _StateOption({
    required this.label,
    required this.description,
    required this.color,
    required this.state,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.6) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? color : AppColors.surfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: selected ? color : AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
