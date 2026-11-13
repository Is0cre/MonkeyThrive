import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_theme.dart';

/// Two-page introduction. The last action opens the body-map check-in.
class OnboardingScreen extends StatefulWidget {
  final void Function([ToleranceState? initialWot]) onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _anchorBaseline() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await PrefsService.setOnboardingDone();
    widget.onComplete();
  }

  void _showPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            children: [
              Expanded(
                child: ScrollConfiguration(
                  // A mouse on the web build does not drag a PageView.
                  // Touch, trackpad, and mouse can all move between the pages.
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _page = index),
                    children: const [
                    _IntroPage(
                      kicker: 'Taming the storm',
                      title: 'Tame the Storm',
                      body:
                          'The nervous system can feel like weather you did not choose. '
                          'Taming it means learning the shape of that weather: when to slow down, '
                          'when to stay, and when a tool stays closed. '
                          'Like Sun Wukong learning to hold his own chaos, '
                          'this is practice in self-regulation.',
                      figureAsset: 'assets/brand/monkey_king.png',
                    ),
                    _IntroPage(
                      kicker: 'On this device',
                      title: 'Zero Tracking. Zero Guilt.',
                      body:
                          'Check-ins, journal entries, and sensor readings stay on this device. '
                          'There is no account, no streak, and no score for the days you were away. '
                          'Nothing here is sent or sold.',
                      footnote:
                          'MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy. '
                          'If you are in immediate danger, contact emergency services.',
                    ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _PageDots(
                index: _page,
                count: 2,
                onSelect: _showPage,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _finishing
                      ? null
                      : _page == 1
                          ? _anchorBaseline
                          : () => _showPage(1),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor:
                        AppColors.amber.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    _page == 1 ? 'Anchor your baseline' : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String kicker;
  final String title;
  final String body;
  final String? footnote;
  final String? figureAsset;

  const _IntroPage({
    required this.kicker,
    required this.title,
    required this.body,
    this.footnote,
    this.figureAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (figureAsset != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Semantics(
                image: true,
                label: 'Sun Wukong in red and gold, holding a phone.',
                child: SizedBox.expand(
                  key: const Key('opening-figure'),
                  child: Image.asset(
                    figureAsset!,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        Text(
          kicker.toUpperCase(),
          style: const TextStyle(
            color: AppColors.amber,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 36,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 20),
        Text(
          body,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            height: 1.6,
          ),
        ),
        if (figureAsset == null) const Spacer(),
        if (footnote != null)
          Text(
            footnote!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int index;
  final int count;
  final ValueChanged<int> onSelect;

  const _PageDots({
    required this.index,
    required this.count,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Page ${i + 1}',
            selected: i == index,
            child: GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == index ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        i == index ? AppColors.amber : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
