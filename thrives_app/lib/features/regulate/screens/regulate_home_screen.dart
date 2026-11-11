import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_chrome.dart';
import 'breathing_screen.dart';
import 'physiological_sigh_screen.dart';
import 'grounding_521_screen.dart';
import 'cold_water_screen.dart';
import 'safe_place_screen.dart';
import 'vagal_screen.dart';
import 'wim_hof_screen.dart';

class RegulateHomeScreen extends StatelessWidget {
  const RegulateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToleranceState?>(
      valueListenable: WoTScope.of(context),
      builder: (context, wot, _) {
        return AppBackdrop(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 42),
                      child: AppHeader(
                        title: 'Regulate',
                        subtitle:
                            'Immediate tools for the state you are in now.',
                        icon: Icons.waves_rounded,
                        trailing: wot == null ? null : _StateChip(wot: wot),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const AppSectionLabel('Breathing',
                          icon: Icons.air_rounded),
                      const SizedBox(height: 12),
                      _ToolCard(
                        icon: Icons.air_rounded,
                        title: 'Box Breathing',
                        subtitle: '4-4-4-4 · Calm the nervous system',
                        color: AppColors.teal,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BreathingScreen(
                              mode: BreathingMode.box,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.air_rounded,
                        title: 'Physiological sigh',
                        subtitle: 'Double inhale + long exhale · Fastest reset',
                        color: AppColors.teal,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhysiologicalSighScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.nights_stay_rounded,
                        title: '4-7-8 Breathing',
                        subtitle: 'Sleep & acute anxiety',
                        color: AppColors.teal,
                        locked: wot != null && !wot.can4_7_8,
                        lockedReason: wot?.lockedReason,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BreathingScreen(
                              mode: BreathingMode.fourSevenEight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.waves_rounded,
                        title: 'Wim Hof Breathing',
                        subtitle: 'Guided round protocol',
                        color: AppColors.teal,
                        locked: wot != null && !wot.canWimHof,
                        lockedReason: wot?.lockedReason,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WimHofScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AppSectionLabel(
                        'Grounding',
                        icon: Icons.spa_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ToolCard(
                        icon: Icons.filter_5_rounded,
                        title: '5-4-3-2-1 Grounding',
                        subtitle: 'Sensory anchoring — bring yourself back',
                        color: AppColors.amber,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Grounding521Screen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.water_drop_rounded,
                        title: 'Cold Water',
                        subtitle: 'Diving reflex · Vagal activation',
                        color: AppColors.amber,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ColdWaterScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.landscape_rounded,
                        title: 'Safe Place',
                        subtitle: 'Guided visualisation with ambient sound',
                        color: AppColors.amber,
                        locked: wot != null && !wot.canSafePlace,
                        lockedReason: wot?.lockedReason,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SafePlaceScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AppSectionLabel(
                        'Vagal nerve activation',
                        icon: Icons.self_improvement_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ToolCard(
                        icon: Icons.self_improvement_rounded,
                        title: 'Vagal Prompts',
                        subtitle: 'Humming · Gargling · Extended exhale',
                        color: const Color(0xFF8B6FD4),
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VagalScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
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

class _StateChip extends StatelessWidget {
  final ToleranceState wot;
  const _StateChip({required this.wot});

  @override
  Widget build(BuildContext context) {
    final Color chipColor;
    switch (wot) {
      case ToleranceState.hyperaroused:
        chipColor = const Color(0xFFDA3633);
      case ToleranceState.regulated:
        chipColor = Theme.of(context).colorScheme.primary;
      case ToleranceState.hypoaroused:
        chipColor = const Color(0xFF6B8EAD);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chipColor,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            wot.displayName,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool locked;
  final String? lockedReason;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.locked,
    required this.onTap,
    this.lockedReason,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = color == AppColors.teal ? colors.primary : color;
    final effectiveColor = locked ? AppColors.textMuted : baseColor;
    return AppTile(
      icon: icon,
      title: title,
      subtitle: locked && lockedReason != null ? lockedReason! : subtitle,
      color: effectiveColor,
      muted: locked,
      onTap: locked ? null : onTap,
      trailing: locked
          ? const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 17,
            )
          : null,
    );
  }
}
