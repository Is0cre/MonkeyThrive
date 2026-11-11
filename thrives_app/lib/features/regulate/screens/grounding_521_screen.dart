import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

class _GroundingStep {
  final int count;
  final String sense;
  final String instruction;
  final IconData icon;

  const _GroundingStep({
    required this.count,
    required this.sense,
    required this.instruction,
    required this.icon,
  });
}

const _steps = [
  _GroundingStep(
    count: 5,
    sense: 'See',
    instruction: 'Look around you. Find 5 things you can see right now.\n\n'
        'Take your time. Notice each one clearly — colour, shape, texture.',
    icon: Icons.visibility_rounded,
  ),
  _GroundingStep(
    count: 4,
    sense: 'Hear',
    instruction:
        'Close your eyes if that feels safe. Find 4 things you can hear.\n\n'
        'Near and far. Notice the sounds without judgement.',
    icon: Icons.hearing_rounded,
  ),
  _GroundingStep(
    count: 3,
    sense: 'Touch',
    instruction:
        'Find 3 things you can feel right now — the chair beneath you, '
        'the fabric on your skin, the air temperature.\n\n'
        'Press your feet into the floor if that helps.',
    icon: Icons.touch_app_rounded,
  ),
  _GroundingStep(
    count: 2,
    sense: 'Smell',
    instruction:
        'Find 2 things you can smell, or remember scents that feel safe and '
        'familiar to you.\n\n'
        'Take a slow breath in through your nose.',
    icon: Icons.spa_rounded,
  ),
  _GroundingStep(
    count: 1,
    sense: 'Taste',
    instruction:
        'Notice 1 thing you can taste, or take a sip of water if you have some.\n\n'
        'You are here. You are safe.',
    icon: Icons.water_drop_outlined,
  ),
];

class Grounding521Screen extends StatefulWidget {
  const Grounding521Screen({super.key});

  @override
  State<Grounding521Screen> createState() => _Grounding521ScreenState();
}

class _Grounding521ScreenState extends State<Grounding521Screen>
    with SingleTickerProviderStateMixin, SessionTracking {
  int _stepIndex = 0;
  bool _finished = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    beginTracking('5-4-3-2-1 Grounding', 'Regulate');
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _next() {
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        if (_stepIndex < _steps.length - 1) {
          _stepIndex++;
        } else {
          _finished = true;
        }
      });
      _fadeController.forward();
    });
  }

  void _prev() {
    if (_stepIndex == 0) return;
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _finished = false;
        _stepIndex--;
      });
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _finished ? null : _steps[_stepIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('5-4-3-2-1 Grounding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: const EmergencyButton(),
      body: SafeArea(
        child: Column(
          children: [
            // Step progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _steps.length; i++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _stepIndex && !_finished ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= _stepIndex || _finished
                            ? AppColors.amber
                            : AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (i < _steps.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                  child: _finished
                      ? _buildFinished(context)
                      : _buildStep(context, step!),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: _finished
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Finish',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    )
                  : Row(
                      children: [
                        if (_stepIndex > 0)
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _prev,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                      color: AppColors.surfaceVariant),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                          ),
                        if (_stepIndex > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.amber,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                _stepIndex == _steps.length - 1
                                    ? 'Complete'
                                    : 'Next',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, _GroundingStep step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(step.icon, color: AppColors.amber, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          '${step.count} things you can ${step.sense.toLowerCase()}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          step.instruction,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFinished(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: AppColors.amber, size: 64),
        const SizedBox(height: 24),
        Text('You are here.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          'You just brought yourself back with your own senses. '
          'That is the skill — and you have it.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
