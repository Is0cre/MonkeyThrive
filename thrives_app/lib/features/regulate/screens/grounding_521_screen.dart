import 'package:flutter/material.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';
import '../../../l10n/l10n.dart';

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

List<_GroundingStep> _groundingSteps(AppLocalizations l10n) => [
      _GroundingStep(
        count: 5,
        sense: l10n.senseSee,
        instruction: l10n.groundSee,
        icon: Icons.visibility_rounded,
      ),
      _GroundingStep(
        count: 4,
        sense: l10n.senseHear,
        instruction: l10n.groundHear,
        icon: Icons.hearing_rounded,
      ),
      _GroundingStep(
        count: 3,
        sense: l10n.senseTouch,
        instruction: l10n.groundTouch,
        icon: Icons.touch_app_rounded,
      ),
      _GroundingStep(
        count: 2,
        sense: l10n.senseSmell,
        instruction: l10n.groundSmell,
        icon: Icons.spa_rounded,
      ),
      _GroundingStep(
        count: 1,
        sense: l10n.senseTaste,
        instruction: l10n.groundTaste,
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
      final count = _groundingSteps(context.l10n).length;
      setState(() {
        if (_stepIndex < count - 1) {
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
    final l10n = context.l10n;
    final steps = _groundingSteps(l10n);
    final step = _finished ? null : steps[_stepIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groundingTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Step progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
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
                    if (i < steps.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _finished
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        children: [
                          _buildFinished(context),
                          const SizedBox(height: 28),
                          const FeelingBetterPrompt(),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        child: _buildStep(context, step!),
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
                          foregroundColor: const Color(0xFF1A140C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(l10n.finish,
                            style: const TextStyle(
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
                                _stepIndex == steps.length - 1
                                    ? l10n.complete
                                    : l10n.next,
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
          context.l10n.groundCount(step.count, step.sense.toLowerCase()),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: AppColors.amber, size: 64),
        const SizedBox(height: 24),
        Text(context.l10n.youAreHereSentence,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          context.l10n.groundBroughtBack,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
