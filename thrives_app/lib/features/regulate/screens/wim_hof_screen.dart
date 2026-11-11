import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

enum _WimHofPhase { idle, breathing, exhaleHold, recovery, retentionHold, done }

class WimHofScreen extends StatefulWidget {
  const WimHofScreen({super.key});

  @override
  State<WimHofScreen> createState() => _WimHofScreenState();
}

class _WimHofScreenState extends State<WimHofScreen>
    with TickerProviderStateMixin, SessionTracking {
  static const int _totalBreaths = 30;
  static const _safetyItems = [
    'I am not in water, driving, or standing.',
    'I am lying down or seated somewhere safe.',
    'I do not have a seizure disorder.',
    'I do not have a serious heart, blood pressure, or respiratory condition.',
    'I am not pregnant.',
    'If this is my first time, another person is nearby.',
    'I will stop immediately if I feel unwell.',
  ];

  _WimHofPhase _phase = _WimHofPhase.idle;
  int _breathCount = 0;
  int _timerSeconds = 0;
  int _round = 1;
  Timer? _timer;
  final Set<int> _confirmedSafetyItems = {};

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    final wot = WoTScope.stateOf(context);
    if (wot == null || !wot.canWimHof) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wim Hof breathing is only available when present.'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_confirmedSafetyItems.length != _safetyItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the safety checks before starting.'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    beginTracking('Wim Hof', 'Regulate', onEmergencyStop: _reset);
    setState(() {
      _phase = _WimHofPhase.breathing;
      _breathCount = 0;
    });
    // Each breath ~2s — we tick breath count with a timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _breathCount++;
        if (_breathCount >= _totalBreaths) {
          _timer?.cancel();
          _phase = _WimHofPhase.exhaleHold;
          _startCountup();
        }
      });
    });
  }

  void _startCountup() {
    _timerSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timerSeconds++);
    });
  }

  void _advanceFromExhaleHold() {
    _timer?.cancel();
    setState(() {
      _phase = _WimHofPhase.recovery;
      _timerSeconds = 0;
    });
    // Recovery breath — hold for 15s
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timerSeconds++;
        if (_timerSeconds >= 15) {
          _timer?.cancel();
          _phase = _WimHofPhase.retentionHold;
          _startCountup();
        }
      });
    });
  }

  void _advanceFromRetention() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _WimHofPhase.done;
    });
  }

  void _nextRound() {
    setState(() {
      _round++;
      _phase = _WimHofPhase.idle;
      _breathCount = 0;
      _timerSeconds = 0;
      _confirmedSafetyItems.clear();
    });
  }

  void _reset() {
    _timer?.cancel();
    endTracking();
    if (!mounted) return;
    setState(() {
      _phase = _WimHofPhase.idle;
      _breathCount = 0;
      _timerSeconds = 0;
      _round = 1;
      _confirmedSafetyItems.clear();
    });
  }

  String get _timerDisplay {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wim Hof Breathing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _reset();
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: const AnchorBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Safety warning — always visible
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.dangerSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Never practice in water or while driving. '
                        'Stop if you feel unwell.',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Round $_round',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(child: _buildPhaseContent(context)),

              _buildButton(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent(BuildContext context) {
    switch (_phase) {
      case _WimHofPhase.idle:
        return _buildSafetyGate();

      case _WimHofPhase.breathing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = 0.8 + (_pulseController.value * 0.2);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.teal.withValues(
                          alpha: 0.12 + _pulseController.value * 0.1),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              '$_breathCount / $_totalBreaths',
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 32,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'breathe in · let go',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );

      case _WimHofPhase.exhaleHold:
        return _CentredContent(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Exhale & Hold',
          body: 'Let all the air out and hold. '
              'Do not force it. Hold as long as comfortable.',
          timerDisplay: _timerDisplay,
          timerColor: AppColors.amber,
        );

      case _WimHofPhase.recovery:
        return _CentredContent(
          icon: Icons.air_rounded,
          title: 'Recovery Breath',
          body: 'Take one deep breath in and hold for 15 seconds.',
          timerDisplay: _timerDisplay,
          timerColor: AppColors.teal,
        );

      case _WimHofPhase.retentionHold:
        return _CentredContent(
          icon: Icons.self_improvement_rounded,
          title: 'Retention Hold',
          body: 'Hold. Feel the stillness.',
          timerDisplay: _timerDisplay,
          timerColor: AppColors.teal,
        );

      case _WimHofPhase.done:
        return _CentredContent(
          icon: Icons.check_circle_outline_rounded,
          title: 'Round $_round complete',
          body: 'Rest for a moment before your next round, '
              'or finish here.',
        );
    }
  }

  Widget _buildButton(BuildContext context) {
    switch (_phase) {
      case _WimHofPhase.idle:
        return _BigButton(
          label: 'Begin',
          color: AppColors.teal,
          onTap: _confirmedSafetyItems.length == _safetyItems.length
              ? _startBreathing
              : null,
        );
      case _WimHofPhase.breathing:
        return const SizedBox.shrink();
      case _WimHofPhase.exhaleHold:
        return _BigButton(
          label: 'I\'m ready — recovery breath',
          color: AppColors.amber,
          onTap: _advanceFromExhaleHold,
        );
      case _WimHofPhase.recovery:
        return const SizedBox.shrink(); // auto-advances
      case _WimHofPhase.retentionHold:
        return _BigButton(
          label: 'Release',
          color: AppColors.teal,
          onTap: _advanceFromRetention,
        );
      case _WimHofPhase.done:
        return Column(
          children: [
            _BigButton(
              label: 'Next round',
              color: AppColors.teal,
              onTap: _nextRound,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _reset();
                Navigator.pop(context);
              },
              child: const Text(
                'Finish',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSafetyGate() {
    return ListView(
      children: [
        const _CentredContent(
          icon: Icons.waves_rounded,
          title: '30 Deep Breaths',
          body: 'Breathe in fully, let go without forcing. '
              'After 30 breaths, exhale and hold only as long as comfortable.',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _safetyItems.length; i++)
          CheckboxListTile(
            value: _confirmedSafetyItems.contains(i),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _confirmedSafetyItems.add(i);
                } else {
                  _confirmedSafetyItems.remove(i);
                }
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.teal,
            checkColor: AppColors.background,
            title: Text(
              _safetyItems[i],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}

class _CentredContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? timerDisplay;
  final Color? timerColor;

  const _CentredContent({
    required this.icon,
    required this.title,
    required this.body,
    this.timerDisplay,
    this.timerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.teal, size: 52),
        const SizedBox(height: 24),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        if (timerDisplay != null) ...[
          const SizedBox(height: 32),
          Text(
            timerDisplay!,
            style: TextStyle(
              color: timerColor ?? AppColors.teal,
              fontSize: 44,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _BigButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.background,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
