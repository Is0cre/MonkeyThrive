import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/storage/prefs_service.dart';
import 'package:monkeythrive/core/storage/session_log.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/core/widgets/feeling_better_prompt.dart';
import 'package:monkeythrive/features/regulate/screens/breathing_screen.dart';
import 'package:monkeythrive/features/regulate/screens/grounding_521_screen.dart';
import 'package:monkeythrive/features/regulate/screens/panic_screen.dart';
import 'package:monkeythrive/features/regulate/screens/vagal_screen.dart';
import 'package:monkeythrive/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ValueNotifier<ToleranceState?>> pumpPrompt(
    WidgetTester tester,
    ToleranceState? state,
  ) async {
    final wot = ValueNotifier<ToleranceState?>(state);
    await tester.pumpWidget(
      WoTScope(
        notifier: wot,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: Center(child: FeelingBetterPrompt())),
        ),
      ),
    );
    return wot;
  }

  testWidgets('not yet leaves the reading unchanged', (tester) async {
    final wot = await pumpPrompt(tester, ToleranceState.hyperaroused);

    await tester.tap(find.byKey(const Key('feeling-better-not-yet')));
    await tester.pump();

    expect(find.text('The reading stays as it is.'), findsOneWidget);
    expect(wot.value, ToleranceState.hyperaroused);
    expect(await PrefsService.loadTodaysWotState(), isNull);
    expect(await SessionLog.getToleranceLog(), isEmpty);
  });

  testWidgets('yes writes today as present through the check-in path',
      (tester) async {
    final wot = ValueNotifier<ToleranceState?>(ToleranceState.hypoaroused);
    await tester.pumpWidget(
      WoTScope(
        notifier: wot,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: Center(child: FeelingBetterPrompt())),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('feeling-better-yes')));
    await tester.pump();
    await tester.pump();

    expect(wot.value, ToleranceState.regulated);
    expect(await PrefsService.loadTodaysWotState(), ToleranceState.regulated);
    final log = await SessionLog.getToleranceLog();
    expect(log.single.state, ToleranceState.regulated.name);
    expect(find.text('Marked as present.'), findsOneWidget);
  });

  testWidgets('yes is a no-op when the reading is already present',
      (tester) async {
    final wot = await pumpPrompt(tester, ToleranceState.regulated);
    await tester.tap(find.byKey(const Key('feeling-better-yes')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Still marked as present.'), findsOneWidget);
    expect(wot.value, ToleranceState.regulated);
    expect(await SessionLog.getToleranceLog(), isEmpty);
  });

  testWidgets('box breathing stops after four cycles and then asks',
      (tester) async {
    final wot = ValueNotifier<ToleranceState?>(ToleranceState.hyperaroused);
    await tester.pumpWidget(
      WoTScope(
        notifier: wot,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const BreathingScreen(mode: BreathingMode.box),
        ),
      ),
    );

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Begin'));
    await tester.pump();

    expect(find.text('Cycle 1 of 3'), findsOneWidget);
    expect(find.text('Are you feeling better?'), findsNothing);

    for (var second = 0; second < 48; second++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Are you feeling better?'), findsOneWidget);
    expect(find.text('Begin'), findsNothing);
    expect(find.byKey(const Key('breathing-again')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('feeling-better-yes')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('feeling-better-yes')));
    await tester.pump();
    await tester.pump();

    expect(wot.value, ToleranceState.regulated);
    expect(await PrefsService.loadTodaysWotState(), ToleranceState.regulated);
    expect(find.text('Marked as present.'), findsOneWidget);
  });

  testWidgets('grounding asks after the last sense', (tester) async {
    await tester.pumpWidget(
      WoTScope(
        notifier: ValueNotifier<ToleranceState?>(ToleranceState.hyperaroused),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Grounding521Screen(),
        ),
      ),
    );
    await tester.pump();

    for (var step = 0; step < 4; step++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.text('Complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Are you feeling better?'), findsOneWidget);
    expect(find.text('You are here.'), findsOneWidget);
  });

  testWidgets('a vagal guide asks when it is done', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const VagalScreen(),
      ),
    );
    await tester.tap(find.text('Humming'));
    await tester.pumpAndSettle();
    expect(find.text('Are you feeling better?'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('Are you feeling better?'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('anchor asks after the sighs and then offers setup',
      (tester) async {
    final wot = ValueNotifier<ToleranceState?>(ToleranceState.hyperaroused);
    await tester.pumpWidget(
      WoTScope(
        notifier: wot,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const PanicScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Are you feeling better?'), findsNothing);

    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pump();
    await tester.pump();

    expect(find.text('Are you feeling better?'), findsOneWidget);
    expect(find.byKey(const Key('trusted-closed')), findsOneWidget);
    expect(find.byKey(const Key('trusted-setup')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('feeling-better-yes')));
    await tester.tap(find.byKey(const Key('feeling-better-yes')));
    await tester.pump();
    await tester.pump();

    expect(wot.value, ToleranceState.regulated);
    expect(find.text('Marked as present.'), findsOneWidget);
    expect(find.byKey(const Key('trusted-setup')), findsOneWidget);
    expect(find.byKey(const Key('trusted-closed')), findsNothing);
  });

  testWidgets('the settings note stays readable while overwhelmed',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      WoTScope(
        notifier: ValueNotifier<ToleranceState?>(ToleranceState.hyperaroused),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: SettingsScreen(onResetOnboarding: () {}),
        ),
      ),
    );
    await tester.pump();

    final note = find.text('Available when the reading is present.');
    await tester.ensureVisible(note);
    await tester.pump();
    final text = tester.widget<Text>(note);
    expect(text.style?.color, AppColors.textPrimary);
  });
}
