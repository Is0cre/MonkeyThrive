import 'package:flutter/material.dart';

import '../audio/acoustic_synthesis_gate.dart';
import '../theme/app_theme.dart';

/// Dismissible notice. Tapping outside or OK closes it and leaves the
/// current screen in place, so the rest of the app stays available.
class AcousticComingSoon {
  AcousticComingSoon._();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Coming soon',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            AcousticSynthesisGate.message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK', style: TextStyle(color: AppColors.teal)),
            ),
          ],
        );
      },
    );
  }
}

/// In-place explanation used when a whole tool is acoustic synthesis.
class AcousticSynthesisNotice extends StatelessWidget {
  const AcousticSynthesisNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.28),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.amber, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AcousticSynthesisGate.message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disabled feature row. The tap only opens the coming-soon dialog.
class AcousticUnavailableCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AcousticUnavailableCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => AcousticComingSoon.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.textMuted, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
