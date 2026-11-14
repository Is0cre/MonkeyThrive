import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import '../../../core/widgets/feeling_better_prompt.dart';
import '../../../l10n/l10n.dart';

enum _WimHofPhase { idle, breathing, exhaleHold, recovery, retentionHold, done }

class WimHofScreen extends StatefulWidget {
  const WimHofScreen({super.key});

  @override
  State<WimHofScreen> createState() => _WimHofScreenState();
}

class _WimHofScreenState extends State<WimHofScreen>
    with TickerProviderStateMixin, SessionTracking {
  static const int _totalBreaths = 30;

  List<String> _safetyItems(AppLocalizations l10n) => [
        l10n.wimHofCheck1,
        l10n.wimHofCheck2,
        l10n.wimHofCheck3,
        l10n.wimHofCheck4,
        l10n.wimHofCheck5,
        l10n.wimHofCheck6,
        l10n.wimHofCheck7,
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
        SnackBar(
          content: Text(context.l10n.wimHofOnlyWhenPresent),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_confirmedSafetyItems.length != _safetyItems(context.l10n).length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.wimHofChecksFirst),
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

  String _timerDisplay(AppLocalizations l10n) {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    if (m > 0) return l10n.timerClock(m, s.toString().padLeft(2, '0'));
    return l10n.timerSecondsOnly(s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wimHofTitle),
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
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.wimHofWarning,
                        style: const TextStyle(
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
                l10n.roundNumber(_round),
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
              context.l10n.breathFraction(_breathCount, _totalBreaths),
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 32,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.wimHofLetGo,
              style: const TextStyle(
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
          title: context.l10n.exhaleAndHold,
          body: context.l10n.wimHofExhaleBody,
          timerDisplay: _timerDisplay(context.l10n),
          timerColor: AppColors.amber,
        );

      case _WimHofPhase.recovery:
        return _CentredContent(
          icon: Icons.air_rounded,
          title: context.l10n.recoveryBreath,
          body: context.l10n.wimHofRecoveryBody,
          timerDisplay: _timerDisplay(context.l10n),
          timerColor: AppColors.teal,
        );

      case _WimHofPhase.retentionHold:
        return _CentredContent(
          icon: Icons.self_improvement_rounded,
          title: context.l10n.retentionHold,
          body: context.l10n.wimHofStillness,
          timerDisplay: _timerDisplay(context.l10n),
          timerColor: AppColors.teal,
        );

      case _WimHofPhase.done:
        return _CentredContent(
          icon: Icons.check_circle_outline_rounded,
          title: context.l10n.roundComplete(_round),
          body: context.l10n.wimHofRoundRest,
        );
    }
  }

  Widget _buildButton(BuildContext context) {
    switch (_phase) {
      case _WimHofPhase.idle:
        return _BigButton(
          label: context.l10n.breathingBegin,
          color: AppColors.teal,
          onTap: _confirmedSafetyItems.length ==
                  _safetyItems(context.l10n).length
              ? _startBreathing
              : null,
        );
      case _WimHofPhase.breathing:
        return const SizedBox.shrink();
      case _WimHofPhase.exhaleHold:
        return _BigButton(
          label: context.l10n.readyRecovery,
          color: AppColors.amber,
          onTap: _advanceFromExhaleHold,
        );
      case _WimHofPhase.recovery:
        return const SizedBox.shrink(); // auto-advances
      case _WimHofPhase.retentionHold:
        return _BigButton(
          label: context.l10n.release,
          color: AppColors.teal,
          onTap: _advanceFromRetention,
        );
      case _WimHofPhase.done:
        return Column(
          children: [
            const FeelingBetterPrompt(),
            const SizedBox(height: 16),
            _BigButton(
              label: context.l10n.nextRound,
              color: AppColors.teal,
              onTap: _nextRound,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _reset();
                Navigator.pop(context);
              },
              child: Text(
                context.l10n.finish,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSafetyGate() {
    final l10n = context.l10n;
    final items = _safetyItems(l10n);
    return ListView(
      children: [
        _CentredContent(
          icon: Icons.waves_rounded,
          title: l10n.thirtyBreaths,
          body: l10n.thirtyBreathsBody,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
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
              items[i],
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
