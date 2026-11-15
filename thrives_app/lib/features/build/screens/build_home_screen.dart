import 'package:flutter/material.dart';
import 'package:monkeythrive/l10n/l10n.dart';
import '../../../core/storage/journal_service.dart';
import '../../../core/storage/vault_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../reflect/screens/vault_lock_screen.dart';
import 'journal_entry_screen.dart';

class BuildHomeScreen extends StatefulWidget {
  const BuildHomeScreen({super.key});

  @override
  State<BuildHomeScreen> createState() => _BuildHomeScreenState();
}

class _BuildHomeScreenState extends State<BuildHomeScreen> {
  List<JournalEntry> _entries = [];
  bool _loading = true;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    VaultService.instance.addListener(_onVault);
    _load();
  }

  @override
  void dispose() {
    VaultService.instance.removeListener(_onVault);
    super.dispose();
  }

  void _onVault() {
    if (!mounted) return;
    final vault = VaultService.instance;
    if (vault.isProtected && !vault.isUnlocked) {
      setState(() {
        _entries = [];
        _locked = true;
        _loading = false;
      });
      return;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await JournalService.load();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _locked = false;
        _loading = false;
      });
    } on VaultLockedException {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _locked = true;
        _loading = false;
      });
    }
  }

  Future<void> _unlock() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const VaultLockScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _newEntry() async {
    final vault = VaultService.instance;
    await vault.ensureLoaded();
    if (!mounted) return;
    if (vault.isProtected && !vault.isUnlocked) {
      await _unlock();
      return;
    }
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
        title: Text(context.l10n.deleteEntryTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: Text(
          context.l10n.cannotBeUndone,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete,
                style: const TextStyle(color: AppColors.danger)),
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
              onPressed: _locked ? _unlock : _newEntry,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              tooltip:
                  _locked ? context.l10n.vaultUnlock : context.l10n.newEntry,
              child: Icon(
                _locked ? Icons.lock_outline_rounded : Icons.edit_rounded,
                size: 22,
              ),
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
                    Text(context.l10n.navBuild,
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.buildSubtitle,
                      style: const TextStyle(
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
            else if (_locked)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.vaultJournalLocked,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _unlock,
                          child: Text(context.l10n.vaultUnlock),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      context.l10n.nothingWritten,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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

    final l10n = context.l10n;
    final String label;
    if (diff == 0) {
      label = l10n.today;
    } else if (diff == 1) {
      label = l10n.yesterday;
    } else if (diff < 7) {
      label = l10n.daysAgoLong(diff);
    } else {
      label = l10n.dayMonthYear(dt.day, monthShort(l10n, dt.month), dt.year);
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
                      Text(
                        context.l10n.emptyEntry,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (entry.wordCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.wordsCount(entry.wordCount),
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
