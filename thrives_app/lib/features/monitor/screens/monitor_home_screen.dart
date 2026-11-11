import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/hrv_service.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/storage/session_log.dart';
import '../../../core/storage/tier_service.dart';
import '../../../core/theme/app_theme.dart';
import 'hrv_screen.dart';

class MonitorHomeScreen extends StatefulWidget {
  const MonitorHomeScreen({super.key});

  @override
  State<MonitorHomeScreen> createState() => _MonitorHomeScreenState();
}

class _MonitorHomeScreenState extends State<MonitorHomeScreen> {
  List<ToleranceEntry> _toleranceHistory = [];
  List<SessionEntry> _sessionHistory = [];
  HrvReading? _lastHrv;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await SessionLog.getToleranceLog();
    final s = await SessionLog.getSessionLog();
    final hrv = await HrvService.load();
    if (mounted) {
      setState(() {
        _toleranceHistory = t;
        _sessionHistory = s;
        _lastHrv = hrv.isNotEmpty ? hrv.first : null;
        _loading = false;
      });
    }
  }

  Future<void> _openHrv() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HrvScreen()),
    );
    // Reload in case a new reading was saved
    final hrv = await HrvService.load();
    if (mounted) setState(() => _lastHrv = hrv.isNotEmpty ? hrv.first : null);
  }

  Future<void> _checkIn(ToleranceState state) async {
    // Update app-wide WoT state via the scope notifier
    WoTScope.of(context).value = state;
    await PrefsService.saveWotState(state);
    final entry = ToleranceEntry(state: state.name, timestamp: DateTime.now());
    await SessionLog.logTolerance(entry);
    TierService
        .recheck(); // fire-and-forget — WoT check-ins count toward tier unlock
    if (mounted) {
      setState(() {
        _toleranceHistory = [entry, ..._toleranceHistory];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToleranceState?>(
      valueListenable: WoTScope.of(context),
      builder: (context, wot, _) {
        return Scaffold(
          body: SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal))
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Monitor',
                                  style:
                                      Theme.of(context).textTheme.displayLarge),
                              const SizedBox(height: 6),
                              const Text(
                                'Check in with your nervous system.',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // ── HRV card ───────────────────────────────────
                            _HrvCard(
                              last: _lastHrv,
                              onTap: _openHrv,
                            ),
                            const SizedBox(height: 16),

                            // ── Window of tolerance diagram ────────────────
                            _WindowDiagram(current: wot),
                            const SizedBox(height: 24),

                            // ── Check-in buttons ───────────────────────────
                            const _SectionLabel('How are you right now?'),
                            const SizedBox(height: 12),
                            _CheckInRow(
                              current: wot,
                              onSelect: _checkIn,
                            ),

                            // ── Tolerance history ──────────────────────────
                            if (_toleranceHistory.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              const _SectionLabel('Recent check-ins'),
                              const SizedBox(height: 12),
                              for (final entry
                                  in _toleranceHistory.take(10)) ...[
                                _ToleranceTile(entry: entry),
                                const SizedBox(height: 8),
                              ],
                            ],

                            // ── Session history ────────────────────────────
                            if (_sessionHistory.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              const _SectionLabel('Tools used recently'),
                              const SizedBox(height: 12),
                              for (final entry in _sessionHistory.take(15)) ...[
                                _SessionTile(entry: entry),
                                const SizedBox(height: 8),
                              ],
                            ],

                            if (_toleranceHistory.isEmpty &&
                                _sessionHistory.isEmpty) ...[
                              const SizedBox(height: 32),
                              const Center(
                                child: Text(
                                  'No history yet.\nStart using tools and check back here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                      height: 1.6),
                                ),
                              ),
                            ],
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

// ─── HRV card ──────────────────────────────────────────────────────────────────

class _HrvCard extends StatelessWidget {
  final HrvReading? last;
  final VoidCallback onTap;
  const _HrvCard({required this.last, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_border_rounded,
                color: AppColors.teal, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: last == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heart rate variability',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400)),
                        SizedBox(height: 2),
                        Text('Tap to measure via camera',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${last!.hr.round()} bpm  ·  RMSSD ${last!.rmssd.round()} ms',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          last!.rmssdLabel,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Window of tolerance diagram ──────────────────────────────────────────────

class _WindowDiagram extends StatelessWidget {
  final ToleranceState? current;
  const _WindowDiagram({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WINDOW OF TOLERANCE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _Band(
            label: 'Hyperarousal',
            sub: 'Anxiety · Panic · Overwhelm',
            color: const Color(0xFFDA6433),
            isActive: current == ToleranceState.hyperaroused,
          ),
          const SizedBox(height: 4),
          _Band(
            label: 'Window of tolerance',
            sub: 'Regulated · Processing possible',
            color: AppColors.teal,
            isActive: current == ToleranceState.regulated,
          ),
          const SizedBox(height: 4),
          _Band(
            label: 'Hypoarousal',
            sub: 'Numbness · Shutdown · Dissociation',
            color: const Color(0xFF6B7ADA),
            isActive: current == ToleranceState.hypoaroused,
          ),
          if (current == null) ...[
            const SizedBox(height: 12),
            const Text(
              'Check in below to log where you are.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Band extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final bool isActive;

  const _Band({
    required this.label,
    required this.sub,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: isActive ? color : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    )),
                Text(sub,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (isActive) Icon(Icons.arrow_left_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}

// ─── Check-in row ──────────────────────────────────────────────────────────────

class _CheckInRow extends StatelessWidget {
  final ToleranceState? current;
  final ValueChanged<ToleranceState> onSelect;

  const _CheckInRow({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opt in [
          (
            ToleranceState.hyperaroused,
            'Overwhelmed',
            const Color(0xFFDA6433),
            Icons.keyboard_double_arrow_up_rounded
          ),
          (
            ToleranceState.regulated,
            'Present',
            AppColors.teal,
            Icons.check_circle_outline_rounded
          ),
          (
            ToleranceState.hypoaroused,
            'Flat',
            const Color(0xFF6B7ADA),
            Icons.keyboard_double_arrow_down_rounded
          ),
        ]) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: current == opt.$1
                      ? opt.$3.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: current == opt.$1 ? opt.$3 : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(opt.$4,
                        color: current == opt.$1 ? opt.$3 : AppColors.textMuted,
                        size: 22),
                    const SizedBox(height: 4),
                    Text(
                      opt.$2,
                      style: TextStyle(
                        color: current == opt.$1
                            ? opt.$3
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: current == opt.$1
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (opt.$1 != ToleranceState.hypoaroused) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

// ─── History tiles ─────────────────────────────────────────────────────────────

class _ToleranceTile extends StatelessWidget {
  final ToleranceEntry entry;
  const _ToleranceTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    // Normalise legacy short keys ('hyper', 'hypo') and current enum names
    final (label, color) = switch (entry.state) {
      'hyperaroused' || 'hyper' => ('Overwhelmed', const Color(0xFFDA6433)),
      'hypoaroused' || 'hypo' => ('Flat', const Color(0xFF6B7ADA)),
      _ => ('Present', AppColors.teal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            _formatTime(entry.timestamp),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionEntry entry;
  const _SessionTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.tool,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
                Text(entry.category,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(entry.durationSeconds),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                _formatTime(entry.timestamp),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}';
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  return '${seconds ~/ 60}m ${seconds % 60}s';
}
