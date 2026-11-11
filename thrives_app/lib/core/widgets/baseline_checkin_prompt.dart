import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/regulate/screens/breathing_screen.dart';
import '../../features/regulate/screens/grounding_521_screen.dart';
import '../../features/regulate/screens/physiological_sigh_screen.dart';
import '../../features/regulate/screens/vagal_screen.dart';
import '../baseline/baseline_feedback_store.dart';
import '../baseline/baseline_models.dart';
import '../baseline/baseline_monitor.dart';
import '../theme/app_theme.dart';

class BaselineCheckInHost extends StatefulWidget {
  final Widget child;

  const BaselineCheckInHost({
    super.key,
    required this.child,
  });

  @override
  State<BaselineCheckInHost> createState() => _BaselineCheckInHostState();
}

class _BaselineCheckInHostState extends State<BaselineCheckInHost> {
  NotificationDecision? _decision;
  UserFeedback? _lastFeedback;
  bool _showTools = false;
  late final StreamSubscription<NotificationDecision> _sub;

  @override
  void initState() {
    super.initState();
    _sub = BaselineMonitor.instance.prompts.listen((decision) {
      if (mounted) {
        setState(() {
          _decision = decision;
          _lastFeedback = null;
          _showTools = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _respond(BaselineUserResponse response) async {
    final decision = _decision;
    if (decision == null) return;

    final feedback = UserFeedback(
      timestamp: DateTime.now(),
      sensorSnapshotId: decision.sensorSnapshotId,
      modelConfidence: decision.modelConfidence,
      baselineVersion: decision.baselineVersion,
      userResponse: response,
      toolRecommended: response == BaselineUserResponse.notReally,
      toolStarted: false,
      toolCompleted: false,
    );
    await BaselineFeedbackStore.append(feedback);

    if (!mounted) return;
    if (response == BaselineUserResponse.okay) {
      _close();
    } else {
      setState(() {
        _lastFeedback = feedback;
        _showTools = true;
      });
    }
  }

  Future<void> _startTool(Widget screen) async {
    final feedback = _lastFeedback;
    if (feedback != null) {
      await BaselineFeedbackStore.replaceLast(
        feedback.copyWith(toolStarted: true),
      );
    }
    if (!mounted) return;
    _close();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _close() {
    unawaited(BaselineMonitor.instance.markPromptClosed(
      _decision?.sensorSnapshotId,
    ));
    setState(() {
      _decision = null;
      _lastFeedback = null;
      _showTools = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_decision != null)
          Positioned.fill(
            child: _BaselinePrompt(
              showTools: _showTools,
              onDismiss: _close,
              onOkay: () => _respond(BaselineUserResponse.okay),
              onNotReally: () => _respond(BaselineUserResponse.notReally),
              onStartTool: _startTool,
            ),
          ),
      ],
    );
  }
}

class _BaselinePrompt extends StatelessWidget {
  final bool showTools;
  final VoidCallback onDismiss;
  final VoidCallback onOkay;
  final VoidCallback onNotReally;
  final ValueChanged<Widget> onStartTool;

  const _BaselinePrompt({
    required this.showTools,
    required this.onDismiss,
    required this.onOkay,
    required this.onNotReally,
    required this.onStartTool,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.96),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  tooltip: 'Dismiss',
                ),
              ),
              const Spacer(),
              ThrivesFrogMascot(
                expression: showTools
                    ? FrogExpression.concerned
                    : FrogExpression.neutral,
              ),
              const SizedBox(height: 24),
              const Text(
                'How are you doing?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'I noticed things look a little different from your usual baseline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              if (!showTools)
                Column(
                  children: [
                    _LargeButton(
                      label: '🙂  I\'m okay',
                      color: AppColors.teal,
                      onTap: onOkay,
                    ),
                    const SizedBox(height: 12),
                    _LargeButton(
                      label: '🙁  Not really',
                      color: AppColors.surfaceVariant,
                      foreground: AppColors.textPrimary,
                      onTap: onNotReally,
                    ),
                  ],
                )
              else
                _TierOneTools(onStartTool: onStartTool),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierOneTools extends StatelessWidget {
  final ValueChanged<Widget> onStartTool;

  const _TierOneTools({required this.onStartTool});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Would one of these help?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToolButton(
                label: 'Sigh',
                icon: Icons.air_rounded,
                onTap: () => onStartTool(const PhysiologicalSighScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToolButton(
                label: 'Box',
                icon: Icons.crop_square_rounded,
                onTap: () => onStartTool(
                  const BreathingScreen(mode: BreathingMode.box),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ToolButton(
                label: 'Ground',
                icon: Icons.filter_5_rounded,
                onTap: () => onStartTool(const Grounding521Screen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToolButton(
                label: 'Vagal',
                icon: Icons.self_improvement_rounded,
                onTap: () => onStartTool(const VagalScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LargeButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;

  const _LargeButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.foreground = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

enum FrogExpression { neutral, concerned, happy }

class ThrivesFrogMascot extends StatelessWidget {
  final FrogExpression expression;
  final double size;

  const ThrivesFrogMascot({
    super.key,
    required this.expression,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FrogPainter(expression),
    );
  }
}

class _FrogPainter extends CustomPainter {
  final FrogExpression expression;

  _FrogPainter(this.expression);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = const Color(0xFF6FCF97);
    final shadow = Paint()..color = const Color(0xFF245C49);
    final eye = Paint()..color = AppColors.textPrimary;
    final pupil = Paint()..color = AppColors.background;
    final cheek = Paint()..color = const Color(0x66E8A645);
    final line = Paint()
      ..color = const Color(0xFF174238)
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.56),
        width: w * 0.78,
        height: h * 0.66,
      ),
      shadow,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.78,
        height: h * 0.66,
      ),
      body,
    );

    canvas.drawCircle(Offset(w * 0.31, h * 0.28), w * 0.17, body);
    canvas.drawCircle(Offset(w * 0.69, h * 0.28), w * 0.17, body);
    canvas.drawCircle(Offset(w * 0.31, h * 0.28), w * 0.105, eye);
    canvas.drawCircle(Offset(w * 0.69, h * 0.28), w * 0.105, eye);
    canvas.drawCircle(Offset(w * 0.31, h * 0.31), w * 0.045, pupil);
    canvas.drawCircle(Offset(w * 0.69, h * 0.31), w * 0.045, pupil);

    canvas.drawCircle(Offset(w * 0.28, h * 0.57), w * 0.055, cheek);
    canvas.drawCircle(Offset(w * 0.72, h * 0.57), w * 0.055, cheek);

    final mouth = Path();
    switch (expression) {
      case FrogExpression.neutral:
        mouth.moveTo(w * 0.39, h * 0.63);
        mouth.quadraticBezierTo(w * 0.5, h * 0.65, w * 0.61, h * 0.63);
      case FrogExpression.concerned:
        mouth.moveTo(w * 0.39, h * 0.66);
        mouth.quadraticBezierTo(w * 0.5, h * 0.61, w * 0.61, h * 0.66);
      case FrogExpression.happy:
        mouth.moveTo(w * 0.36, h * 0.62);
        mouth.quadraticBezierTo(w * 0.5, h * 0.72, w * 0.64, h * 0.62);
    }
    canvas.drawPath(mouth, line);

    final nostril = Paint()..color = const Color(0xFF174238);
    canvas.drawCircle(Offset(w * 0.44, h * 0.5), w * 0.014, nostril);
    canvas.drawCircle(Offset(w * 0.56, h * 0.5), w * 0.014, nostril);

    final foot = Paint()..color = const Color(0xFF58B883);
    for (final x in [0.28, 0.72]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w * x, h * 0.81),
          width: w * 0.24,
          height: h * 0.12,
        ),
        math.pi,
        math.pi,
        false,
        foot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrogPainter oldDelegate) {
    return oldDelegate.expression != expression;
  }
}
