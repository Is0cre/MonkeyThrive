import 'package:flutter/material.dart';
import 'package:monkeythrive/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/baseline/baseline_models.dart';
import '../../../core/baseline/baseline_monitor.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/tier_service.dart';
import '../../../core/storage/vault_service.dart';
import '../../../core/theme/app_appearance.dart';
import '../../../core/theme/app_theme.dart';
import '../../support/trusted_people_screen.dart';
import '../data_portability.dart';
import 'crisis_directory_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onResetOnboarding;
  const SettingsScreen({super.key, required this.onResetOnboarding});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _readingIsPresent(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<WoTScope>()
            ?.notifier
            ?.value ==
        ToleranceState.regulated;
  }

  // ── Data management ─────────────────────────────────────────────────────────

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.clearAllDataTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          context.l10n.clearAllDataBody,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.clearAll,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.allDataCleared),
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await VaultService.instance.wipe();
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
        SnackBar(
          content: Text(context.l10n.checkinAlreadyOpen),
          backgroundColor: Theme.of(context).colorScheme.surface,
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
        title: Text(
          context.l10n.settings,
          style: const TextStyle(
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
            _Section(context.l10n.about),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MONKEYTHRIVE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'v0.1.3',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.builtFromLivedExperience,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.openSourceLine,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const _RowDetail(
                    icon: Icons.code_rounded,
                    text: 'github.com/Is0cre/MonkeyThrive',
                  ),
                  const SizedBox(height: 6),
                  const _RowDetail(
                    icon: Icons.balance_rounded,
                    text: 'GPL-3.0-only',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Appearance ──────────────────────────────────────────────────
            _Section(context.l10n.appearance),
            const _AppearancePanel(),

            const SizedBox(height: 24),

            // ── Safety ──────────────────────────────────────────────────────
            _Section(context.l10n.safety),
            _TileButton(
              icon: Icons.emergency_rounded,
              iconColor: AppColors.danger,
              label: context.l10n.crisisDirectoryLabel,
              subtitle: context.l10n.crisisDirectorySubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CrisisDirectoryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.person_outline,
              iconColor: Theme.of(context).colorScheme.primary,
              label: context.l10n.trustedPerson,
              subtitle: _readingIsPresent(context)
                  ? context.l10n.savedTextOnDevice
                  : context.l10n.availableWhenPresent,
              onTap: () {
                if (!_readingIsPresent(context)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.trustedSavedWhenPresent,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrustedPeopleScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.forum_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              label: context.l10n.showBaseline,
              subtitle: context.l10n.showBaselineSubtitle,
              onTap: () => _showBaselinePromptPreview(context),
            ),

            const SizedBox(height: 24),

            // ── Privacy ─────────────────────────────────────────────────────
            _Section(context.l10n.privacy),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.entriesStay,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.privacyBody,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RowDetail(
                      icon: Icons.storage_rounded,
                      text: context.l10n.journalDeviceOnly),
                  const SizedBox(height: 5),
                  _RowDetail(
                      icon: Icons.storage_rounded,
                      text: context.l10n.hrvDeviceOnly),
                  const SizedBox(height: 5),
                  _RowDetail(
                      icon: Icons.storage_rounded,
                      text: context.l10n.checkinDeviceOnly),
                  const SizedBox(height: 5),
                  _RowDetail(
                      icon: Icons.storage_rounded,
                      text: context.l10n.sessionDeviceOnly),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Disclaimer ───────────────────────────────────────────────────
            _Section(context.l10n.disclaimer),
            _InfoCard(
              child: Text(
                context.l10n.settingsDisclaimer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Your data ────────────────────────────────────────────────────
            _Section(context.l10n.yourData),
            _TileButton(
              icon: Icons.file_download_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              label: context.l10n.export,
              subtitle: context.l10n.exportSubtitle,
              onTap: () => showLocalExportDialog(context),
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.file_upload_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              label: context.l10n.import,
              subtitle: context.l10n.importSubtitle,
              onTap: () => showLocalImportDialog(context),
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.danger,
              label: context.l10n.clearAllData,
              subtitle: context.l10n.clearAllSubtitle,
              onTap: () => _confirmClearData(context),
            ),
            const SizedBox(height: 8),
            _TileButton(
              icon: Icons.refresh_rounded,
              iconColor: AppColors.textMuted,
              label: context.l10n.redoOnboarding,
              subtitle: context.l10n.redoOnboardingSubtitle,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text(context.l10n.redoOnboardingTitle,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    content: Text(
                      context.l10n.redoOnboardingBody,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.cancel,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.l10n.reset,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)),
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
              Text(
                context.l10n.accent,
                style: const TextStyle(
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
              Text(
                context.l10n.contrast,
                style: const TextStyle(
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
      label: switch (accent) {
        AppAccent.teal => context.l10n.accentTeal,
        AppAccent.green => context.l10n.accentGreen,
        AppAccent.blue => context.l10n.accentBlue,
        AppAccent.amber => context.l10n.accentAmber,
      },
      child: GestureDetector(
        onTap: () => AppAppearanceController.instance.setAccent(accent),
        child: AnimatedContainer(
          duration: AppMotion.press,
          curve: AppMotion.arrive,
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
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).scaffoldBackgroundColor,
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
      AppContrast.soft => context.l10n.contrastSoft,
      AppContrast.standard => context.l10n.contrastStandard,
      AppContrast.high => context.l10n.contrastHigh,
    };
    return GestureDetector(
      onTap: () => AppAppearanceController.instance.setContrast(contrast),
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.arrive,
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
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.35)),
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
