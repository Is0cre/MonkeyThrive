import 'package:flutter/material.dart';
import 'package:monkeythrive/l10n/l10n.dart';
import '../../../core/storage/session_log.dart';
import '../../../core/storage/vault_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/data_portability.dart';
import 'vault_lock_screen.dart';

/// Reflect stays behind the vault. Session logs are not read until the
/// key is open, because the shell builds this tab immediately.
class ReflectHomeScreen extends StatefulWidget {
  const ReflectHomeScreen({super.key});

  @override
  State<ReflectHomeScreen> createState() => _ReflectGateState();
}

class _ReflectGateState extends State<ReflectHomeScreen> {
  @override
  void initState() {
    super.initState();
    VaultService.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VaultService.instance,
      builder: (context, _) {
        final vault = VaultService.instance;
        if (!vault.isReady) {
          return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
        }
        if (!vault.isUnlocked || vault.storageBroken) {
          return const VaultLockScreen();
        }
        return const _ReflectRecord();
      },
    );
  }
}

class _ReflectRecord extends StatefulWidget {
  const _ReflectRecord();

  @override
  State<_ReflectRecord> createState() => _ReflectHomeScreenState();
}

class _ReflectHomeScreenState extends State<_ReflectRecord> {
  List<ToleranceEntry> _toleranceLog = [];
  List<SessionEntry> _sessionLog = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await SessionLog.getToleranceLog();
    final s = await SessionLog.getSessionLog();
    if (mounted) {
      setState(() {
        _toleranceLog = t;
        _sessionLog = s;
        _loading = false;
      });
    }
  }

  // ── Data helpers ────────────────────────────────────────────────────────────

  /// Returns the last checked-in state for each of the past [days] days.
  /// Key = date (yyyy-MM-dd), Value = state name or null.
  Map<String, String?> _statesByDay(int days) {
    final result = <String, String?>{};
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      result[_dateKey(day)] = null;
    }
    // Fill from log — later entries overwrite earlier ones for same day
    for (final entry in _toleranceLog.reversed) {
      final key = _dateKey(entry.timestamp);
      if (result.containsKey(key)) {
        result[key] = entry.state;
      }
    }
    return result;
  }

  /// tool name → {count, totalSeconds}
  Map<String, ({int count, int totalSeconds})> _toolStats() {
    final stats = <String, ({int count, int totalSeconds})>{};
    for (final entry in _sessionLog) {
      final existing = stats[entry.tool];
      stats[entry.tool] = (
        count: (existing?.count ?? 0) + 1,
        totalSeconds: (existing?.totalSeconds ?? 0) + entry.durationSeconds,
      );
    }
    return stats;
  }

  /// category → total seconds
  Map<String, int> _categoryTotals() {
    final totals = <String, int>{};
    for (final entry in _sessionLog) {
      totals[entry.category] =
          (totals[entry.category] ?? 0) + entry.durationSeconds;
    }
    return totals;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary)),
      );
    }

    final stateMap = _statesByDay(35);
    final toolStats = _toolStats();
    final categoryTotals = _categoryTotals();
    final hasData = _sessionLog.isNotEmpty || _toleranceLog.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.navReflect,
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.reflectSubtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => showLocalExportDialog(context),
                          child: Text(context.l10n.export),
                        ),
                        TextButton(
                          onPressed: () async {
                            await showLocalImportDialog(context);
                            if (mounted) await _load();
                          },
                          child: Text(context.l10n.import),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (!hasData)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      context.l10n.reflectEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          height: 1.7),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── 35-day state map ───────────────────────────────────
                    _StateMap(stateMap: stateMap),
                    const SizedBox(height: 32),

                    // ── Category time ──────────────────────────────────────
                    if (categoryTotals.isNotEmpty) ...[
                      _Label(context.l10n.timeWithEachArea),
                      const SizedBox(height: 12),
                      _CategoryBars(totals: categoryTotals),
                      const SizedBox(height: 32),
                    ],

                    // ── Tool usage ─────────────────────────────────────────
                    if (toolStats.isNotEmpty) ...[
                      _Label(context.l10n.whatYouReachedFor),
                      const SizedBox(height: 12),
                      _ToolList(stats: toolStats),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 35-day state map ──────────────────────────────────────────────────────────

class _StateMap extends StatelessWidget {
  final Map<String, String?> stateMap;
  const _StateMap({required this.stateMap});

  Color _colorFor(BuildContext context, String? state) {
    switch (state) {
      case 'hyperaroused':
      case 'hyper':
        return const Color(0xFFDA6433);
      case 'regulated':
        return Theme.of(context).colorScheme.primary;
      case 'hypoaroused':
      case 'hypo':
        return const Color(0xFF6B7ADA);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Days ordered oldest → newest (left → right, top → bottom)
    final days = stateMap.keys.toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.statesPast35,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: days.map((key) {
              final state = stateMap[key];
              return Tooltip(
                message: state != null
                    ? _ToleranceStateX.displayFor(context.l10n, state)
                    : context.l10n.noCheckIn,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _colorFor(context, state),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final item in [
                (context.l10n.stateOverwhelmed, const Color(0xFFDA6433)),
                (
                  context.l10n.statePresent,
                  Theme.of(context).colorScheme.primary
                ),
                (context.l10n.flatShort, const Color(0xFF6B7ADA)),
                (
                  context.l10n.noData,
                  Theme.of(context).colorScheme.surfaceContainerHighest
                ),
              ]) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.$2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category time bars ────────────────────────────────────────────────────────

class _CategoryBars extends StatelessWidget {
  final Map<String, int> totals;
  const _CategoryBars({required this.totals});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final colors = {
      'Regulate': accent,
      'Process': context.schemeShift(32),
      'Attune': context.schemeShift(64),
      'General': context.schemeShift(96),
    };
    final maxSeconds =
        totals.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    if (maxSeconds == 0) return const SizedBox.shrink();

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final color = colors[e.key] ?? AppColors.textMuted;
        final fraction = e.value / maxSeconds;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  categoryLabel(context.l10n, e.key),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fraction.clamp(0.02, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(
                  _fmtDuration(context.l10n, e.value),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Tool usage list ────────────────────────────────────────────────────────────

class _ToolList extends StatelessWidget {
  final Map<String, ({int count, int totalSeconds})> stats;
  const _ToolList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return Column(
      children: sorted.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    toolTitle(context.l10n, e.key),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                Text(
                  context.l10n.countTimes(e.value.count),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  _fmtDuration(context.l10n, e.value.totalSeconds),
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

String _fmtDuration(AppLocalizations l10n, int seconds) {
  if (seconds < 60) return l10n.durationSeconds(seconds);
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m < 60) {
    return s > 0 ? l10n.durationMinutesSeconds(m, s) : l10n.minutesShort(m);
  }
  final h = m ~/ 60;
  final rm = m % 60;
  return rm > 0 ? l10n.durationHoursMinutes(h, rm) : l10n.hoursShort(h);
}

// Normalise legacy + current state name strings to display labels
class _ToleranceStateX {
  static String displayFor(AppLocalizations l10n, String state) {
    switch (state) {
      case 'hyperaroused':
      case 'hyper':
        return l10n.stateOverwhelmed;
      case 'hypoaroused':
      case 'hypo':
        return l10n.stateFlat;
      default:
        return l10n.statePresent;
    }
  }
}
