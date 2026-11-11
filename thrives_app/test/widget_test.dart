import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/storage/session_tracker.dart';
import 'package:monkeythrive/features/regulate/screens/panic_screen.dart';
import 'package:monkeythrive/features/regulate/screens/wim_hof_screen.dart';
import 'package:monkeythrive/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('intro swipe ends on the body map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ThrivesApp(onboardingDone: false, initialWot: null),
    );
    await tester.pump();

    expect(find.text('Tame the Storm'), findsOneWidget);
    expect(find.text('Anchor your baseline'), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Zero Tracking. Zero Guilt.'), findsOneWidget);
    await tester.tap(find.text('Anchor your baseline'));
    await tester.pumpAndSettle();

    expect(find.text('how are you\nright now?'), findsOneWidget);
    expect(find.bySemanticsLabel('Chest, unmarked'), findsOneWidget);
  });

  testWidgets('App asks for check-in when onboarding is done without WoT',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ThrivesApp(onboardingDone: true, initialWot: null),
    );
    await tester.pump();
    expect(find.text('how are you\nright now?'), findsOneWidget);
  });

  testWidgets('App shows shell when onboarding is done with WoT',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ThrivesApp(
        onboardingDone: true,
        initialWot: ToleranceState.hyperaroused,
      ),
    );
    await tester.pump();
    expect(find.text('Regulate'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.bySemanticsLabel('Anchor'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.audioVolumeDown);
    // The hero controller parks a new route offstage for the frame it is
    // pushed. The following frame brings the black screen onstage.
    await tester.pump();
    await tester.pump();
    expect(find.byType(PanicScreen), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(PanicScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, const Color(0xFF000000));
    expect(find.text('breathe in'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('panic screen stays black with no choices during the sigh',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: PanicScreen()));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF000000));
    expect(find.text('breathe in'), findsNothing);
    expect(find.text('go to regulate'), findsNothing);
    expect(find.text("I'm ok"), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Wim Hof requires per-session safety confirmations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      WoTScope(
        notifier: ValueNotifier<ToleranceState?>(ToleranceState.regulated),
        child: const MaterialApp(home: WimHofScreen()),
      ),
    );
    await tester.pump();

    FilledButton beginButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Begin'));

    expect(beginButton().onPressed, isNull);

    const safetyItems = [
      'I am not in water, driving, or standing.',
      'I am lying down or seated somewhere safe.',
      'I do not have a seizure disorder.',
      'I do not have a serious heart, blood pressure, or respiratory condition.',
      'I am not pregnant.',
      'If this is my first time, another person is nearby.',
      'I will stop immediately if I feel unwell.',
    ];

    for (final item in safetyItems) {
      final checkbox = find.widgetWithText(CheckboxListTile, item);
      await tester.scrollUntilVisible(
        checkbox,
        80,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(checkbox);
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Begin'));
    await tester.pump();

    expect(beginButton().onPressed, isNotNull);
  });

  testWidgets(
      'Bilateral stimulation shows clinical disclaimer and halts on emergency bailout',
      (WidgetTester tester) async {
    bool stopped = false;
    SessionActivity.begin(onEmergencyBailout: () => stopped = true);
    expect(SessionActivity.isActive, isTrue);

    SessionActivity.triggerEmergencyBailout();
    expect(stopped, isTrue);
    SessionActivity.end();
    expect(SessionActivity.isActive, isFalse);
  });
}
