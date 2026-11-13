import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';

class _VagalTool {
  final String title;
  final String why;
  final String instructions;
  final IconData icon;
  final int? timerSeconds;

  const _VagalTool({
    required this.title,
    required this.why,
    required this.instructions,
    required this.icon,
    this.timerSeconds,
  });
}

const _tools = [
  _VagalTool(
    title: 'Humming',
    why: 'Humming creates vibrations that directly stimulate the vagus nerve '
        'through the larynx. Even 2 minutes can measurably shift your state.',
    instructions: 'Find a comfortable note and hum steadily. '
        'Feel the vibration in your chest and throat. '
        'Let the exhale extend naturally as you hum.',
    icon: Icons.music_note_rounded,
  ),
  _VagalTool(
    title: 'Gargling',
    why: 'Gargling activates muscles at the back of the throat that are '
        'connected to the vagus nerve. 30 seconds is enough to notice a shift.',
    instructions: 'Take a mouthful of water and gargle vigorously '
        'for as long as comfortable. Repeat 2-3 times.',
    icon: Icons.water_drop_rounded,
    timerSeconds: 30,
  ),
  _VagalTool(
    title: 'Extended Exhale',
    why: 'The exhale activates the parasympathetic nervous system. '
        'Making your exhale twice as long as your inhale slows the heart rate '
        'and signals safety to your body.',
    instructions: 'Breathe in for 4 counts. Breathe out slowly for 8 counts. '
        'There is no hold — just a long, steady out-breath. '
        'Repeat as many times as you need.',
    icon: Icons.air_rounded,
  ),
  _VagalTool(
    title: 'Diving Reflex',
    why: 'Submerging your face in cold water (or splashing it) triggers the '
        'mammalian diving reflex — your heart rate slows within seconds. '
        'It is one of the fastest calming signals your body responds to.',
    instructions: 'Fill a bowl or sink with cold water. '
        'Hold your breath and submerge your face for 15-30 seconds, '
        'or splash cold water repeatedly over your face and forehead.',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vagal Nerve Activation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: _activeToolIndex != null
            ? _VagalToolDetail(
                tool: _tools[_activeToolIndex!],
                onBack: () => setState(() => _activeToolIndex = null),
              )
            : _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'The vagus nerve is your body\'s main pathway to calm. '
            'These techniques activate it directly.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        for (int i = 0; i < _tools.length; i++) ...[
          _VagalCard(
            tool: _tools[i],
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
    const color = Color(0xFF8B6FD4);
    return Material(
      color: AppColors.surface,
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
                          ? '${tool.timerSeconds}s timer'
                          : 'Breathing guide',
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
      beginTracking('Vagal — ${widget.tool.title}', 'Regulate');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    beginTracking('Vagal — ${widget.tool.title}', 'Regulate');
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
    const color = Color(0xFF8B6FD4);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
          GestureDetector(
            onTap: () {
              _reset();
              widget.onBack();
            },
            child: const Row(
              children: [
                Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary, size: 18),
                SizedBox(width: 6),
                Text('Back',
                    style: TextStyle(
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WHY THIS WORKS',
                  style: TextStyle(
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
                    ? const Icon(Icons.check_circle_outline_rounded,
                        color: color, size: 52)
                    : Text(
                        '$_secondsLeft',
                        style: const TextStyle(
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
                  backgroundColor: _done ? AppColors.surfaceVariant : color,
                  foregroundColor:
                      _done ? AppColors.textPrimary : AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _done
                      ? 'Again'
                      : (_running
                          ? 'Running…'
                          : 'Start ${widget.tool.timerSeconds}s timer'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
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
                  side: const BorderSide(color: AppColors.amber),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_done ? 'Back' : 'Done'),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
    );
  }
}
