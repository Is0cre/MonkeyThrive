import 'package:flutter/material.dart';
import '../../../core/storage/session_log.dart';
import '../../../core/theme/app_theme.dart';

class ReflectHomeScreen extends StatefulWidget {
  const ReflectHomeScreen({super.key});

  @override
  State<ReflectHomeScreen> createState() => _ReflectHomeScreenState();
}

class _ReflectHomeScreenState extends State<ReflectHomeScreen> {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
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
                    Text('Reflect',
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 6),
                    const Text(
                      'a record of what you\'ve explored.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            if (!hasData)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'Nothing here yet.\n\nUse a few tools and come back.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                      const _Label('time with each area'),
                      const SizedBox(height: 12),
                      _CategoryBars(totals: categoryTotals),
                      const SizedBox(height: 32),
                    ],

                    // ── Tool usage ─────────────────────────────────────────
                    if (toolStats.isNotEmpty) ...[
                      const _Label('what you\'ve reached for'),
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

  Color _colorFor(String? state) {
    switch (state) {
      case 'hyperaroused':
      case 'hyper':
        return const Color(0xFFDA6433);
      case 'regulated':
        return AppColors.teal;
      case 'hypoaroused':
      case 'hypo':
        return const Color(0xFF6B7ADA);
      default:
        return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Days ordered oldest → newest (left → right, top → bottom)
    final days = stateMap.keys.toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR STATES — PAST 35 DAYS',
            style: TextStyle(
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
                    ? _ToleranceStateX.displayFor(state)
                    : 'no check-in',
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _colorFor(state),
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
                ('overwhelmed', const Color(0xFFDA6433)),
                ('present', AppColors.teal),
                ('flat', const Color(0xFF6B7ADA)),
                ('no data', AppColors.surfaceVariant),
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

  static const _colors = {
    'Regulate': AppColors.teal,
    'Process': Color(0xFF4A9EDA),
    'Attune': Color(0xFF7B68EE),
    'General': AppColors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final maxSeconds =
        totals.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    if (maxSeconds == 0) return const SizedBox.shrink();

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final color = _colors[e.key] ?? AppColors.textMuted;
        final fraction = e.value / maxSeconds;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  e.key,
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
                        color: AppColors.surfaceVariant,
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
                  _fmtDuration(e.value),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                Text(
                  '${e.value.count}×',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  _fmtDuration(e.value.totalSeconds),
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

String _fmtDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m < 60) return s > 0 ? '${m}m ${s}s' : '${m}m';
  final h = m ~/ 60;
  final rm = m % 60;
  return rm > 0 ? '${h}h ${rm}m' : '${h}h';
}

// Normalise legacy + current state name strings to display labels
class _ToleranceStateX {
  static String displayFor(String state) {
    switch (state) {
      case 'hyperaroused':
      case 'hyper':
        return 'overwhelmed';
      case 'hypoaroused':
      case 'hypo':
        return 'flat or numb';
      default:
        return 'present';
    }
  }
}
