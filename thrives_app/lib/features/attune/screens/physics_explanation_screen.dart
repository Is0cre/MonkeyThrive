import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../widgets/attune_listening.dart';

/// What the two tones are, and what they do not do to the nervous system.
class PhysicsExplanationScreen extends StatelessWidget {
  const PhysicsExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(l10n.physicsTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Text(
                  l10n.physicsLead,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _PhysicsCard(
                  icon: Icons.hearing_rounded,
                  title: l10n.physicsHearingTitle,
                  body: l10n.physicsHearingBody,
                ),
                const SizedBox(height: 12),
                _PhysicsCard(
                  icon: Icons.headphones_rounded,
                  title: l10n.physicsCarrierTitle,
                  body: l10n.physicsCarrierBody,
                ),
                const SizedBox(height: 12),
                _PhysicsCard(
                  icon: Icons.psychology_rounded,
                  title: l10n.physicsFollowingTitle,
                  body: l10n.physicsFollowingBody,
                ),
                const SizedBox(height: 12),
                _PhysicsCard(
                  icon: Icons.lightbulb_rounded,
                  title: l10n.physicsLampTitle,
                  body: l10n.physicsLampBody,
                  trailingIcon: Icons.flare_rounded,
                ),
              ],
            ),
          ),
          const _WarningBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  backgroundColor: attuneViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.close),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhysicsCard extends StatelessWidget {
  final IconData icon;
  final IconData? trailingIcon;
  final String title;
  final String body;

  const _PhysicsCard({
    required this.icon,
    required this.title,
    required this.body,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconWell(icon: icon),
              if (trailingIcon != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
                _IconWell(icon: trailingIcon!),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconWell extends StatelessWidget {
  final IconData icon;

  const _IconWell({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: attuneViolet.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: attuneViolet.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: attuneViolet, size: 22),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.dangerSurface,
        border: Border(
          top: BorderSide(color: AppColors.danger),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.physicsWarningKicker,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.physicsWarning,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
