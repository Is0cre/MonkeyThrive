import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';
import '../../../l10n/l10n.dart';

class _VagalTool {
  /// English session id. Tracking stays `Vagal — $id`.
  final String id;
  final String title;
  final String why;
  final String instructions;
  final IconData icon;
  final int? timerSeconds;

  const _VagalTool({
    required this.id,
    required this.title,
    required this.why,
    required this.instructions,
    required this.icon,
    this.timerSeconds,
  });
}

List<_VagalTool> _vagalTools(AppLocalizations l10n) => [
      _VagalTool(
        id: 'Humming',
        title: l10n.humming,
        why: l10n.hummingWhy,
        instructions: l10n.hummingHow,
        icon: Icons.music_note_rounded,
      ),
      _VagalTool(
        id: 'Gargling',
        title: l10n.gargling,
        why: l10n.garglingWhy,
        instructions: l10n.garglingHow,
        icon: Icons.water_drop_rounded,
        timerSeconds: 30,
      ),
      _VagalTool(
        id: 'Extended Exhale',
        title: l10n.extendedExhale,
        why: l10n.extendedWhy,
        instructions: l10n.extendedHow,
        icon: Icons.air_rounded,
      ),
      _VagalTool(
        id: 'Diving Reflex',
        title: l10n.divingReflex,
        why: l10n.divingWhy,
        instructions: l10n.divingHow,
        icon: Icons.face_rounded,
        timerSeconds: 30,
      ),
    ];

class VagalScreen extends StatefulWidget {
  const VagalScreen({super.key});

  @override
  State<VagalScreen> createState() => _VagalScreenState();
}

class _VagalScreenState extends State<VagalScreen> {
  int? _activeToolIndex;

  @override
  Widget build(BuildContext context) {
    final tools = _vagalTools(context.l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.vagalScreenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: _activeToolIndex != null
            ? _VagalToolDetail(
                tool: tools[_activeToolIndex!],
                onBack: () => setState(() => _activeToolIndex = null),
              )
            : _buildList(context, tools),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<_VagalTool> tools) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            context.l10n.vagalIntro,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        for (int i = 0; i < tools.length; i++) ...[
          _VagalCard(
            tool: tools[i],
            onTap: () => setState(() => _activeToolIndex = i),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _VagalCard extends StatelessWidget {
  final _VagalTool tool;
  final VoidCallback onTap;

  const _VagalCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      tool.timerSeconds != null
                          ? context.l10n.secondsTimer(tool.timerSeconds!)
                          : context.l10n.breathingGuide,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _VagalToolDetail extends StatefulWidget {
  final _VagalTool tool;
  final VoidCallback onBack;

  const _VagalToolDetail({required this.tool, required this.onBack});

  @override
  State<_VagalToolDetail> createState() => _VagalToolDetailState();
}

class _VagalToolDetailState extends State<_VagalToolDetail>
    with SessionTracking {
  int _secondsLeft = 0;
  bool _running = false;
  bool _done = false;
  Timer? _timer;

  bool get _hasTimer => widget.tool.timerSeconds != null;

  @override
  void initState() {
    super.initState();
    // Tools without a timer begin immediately when opened
    if (!_hasTimer) {
      beginTracking('Vagal — ${widget.tool.id}', 'Regulate');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    beginTracking('Vagal — ${widget.tool.id}', 'Regulate');
    setState(() {
      _running = true;
      _done = false;
      _secondsLeft = widget.tool.timerSeconds!;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          _running = false;
          _done = true;
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _done = false;
      _secondsLeft = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GestureDetector(
          onTap: () {
            _reset();
            widget.onBack();
          },
          child: Row(
            children: [
              const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(context.l10n.back,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.tool.icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Text(
              widget.tool.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Why it works
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.whyThisWorks,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tool.why,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          widget.tool.instructions,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 28),

        if (_hasTimer) ...[
          if (_running || _done) ...[
            Center(
              child: _done
                  ? Icon(Icons.check_circle_outline_rounded,
                      color: color, size: 52)
                  : Text(
                      '$_secondsLeft',
                      style: TextStyle(
                        color: color,
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
          if (_done) ...[
            const FeelingBetterPrompt(),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _done ? _reset : (_running ? null : _startTimer),
              style: FilledButton.styleFrom(
                backgroundColor: _done
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : color,
                foregroundColor: _done
                    ? AppColors.textPrimary
                    : Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _done
                    ? context.l10n.againLabel
                    : (_running
                        ? context.l10n.running
                        : context.l10n
                            .startSecondsTimer(widget.tool.timerSeconds!)),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ] else ...[
          if (_done) ...[
            const FeelingBetterPrompt(),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                if (!_done) {
                  setState(() => _done = true);
                  return;
                }
                _reset();
                widget.onBack();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_done ? context.l10n.back : context.l10n.done),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
