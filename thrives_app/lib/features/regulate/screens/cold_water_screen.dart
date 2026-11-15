import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';
import '../../../l10n/l10n.dart';

class ColdWaterScreen extends StatefulWidget {
  const ColdWaterScreen({super.key});

  @override
  State<ColdWaterScreen> createState() => _ColdWaterScreenState();
}

class _ColdWaterScreenState extends State<ColdWaterScreen>
    with SessionTracking {
  static const int _timerDuration = 30;
  int _secondsLeft = _timerDuration;
  bool _running = false;
  bool _done = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    beginTracking('Cold Water', 'Regulate');
    setState(() {
      _running = true;
      _done = false;
      _secondsLeft = _timerDuration;
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
      _secondsLeft = _timerDuration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coldWaterTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),

            // Explanation card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 10),
                      Text(
                        l10n.coldHow,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.coldBody,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            _InstructionRow(
              icon: Icons.face_rounded,
              text: l10n.coldFace,
            ),
            const SizedBox(height: 12),
            _InstructionRow(
              icon: Icons.back_hand_rounded,
              text: l10n.coldWrists,
            ),
            const SizedBox(height: 12),
            _InstructionRow(
              icon: Icons.airline_seat_recline_extra_rounded,
              text: l10n.coldNeck,
            ),

            const SizedBox(height: 32),

            // Timer display
            if (_running || _done) ...[
              AnimatedSwitcher(
                duration: AppMotion.settle,
                switchInCurve: AppMotion.arrive,
                switchOutCurve: AppMotion.depart,
                child: _done
                    ? Column(
                        key: const ValueKey('done'),
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 52),
                          const SizedBox(height: 12),
                          Text(
                            l10n.good,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.alreadyResponding,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 24),
                          const FeelingBetterPrompt(),
                        ],
                      )
                    : Column(
                        key: const ValueKey('timer'),
                        children: [
                          Text(
                            '$_secondsLeft',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                          Text(
                            l10n.seconds,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _done ? _reset : (_running ? null : _start),
                style: FilledButton.styleFrom(
                  backgroundColor: _done
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: _done
                      ? AppColors.textPrimary
                      : Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _done
                      ? l10n.againLabel
                      : (_running ? l10n.running : l10n.start30),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
