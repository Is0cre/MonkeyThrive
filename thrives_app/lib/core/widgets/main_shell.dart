import 'package:flutter/material.dart';
import '../../core/storage/tier_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/attune/screens/attune_home_screen.dart';
import '../../features/build/screens/build_home_screen.dart';
import '../../features/monitor/screens/monitor_home_screen.dart';
import '../../features/process/screens/process_home_screen.dart';
import '../../features/reflect/screens/reflect_home_screen.dart';
import '../../features/regulate/screens/regulate_home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'baseline_checkin_prompt.dart';
import 'emergency_button.dart';

/// Describes a single tab entry: the widget to show and its nav bar item.
/// [minTier] controls when the tab becomes visible:
///   1 = always (Regulate, Attune)
///   2 = after consistent Regulate practice
///   3 = after demonstrated journaling / WoT engagement
class _Tab {
  final Widget screen;
  final IconData icon;
  final String label;
  final int minTier;

  const _Tab({
    required this.screen,
    required this.icon,
    required this.label,
    required this.minTier,
  });
}

const _allTabs = [
  _Tab(
    screen: RegulateHomeScreen(),
    icon: Icons.waves_rounded,
    label: 'Regulate',
    minTier: 1,
  ),
  _Tab(
    screen: AttuneHomeScreen(),
    icon: Icons.music_note_rounded,
    label: 'Attune',
    minTier: 1,
  ),
  _Tab(
    screen: MonitorHomeScreen(),
    icon: Icons.favorite_border_rounded,
    label: 'Monitor',
    minTier: 2,
  ),
  _Tab(
    screen: BuildHomeScreen(),
    icon: Icons.eco_rounded,
    label: 'Build',
    minTier: 2,
  ),
  _Tab(
    screen: ReflectHomeScreen(),
    icon: Icons.auto_stories_rounded,
    label: 'Reflect',
    minTier: 2,
  ),
  _Tab(
    screen: ProcessHomeScreen(),
    icon: Icons.swap_horiz_rounded,
    label: 'Process',
    minTier: 3,
  ),
];

class MainShell extends StatefulWidget {
  final VoidCallback onResetOnboarding;

  const MainShell({
    super.key,
    required this.onResetOnboarding,
  });

  @override
  State<MainShell> createState() => _MainShellState();

  /// Switches to the Regulate tab from anywhere.
  /// Called after the panic sequence completes to land on Regulate tools.
  static void emergencyJumpToRegulate(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
    _MainShellState._current?.jumpToRegulate();
  }
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static _MainShellState? _current;

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  void jumpToRegulate() => setState(() => _index = 0);

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onResetOnboarding: widget.onResetOnboarding,
        ),
      ),
    );
  }

  List<_Tab> _visibleTabs(TierStatus tier) {
    final maxTier = tier.tier3
        ? 3
        : tier.tier2
            ? 2
            : 1;
    return _allTabs.where((t) => t.minTier <= maxTier).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TierStatus>(
      valueListenable: TierService.notifier,
      builder: (context, tier, _) {
        final colors = Theme.of(context).colorScheme;
        final tabs = _visibleTabs(tier);
        // Clamp index so it never goes out of range when tabs count changes
        final safeIndex = _index.clamp(0, tabs.length - 1);
        if (safeIndex != _index) {
          // Use post-frame callback to avoid setState during build
          WidgetsBinding.instance
              .addPostFrameCallback((_) => setState(() => _index = safeIndex));
        }

        return BaselineCheckInHost(
          child: Scaffold(
            body: Stack(
              children: [
                IndexedStack(
                  index: safeIndex,
                  children: tabs.map((t) => t.screen).toList(),
                ),
                // Settings button — top right, always accessible
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Material(
                    color: colors.surface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _openSettings,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.surfaceContainerHighest
                                .withValues(alpha: 0.82),
                          ),
                        ),
                        child: Icon(
                          Icons.settings_rounded,
                          color: colors.primary,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _ThriveNavBar(
              currentIndex: safeIndex,
              tabs: tabs,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        );
      },
    );
  }
}

class _ThriveNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;

  const _ThriveNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.88),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++) ...[
                  if (i == tabs.length ~/ 2) const _DockedAnchor(),
                  Expanded(
                    child: _NavItem(
                      tab: tabs[i],
                      selected: currentIndex == i,
                      onTap: () => onTap(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockedAnchor extends StatelessWidget {
  const _DockedAnchor();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Center(child: EmergencyButton()),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? colors.primary.withValues(alpha: 0.34)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tab.icon,
                  color: selected ? colors.primary : AppColors.textMuted,
                  size: 21,
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? colors.primary : AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
