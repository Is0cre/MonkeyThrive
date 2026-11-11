import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/storage/session_log.dart';
import '../../../core/storage/tier_service.dart';
import '../../../core/theme/app_theme.dart';
import '../somatic_body_map.dart';
import '../somatic_map.dart';

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
  final Map<SomaticZone, SomaticQuality> _marks = {
    for (final zone in SomaticZone.values) zone: SomaticQuality.unmarked,
  };
  bool _explicitPresent = false;
  bool _confirming = false;

  ToleranceState? get _reading {
    if (_explicitPresent) return ToleranceState.regulated;
    return stateFromBodyMap(_marks);
  }

  void _tapZone(SomaticZone zone) {
    setState(() {
      _explicitPresent = false;
      _marks[zone] = nextQuality(_marks[zone] ?? SomaticQuality.unmarked);
    });
  }

  void _markPresent() {
    setState(() {
      _explicitPresent = true;
      for (final zone in SomaticZone.values) {
        _marks[zone] = SomaticQuality.unmarked;
      }
    });
  }

  Future<void> _confirm() async {
    final reading = _reading;
    if (reading == null || _confirming) return;
    setState(() => _confirming = true);

    await PrefsService.saveWotState(reading);
    await SessionLog.logTolerance(ToleranceEntry(
      state: reading.name,
      timestamp: DateTime.now(),
    ));
    TierService.recheck(); // fire-and-forget

    widget.onComplete(reading);
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
          children: [
            Text(
              'how are you\nright now?',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap where the body is speaking. Tap again to change it. '
              'This shapes what is available.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const _Legend(),
            const SizedBox(height: 8),
            SomaticBodyMap(marks: _marks, onTap: _tapZone),
            const SizedBox(height: 8),
            if (reading != null)
              Text(
                'this reads as ${reading.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            TextButton(
              onPressed: _markPresent,
              child: Text(
                'nothing stands out',
                style: TextStyle(
                  color: _explicitPresent
                      ? AppColors.teal
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: reading != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: reading == null ? null : _confirm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceVariant),
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
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Swatch(color: Color(0xFFDA3633), label: 'tight'),
        SizedBox(width: 16),
        _Swatch(color: Color(0xFF6B8EAD), label: 'heavy'),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;

  const _Swatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
