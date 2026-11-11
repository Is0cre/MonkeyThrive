import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold Water'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: const EmergencyButton(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Explanation card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop_rounded,
                            color: AppColors.teal, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'How this works',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cold water activates the diving reflex — your body\'s '
                      'built-in emergency brake. It slows your heart rate and '
                      'activates the vagus nerve within seconds.\n\n'
                      'Apply cold water to your face, wrists, or the back of your neck.',
                      style: TextStyle(
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
              const _InstructionRow(
                icon: Icons.face_rounded,
                text: 'Splash cold water on your face',
              ),
              const SizedBox(height: 12),
              const _InstructionRow(
                icon: Icons.back_hand_rounded,
                text: 'Hold cold water on your wrists',
              ),
              const SizedBox(height: 12),
              const _InstructionRow(
                icon: Icons.airline_seat_recline_extra_rounded,
                text: 'Cold cloth on the back of your neck',
              ),

              const Spacer(),

              // Timer display
              if (_running || _done) ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _done
                      ? Column(
                          key: const ValueKey('done'),
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: AppColors.teal, size: 52),
                            const SizedBox(height: 12),
                            Text(
                              'Good.',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your nervous system is already responding.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('timer'),
                          children: [
                            Text(
                              '$_secondsLeft',
                              style: const TextStyle(
                                color: AppColors.teal,
                                fontSize: 72,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                            const Text(
                              'seconds',
                              style: TextStyle(
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
                    backgroundColor:
                        _done ? AppColors.surfaceVariant : AppColors.teal,
                    foregroundColor:
                        _done ? AppColors.textPrimary : AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _done
                        ? 'Again'
                        : (_running ? 'Running…' : 'Start 30s timer'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.teal, size: 20),
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
