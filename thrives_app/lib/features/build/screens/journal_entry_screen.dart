import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monkeythrive/l10n/l10n.dart';
import '../../../core/storage/journal_service.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

// Gentle, open-ended prompts — trauma-informed, body-based, no leading questions.
// Not shown unless the user asks. Never prescriptive.
List<String> _promptsFor(AppLocalizations l10n) => [
      l10n.prompt1,
      l10n.prompt2,
      l10n.prompt3,
      l10n.prompt4,
      l10n.prompt5,
      l10n.prompt6,
      l10n.prompt7,
      l10n.prompt8,
    ];

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry entry;
  final bool isNew;

  const JournalEntryScreen({
    super.key,
    required this.entry,
    this.isNew = false,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen>
    with SessionTracking {
  late TextEditingController _controller;
  late JournalEntry _entry;
  Timer? _saveTimer;
  bool _saved = true;
  bool _showPrompt = false;
  int _promptIndex = 0;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _controller = TextEditingController(text: _entry.body);
    _controller.addListener(_onChanged);
    beginTracking('Journaling', 'Build');
    if (widget.isNew) {
      // Autofocus on new entries
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _saved = false);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _flush);
  }

  Future<void> _flush() async {
    final updated = _entry.copyWith(body: _controller.text);
    _entry = updated;
    await JournalService.save(updated);
    if (mounted) setState(() => _saved = true);
  }

  void _nextPrompt() {
    final prompts = _promptsFor(context.l10n);
    setState(() {
      _promptIndex = (_promptIndex + 1) % prompts.length;
      _showPrompt = true;
    });
  }

  void _dismissPrompt() => setState(() => _showPrompt = false);

  String _wordCountLabel(AppLocalizations l10n) {
    final n = _entry.copyWith(body: _controller.text).wordCount;
    if (n == 0) return '';
    return l10n.wordCount(n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            await _flush();
            if (context.mounted) Navigator.pop(context, _entry);
          },
        ),
        title: Text(
          _formatDate(context.l10n, _entry.timestamp),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          // Saved indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: AnimatedOpacity(
                opacity: _saved ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  context.l10n.saved,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const EmergencyButton(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Prompt chip ─────────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _showPrompt
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _promptsFor(context.l10n)[_promptIndex],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 18),
                            onPressed: _dismissPrompt,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Editor ──────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: TextField(
                  controller: _controller,
                  autofocus: widget.isNew,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.7,
                    fontWeight: FontWeight.w300,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: context.l10n.journalHint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom bar ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  // Prompt button
                  GestureDetector(
                    onTap: _nextPrompt,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.prompt,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Word count
                  Text(
                    _wordCountLabel(context.l10n),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(AppLocalizations l10n, DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return l10n.journalStamp(dt.day, monthShort(l10n, dt.month), dt.year, h, m);
}
