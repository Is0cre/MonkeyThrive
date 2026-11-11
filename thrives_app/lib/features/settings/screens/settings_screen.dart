import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/baseline/baseline_models.dart';
import '../../../core/baseline/baseline_monitor.dart';
import '../../../core/storage/tier_service.dart';
import '../../../core/theme/app_appearance.dart';
import '../../../core/theme/app_theme.dart';
import 'crisis_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onResetOnboarding;
  const SettingsScreen({super.key, required this.onResetOnboarding});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Data management ─────────────────────────────────────────────────────────

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all data?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will permanently delete:\n\n'
          '• Journal entries\n'
          '• HRV readings\n'
          '• Check-in history\n'
          '• Baseline feedback history\n'
          '• Session log\n'
          '• Safe place description\n\n'
          'This cannot be undone.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared.'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AppAppearanceController.instance.notifier.value =
        const AppearanceSettings();

    // Reset tier notifier in memory
    TierService.notifier.value = const TierStatus(tier2: false, tier3: false);
    widget.onResetOnboarding();
  }

  Future<void> _showBaselinePromptPreview(BuildContext context) async {
    final now = DateTime.now();
    final shown = await BaselineMonitor.instance.showManualPrompt(
      NotificationDecision(
        sensorSnapshotId: 'manual-settings-${now.microsecondsSinceEpoch}',
        modelConfidence: 1.0,
        baselineVersion: 1,
        shouldNotify: true,
        decidedAt: now,
      ),
    );

    if (!context.mounted) return;
    if (shown) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A check-in is already open.'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w400),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
          children: [
            // ── About ───────────────────────────────────────────────────────
            _Section('About'),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'THRIVES',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'v0.1.0',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Built from lived experience.\nFor everyone who is still here.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Open source · No ads · No data collection · Free forever.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const _RowDetail(
                    icon: Icons.code_rounded,
                    text: 'github.com/Is0cre/THRIVE',
                  ),
                  const SizedBox(height: 6),
                  const _RowDetail(
                    icon: Icons.balance_rounded,
                    text: 'GPL-3.0 · non-military, non-intelligence use only',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Appearance ──────────────────────────────────────────────────
            _Section('Appearance'),
            const _AppearancePanel(),

            const SizedBox(height: 24),

            // ── Safety ──────────────────────────────────────────────────────
            _Section('Safety'),
            _TileButton(
              icon: Icons.emergency_rounded,
              iconColor: AppColors.danger,
              label: 'Crisis resources',
              subtitle: 'Crisis lines for Malta and internationally',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrisisScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.forum_outlined,
              iconColor: AppColors.teal,
              label: 'Show baseline check-in',
              subtitle: 'Preview the local prompt implementation',
              onTap: () => _showBaselinePromptPreview(context),
            ),

            const SizedBox(height: 24),

            // ── Clinical advisory ────────────────────────────────────────────
            _Section('Clinical advisory'),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The safety architecture, tool routing, and trauma-informed '
                    'design of THRIVES is shaped by clinical input from:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _AdvisorCard(
                    name: 'Marit Leito',
                    role: 'Psychologist · Clinical Advisor',
                    detail:
                        'Window of Tolerance architecture · trauma-informed '
                        'tool routing · somatic regulation protocols',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Advisory credits reflect input on design and safety '
                    'protocols. THRIVES is a wellness support tool, not a '
                    'clinical service.',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Privacy ─────────────────────────────────────────────────────
            _Section('Privacy'),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your entries stay on this device.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Zero network requests. Zero analytics. Zero crash reporting. '
                    'Everything you enter — check-ins, '
                    'journal entries, HRV readings, your safe place description '
                    '— is stored only on this device.\n\n'
                    'We cannot provide your data to anyone because we do '
                    'not have it.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _RowDetail(
                      icon: Icons.storage_rounded,
                      text: 'Journal entries — device only'),
                  const SizedBox(height: 5),
                  const _RowDetail(
                      icon: Icons.storage_rounded,
                      text: 'HRV readings — device only'),
                  const SizedBox(height: 5),
                  const _RowDetail(
                      icon: Icons.storage_rounded,
                      text: 'Check-in history — device only'),
                  const SizedBox(height: 5),
                  const _RowDetail(
                      icon: Icons.storage_rounded,
                      text: 'Session log — device only'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Disclaimer ───────────────────────────────────────────────────
            _Section('Disclaimer'),
            _InfoCard(
              child: const Text(
                'THRIVES is a wellness support tool. It does not diagnose, '
                'assess, or treat any condition, and is not a replacement for '
                'therapy or medical care.\n\n'
                'If you are in crisis, please reach out to a professional or '
                'use the crisis resources listed above.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Your data ────────────────────────────────────────────────────
            _Section('Your data'),
            _TileButton(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.danger,
              label: 'Clear all data',
              subtitle: 'Journal, HRV, check-ins, session log, safe place',
              onTap: () => _confirmClearData(context),
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.refresh_rounded,
              iconColor: AppColors.textMuted,
              label: 'Redo onboarding',
              subtitle: 'Reset your profile questionnaire',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Redo onboarding?',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text(
                      'Your profile will be reset and you\'ll go through the '
                      'questionnaire again. Your history is not affected.',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset',
                            style: TextStyle(color: AppColors.teal)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) widget.onResetOnboarding();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.surfaceContainerHighest),
      ),
      child: child,
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceSettings>(
      valueListenable: AppAppearanceController.instance.notifier,
      builder: (context, appearance, _) {
        return _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accent',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final accent in AppAccent.values) ...[
                    Expanded(
                      child: _AccentSwatch(
                        accent: accent,
                        selected: appearance.accent == accent,
                      ),
                    ),
                    if (accent != AppAccent.values.last)
                      const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Contrast',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _ContrastSelector(selected: appearance.contrast),
            ],
          ),
        );
      },
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AppAccent accent;
  final bool selected;

  const _AccentSwatch({
    required this.accent,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppearanceSettings(accent: accent);
    final color = settings.accentColor;
    return Semantics(
      button: true,
      selected: selected,
      label: accent.name,
      child: GestureDetector(
        onTap: () => AppAppearanceController.instance.setAccent(accent),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.background,
                      size: 14,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContrastSelector extends StatelessWidget {
  final AppContrast selected;

  const _ContrastSelector({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final contrast in AppContrast.values) ...[
          Expanded(
            child: _ContrastChip(
              contrast: contrast,
              selected: selected == contrast,
            ),
          ),
          if (contrast != AppContrast.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ContrastChip extends StatelessWidget {
  final AppContrast contrast;
  final bool selected;

  const _ContrastChip({
    required this.contrast,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final label = switch (contrast) {
      AppContrast.soft => 'Soft',
      AppContrast.standard => 'Standard',
      AppContrast.high => 'High',
    };
    return GestureDetector(
      onTap: () => AppAppearanceController.instance.setContrast(contrast),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.16)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RowDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RowDetail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 13),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  final String name;
  final String role;
  final String detail;
  const _AdvisorCard({
    required this.name,
    required this.role,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TileButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
