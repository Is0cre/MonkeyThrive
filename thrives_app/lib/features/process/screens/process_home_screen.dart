import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import 'emdr_screen.dart';

class ProcessHomeScreen extends StatelessWidget {
  const ProcessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToleranceState?>(
      valueListenable: WoTScope.of(context),
      builder: (context, wot, _) {
        // CLINICAL SAFETY — bilateral stimulation access gate
        // What this does: Locks bilateral stimulation when user is not regulated.
        // Why it exists: Processing without a regulated nervous system risks
        //   retraumatisation. See tolerance_state.dart for full reasoning.
        // What happens if removed: Users in acute states access processing tools
        //   that require regulation as a prerequisite.
        // Informed by: Marit Leito, clinical advisor.
        final bilateralLocked = wot != null && !wot.canBilateral;
        final lockedReason = wot?.lockedReason ?? '';

        return Scaffold(
          floatingActionButton: const EmergencyButton(),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Process',
                            style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 6),
                        const Text(
                          'Deeper work. Use when regulated and ready.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'These tools are for processing, not crisis. '
                            'Make sure you feel regulated before starting.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ProcessCard(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Bilateral Stimulation',
                        subtitle: bilateralLocked && lockedReason.isNotEmpty
                            ? lockedReason
                            : 'between-session support, not therapy',
                        color: const Color(0xFF4A9EDA),
                        enabled: !bilateralLocked,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmdrScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProcessCard(
                        icon: Icons.accessibility_new_rounded,
                        title: 'EFT Tapping',
                        subtitle: 'Coming soon',
                        color: const Color(0xFF4A9EDA),
                        enabled: false,
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _ProcessCard(
                        icon: Icons.self_improvement_rounded,
                        title: 'Somatic Body Scan',
                        subtitle: 'Coming soon',
                        color: const Color(0xFF4A9EDA),
                        enabled: false,
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _ProcessCard(
                        icon: Icons.edit_note_rounded,
                        title: 'Trauma-informed Journaling',
                        subtitle: 'Coming soon',
                        color: const Color(0xFF4A9EDA),
                        enabled: false,
                        onTap: () {},
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ProcessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppColors.textMuted;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 20)
                else
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
