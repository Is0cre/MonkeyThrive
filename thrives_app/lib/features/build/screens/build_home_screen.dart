import 'package:flutter/material.dart';
import '../../../core/storage/journal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import 'journal_entry_screen.dart';

class BuildHomeScreen extends StatefulWidget {
  const BuildHomeScreen({super.key});

  @override
  State<BuildHomeScreen> createState() => _BuildHomeScreenState();
}

class _BuildHomeScreenState extends State<BuildHomeScreen> {
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.load();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _newEntry() async {
    final entry = JournalEntry(
      id: JournalService.newId(),
      timestamp: DateTime.now(),
      body: '',
    );
    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(entry: entry, isNew: true),
      ),
    );
    if (result != null && result.body.trim().isNotEmpty) {
      await _load();
    }
  }

  Future<void> _openEntry(JournalEntry entry) async {
    await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(entry: entry),
      ),
    );
    await _load();
  }

  Future<void> _confirmDelete(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this entry?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: const Text(
          'This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await JournalService.delete(entry.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // New entry button — positioned above emergency FAB
          Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: FloatingActionButton(
              heroTag: 'new_journal_entry',
              onPressed: _newEntry,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              tooltip: 'New entry',
              child: const Icon(Icons.edit_rounded, size: 22),
            ),
          ),
          const EmergencyButton(),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Build',
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 6),
                    const Text(
                      'A private space to write. Nothing leaves this device.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                ),
              )
            else if (_entries.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Nothing written yet.\n\nTap the pencil when you\'re ready.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      // Group by date
                      final entry = _entries[i];
                      final showHeader = i == 0 ||
                          !_sameDay(_entries[i - 1].timestamp, entry.timestamp);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) ...[
                            if (i > 0) const SizedBox(height: 24),
                            _DateHeader(entry.timestamp),
                            const SizedBox(height: 10),
                          ],
                          _EntryCard(
                            entry: entry,
                            onTap: () => _openEntry(entry),
                            onLongPress: () => _confirmDelete(entry),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                    childCount: _entries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DateHeader extends StatelessWidget {
  final DateTime dt;
  const _DateHeader(this.dt);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;

    final String label;
    if (diff == 0) {
      label = 'today';
    } else if (diff == 1) {
      label = 'yesterday';
    } else if (diff < 7) {
      label = '$diff days ago';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      label = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final h = entry.timestamp.hour.toString().padLeft(2, '0');
    final m = entry.timestamp.minute.toString().padLeft(2, '0');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.preview.isNotEmpty)
                      Text(
                        entry.preview,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w300,
                        ),
                      )
                    else
                      const Text(
                        'empty entry',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (entry.wordCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${entry.wordCount} words',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$h:$m',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
