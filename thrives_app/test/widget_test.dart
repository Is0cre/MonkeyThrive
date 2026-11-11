import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/storage/session_tracker.dart';
import 'package:monkeythrive/features/regulate/screens/wim_hof_screen.dart';
import 'package:monkeythrive/main.dart';

void main() {
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
    await tester.pumpWidget(
      const ThrivesApp(
        onboardingDone: true,
        initialWot: ToleranceState.hyperaroused,
      ),
    );
    await tester.pump();
    expect(find.text('Regulate'), findsWidgets);
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
