import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

/// Two pages before a binaural or isochronic tone can play.
///
/// The first visit has no skip. A later visit can close and return to Attune.
class AttuneFrequencyIntro extends StatefulWidget {
  final Future<void> Function() onDone;
  final VoidCallback? onClose;
  final bool allowClose;

  const AttuneFrequencyIntro({
    super.key,
    required this.onDone,
    this.onClose,
    this.allowClose = false,
  });

  @override
  State<AttuneFrequencyIntro> createState() => _AttuneFrequencyIntroState();
}

class _AttuneFrequencyIntroState extends State<AttuneFrequencyIntro> {
  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPage(int page) {
    _pageController.animateToPage(
      page,
      duration: AppMotion.settle,
      curve: AppMotion.arrive,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.allowClose)
              IconButton(
                onPressed: widget.onClose,
                tooltip: l10n.close,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                ),
              )
            else
              const SizedBox(height: 12),
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
                    _FrequencyPage(
                      kicker: l10n.attuneIntroKicker1,
                      title: l10n.attuneIntroTitle1,
                      body: l10n.attuneIntroBody1,
                    ),
                    _FrequencyPage(
                      kicker: l10n.attuneIntroKicker2,
                      title: l10n.attuneIntroTitle2,
                      body: l10n.attuneIntroBody2,
                      footnote: l10n.attuneIntroFootnote,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PageDots(index: _page, onSelect: _showPage),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _finishing
                    ? null
                    : _page == 0
                        ? () => _showPage(1)
                        : _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  _page == 0 ? l10n.continueAction : l10n.attuneIntroUnderstand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyPage extends StatelessWidget {
  final String kicker;
  final String title;
  final String body;
  final String? footnote;

  const _FrequencyPage({
    required this.kicker,
    required this.title,
    required this.body,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 36, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
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

class _PageDots extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _PageDots({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Semantics(
            button: true,
            label: context.l10n.pageLabel(i + 1),
            selected: i == index,
            child: GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedContainer(
                  duration: AppMotion.press,
                  curve: AppMotion.arrive,
                  width: i == index ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
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
