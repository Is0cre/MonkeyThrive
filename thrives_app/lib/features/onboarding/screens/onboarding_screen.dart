import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function([ToleranceState? initialWot]) onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Answers
  String? _primaryGoal;
  String? _familiarity;
  String? _wearable; // 'yes' | 'camera' | 'none'
  String? _workStyle;
  bool _reduceMotion = false;
  bool _reduceAudio = false;
  bool _reduceVibration = false;
  String? _hasTherapist;
  // Crisis screen — if true, show emergency route
  bool _acuteCrisis = false;

  void _next() {
    if (_page < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete({ToleranceState? initialWot}) async {
    await PrefsService.saveProfile(
      primaryGoal: _primaryGoal ?? '',
      familiarity: _familiarity ?? '',
      hasWearable: _wearable == 'yes',
      workStyle: _workStyle ?? '',
      reduceMotion: _reduceMotion,
      reduceAudio: _reduceAudio,
      reduceVibration: _reduceVibration,
      hasTherapist: _hasTherapist ?? '',
    );
    if (initialWot != null) {
      await PrefsService.saveWotState(initialWot);
    }
    await PrefsService.setOnboardingDone();
    widget.onComplete(initialWot);
  }

  bool get _canAdvance {
    switch (_page) {
      case 0:
        return true; // welcome — always can advance
      case 1:
        return _primaryGoal != null;
      case 2:
        return _familiarity != null;
      case 3:
        return _wearable != null;
      case 4:
        return _workStyle != null;
      case 5:
        return true; // sensitivity — all optional
      case 6:
        return _hasTherapist != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _ProgressBar(current: _page, total: 7),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(),
                  _ChoicePage(
                    question: 'What brings you here?',
                    choices: const [
                      _Choice('sleep', 'Sleep difficulties'),
                      _Choice('anxiety', 'Anxiety and stress'),
                      _Choice('trauma', 'Trauma processing'),
                      _Choice(
                          'regulation', 'General nervous system regulation'),
                      _Choice('growth', 'Curiosity / personal growth'),
                      _Choice('multiple', 'Several of the above'),
                    ],
                    selected: _primaryGoal,
                    onSelect: (v) => setState(() => _primaryGoal = v),
                  ),
                  _ChoicePage(
                    question: 'How familiar are you with these tools?',
                    choices: const [
                      _Choice('beginner', 'Complete beginner'),
                      _Choice('some',
                          'Some experience with meditation or breathing'),
                      _Choice('somatic',
                          'Familiar with somatic or trauma-informed therapy'),
                      _Choice('practitioner', 'Experienced practitioner'),
                    ],
                    selected: _familiarity,
                    onSelect: (v) => setState(() => _familiarity = v),
                  ),
                  _ChoicePage(
                    question: 'Do you have a smartwatch or fitness tracker?',
                    choices: const [
                      _Choice('yes',
                          'Yes — WearOS, Garmin, Fitbit, Polar, or similar'),
                      _Choice('camera', 'No — I\'ll use the phone camera'),
                      _Choice('none', 'No biofeedback for now'),
                    ],
                    selected: _wearable,
                    onSelect: (v) => setState(() => _wearable = v),
                  ),
                  _ChoicePage(
                    question: 'How do you prefer to work?',
                    choices: const [
                      _Choice('guided', 'Guide me — I\'ll follow suggestions'),
                      _Choice('explore', 'Give me the tools, I\'ll explore'),
                      _Choice('mix', 'A mix of both'),
                    ],
                    selected: _workStyle,
                    onSelect: (v) => setState(() => _workStyle = v),
                  ),
                  _SensitivityPage(
                    reduceMotion: _reduceMotion,
                    reduceAudio: _reduceAudio,
                    reduceVibration: _reduceVibration,
                    onMotion: (v) => setState(() => _reduceMotion = v),
                    onAudio: (v) => setState(() => _reduceAudio = v),
                    onVibration: (v) => setState(() => _reduceVibration = v),
                  ),
                  _SafetyPage(
                    hasTherapist: _hasTherapist,
                    acuteCrisis: _acuteCrisis,
                    onTherapist: (v) => setState(() => _hasTherapist = v),
                    onCrisis: (v) {
                      setState(() => _acuteCrisis = v);
                      if (v) {
                        // Route directly to Regulate with only all-state tools
                        // available. Hyperaroused is the safest conservative
                        // state for acute distress.
                        _complete(initialWot: ToleranceState.hyperaroused);
                      }
                    },
                    onComplete: _canAdvance ? () => _complete() : null,
                  ),
                ],
              ),
            ),

            // Nav buttons
            if (_page < 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    if (_page > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.textSecondary,
                        onPressed: _prev,
                      ),
                    const Spacer(),
                    if (_page == 0)
                      FilledButton(
                        onPressed: _next,
                        style: _primaryStyle,
                        child: const Text('Get started'),
                      )
                    else
                      FilledButton(
                        onPressed: _canAdvance ? _next : null,
                        style: _primaryStyle,
                        child: Text(_page == 5 ? 'Almost done' : 'Continue'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _primaryStyle => FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.background,
        minimumSize: const Size(140, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      );
}

// ─── Pages ───────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THRIVES',
            style: TextStyle(
              color: AppColors.teal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          const Text(
            'A few quick questions to set up your profile. '
            'Your answers stay on this device — nothing is sent anywhere.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can change everything later in settings. '
            'There are no wrong answers.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const Spacer(),
          const _DisclaimerBox(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DisclaimerBox extends StatelessWidget {
  const _DisclaimerBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'THRIVES is a wellness tool, not a replacement for therapy or medical care. '
        'If you are in immediate danger, please contact emergency services.',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _Choice {
  final String value;
  final String label;
  const _Choice(this.value, this.label);
}

class _ChoicePage extends StatelessWidget {
  final String question;
  final List<_Choice> choices;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ChoicePage({
    required this.question,
    required this.choices,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: [
        Text(question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        for (final choice in choices) ...[
          _ChoiceTile(
            label: choice.label,
            selected: selected == choice.value,
            onTap: () => onSelect(choice.value),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: AppColors.teal, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SensitivityPage extends StatelessWidget {
  final bool reduceMotion;
  final bool reduceAudio;
  final bool reduceVibration;
  final ValueChanged<bool> onMotion;
  final ValueChanged<bool> onAudio;
  final ValueChanged<bool> onVibration;

  const _SensitivityPage({
    required this.reduceMotion,
    required this.reduceAudio,
    required this.reduceVibration,
    required this.onMotion,
    required this.onAudio,
    required this.onVibration,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: [
        Text('Any sensitivities?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'These help us show you what\'s right for you. All off by default.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        _SensitivityTile(
          label: 'Reduce animations',
          subtitle: 'Avoid moving or pulsing visuals',
          value: reduceMotion,
          onChanged: onMotion,
        ),
        const SizedBox(height: 12),
        _SensitivityTile(
          label: 'Prefer low-intensity audio',
          subtitle: 'Soft tones only, no sudden sounds',
          value: reduceAudio,
          onChanged: onAudio,
        ),
        const SizedBox(height: 12),
        _SensitivityTile(
          label: 'Avoid vibration',
          subtitle: 'Disable haptic feedback',
          value: reduceVibration,
          onChanged: onVibration,
        ),
      ],
    );
  }
}

class _SensitivityTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SensitivityTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: value
              ? AppColors.teal.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.teal : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: value
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.teal,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyPage extends StatelessWidget {
  final String? hasTherapist;
  final bool acuteCrisis;
  final ValueChanged<String> onTherapist;
  final ValueChanged<bool> onCrisis;
  final VoidCallback? onComplete;

  const _SafetyPage({
    required this.hasTherapist,
    required this.acuteCrisis,
    required this.onTherapist,
    required this.onCrisis,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        Text('A couple of safety questions.',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'These help us point you in the right direction.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        const Text('Are you currently working with a therapist?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w400)),
        const SizedBox(height: 12),
        for (final opt in [
          ('yes', 'Yes'),
          ('no', 'Not currently'),
          ('seeking', 'No, and I\'d like to find one'),
        ]) ...[
          _ChoiceTile(
            label: opt.$2,
            selected: hasTherapist == opt.$1,
            onTap: () => onTherapist(opt.$1),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 28),
        const Text('Are you in acute distress right now?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        const Text(
          'If yes, we\'ll take you straight to grounding tools.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _ChoiceTile(
          label: 'Yes — I need help right now',
          selected: acuteCrisis,
          onTap: () => onCrisis(true),
        ),
        const SizedBox(height: 8),
        _ChoiceTile(
          label: 'No — I\'m okay',
          selected: !acuteCrisis,
          onTap: () => onCrisis(false),
        ),
        const SizedBox(height: 32),
        if (onComplete != null && !acuteCrisis)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onComplete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              child: const Text('Take me in'),
            ),
          ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.teal : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
