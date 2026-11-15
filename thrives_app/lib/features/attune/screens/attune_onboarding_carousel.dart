import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../widgets/attune_listening.dart';

/// Four cards before Attune can play.
///
/// The first visit has no close. The last card is the listening confirmation.
/// All three lines have to be checked before the deck can finish.
class AttuneOnboardingCarousel extends StatefulWidget {
  final Future<void> Function() onAccepted;
  final VoidCallback onOpenPhysics;

  const AttuneOnboardingCarousel({
    super.key,
    required this.onAccepted,
    required this.onOpenPhysics,
  });

  @override
  State<AttuneOnboardingCarousel> createState() =>
      _AttuneOnboardingCarouselState();
}

class _AttuneOnboardingCarouselState extends State<AttuneOnboardingCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  double _pageValue() {
    if (!_pageController.hasClients) return _page.toDouble();
    return _pageController.page ?? _page.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = <Widget>[
      _InfoCard(
        icon: Icons.headphones_rounded,
        kicker: l10n.attuneIntroKicker1,
        title: l10n.attuneIntroTitle1,
        body: l10n.attuneIntroBody1,
      ),
      _InfoCard(
        icon: Icons.hearing_rounded,
        kicker: l10n.attuneIntroKicker2,
        title: l10n.attuneIntroTitle2,
        body: l10n.attuneIntroBody2,
        footnote: l10n.attuneIntroFootnote,
      ),
      _InfoCard(
        icon: Icons.graphic_eq_rounded,
        kicker: l10n.physicsTitle,
        title: l10n.physicsFollowingTitle,
        body: l10n.physicsFollowingBody,
      ),
      _KeepAlive(
        child: AttuneWaiverGate(
          embedded: true,
          actionLabel: l10n.attuneCarouselAccept,
          onAccepted: widget.onAccepted,
          onOpenPhysics: widget.onOpenPhysics,
        ),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ScrollConfiguration(
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
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          final distance = (_pageValue() - i).abs();
                          final opacity = (1 - distance).clamp(0.0, 1.0);
                          return Opacity(opacity: opacity, child: child);
                        },
                        child: pages[i],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DeckDots(index: _page, count: pages.length, onSelect: _showPage),
            if (_page < pages.length - 1) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _showPage(_page + 1),
                  style: FilledButton.styleFrom(
                    backgroundColor: attuneViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.continueAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String kicker;
  final String title;
  final String body;
  final String? footnote;

  const _InfoCard({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.body,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 48, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: attuneViolet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: attuneViolet.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, color: attuneViolet, size: 28),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            kicker.toUpperCase(),
            style: const TextStyle(
              color: attuneViolet,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
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
          if (footnote != null) ...[
            const SizedBox(height: 28),
            Text(
              footnote!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeckDots extends StatelessWidget {
  final int index;
  final int count;
  final ValueChanged<int> onSelect;

  const _DeckDots({
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
            label: context.l10n.pageLabel(i + 1),
            selected: i == index,
            child: GestureDetector(
              key: Key('attune-onboarding-dot-$i'),
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == index ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == index ? attuneViolet : AppColors.surfaceVariant,
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

/// Keeps the confirmation checks if the person swipes back to reread.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
