import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/storage/prefs_service.dart';
import 'package:monkeythrive/features/attune/attune_dosage.dart';
import 'package:monkeythrive/features/attune/screens/attune_home_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('listening time stays on today and a later day starts again', () async {
    var now = DateTime(2026, 11, 15, 9);
    final dosage = AttuneDosage(now: () => now);

    expect(await dosage.todaySeconds(), 0);
    dosage.begin();
    dosage.begin();
    now = now.add(const Duration(minutes: 10));
    await dosage.end();
    expect(await dosage.todaySeconds(), 10 * 60);

    dosage.begin();
    now = now.add(const Duration(seconds: 20));
    await dosage.checkpointIfDue(due: const Duration(seconds: 15));
    now = now.add(const Duration(seconds: 10));
    await dosage.end();
    expect(await dosage.todaySeconds(), 10 * 60 + 30);

    now = DateTime(2026, 11, 16, 8);
    expect(await dosage.todaySeconds(), 0);
    expect(AttuneDosage.needsWarning(45 * 60), isFalse);
    expect(AttuneDosage.needsWarning(45 * 60 + 1), isTrue);
  });

  testWidgets('the dosage note stays off the introduction', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const AttuneHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Two tones, one in each ear'), findsOneWidget);
    expect(find.text('Daily limit'), findsNothing);
    expect(find.byKey(const Key('attune-dosage-note')), findsNothing);
  });

  testWidgets('a finished introduction shows the daily limit and today',
      (tester) async {
    final today = AttuneDosage.stamp(DateTime.now());
    SharedPreferences.setMockInitialValues({
      PrefsService.attuneIntroKey: true,
      PrefsService.attuneWaiverKey: true,
      AttuneDosage.dayKey: today,
      AttuneDosage.secondsKey: 120,
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const AttuneHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attune-dosage-note')), findsOneWidget);
    expect(find.text('Daily limit'), findsOneWidget);
    expect(find.textContaining('heavy machinery'), findsOneWidget);
    expect(find.textContaining('45 minutes a day'), findsOneWidget);
    expect(find.text('2 minutes today'), findsOneWidget);
    expect(find.textContaining('forcefully'), findsNothing);
    expect(find.text('Play'), findsNothing);
  });

  testWidgets('past 45 minutes can be left or continued', (tester) async {
    await tester.pumpWidget(_app(const _DosageAsk()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    expect(find.text('Past the daily limit'), findsOneWidget);
    expect(
      find.textContaining('past 45 minutes of Attune today'),
      findsOneWidget,
    );
    expect(find.textContaining('drowsy or groggy'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('no'), findsOneWidget);
    expect(find.text('Past the daily limit'), findsNothing);

    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attune-dosage-continue')));
    await tester.pumpAndSettle();
    expect(find.text('yes'), findsOneWidget);
  });
}

Widget _app(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: home),
  );
}

class _DosageAsk extends StatefulWidget {
  const _DosageAsk();

  @override
  State<_DosageAsk> createState() => _DosageAskState();
}

class _DosageAskState extends State<_DosageAsk> {
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_result),
        TextButton(
          onPressed: () async {
            final proceed = await confirmAttunePastDailyLimit(context);
            if (!mounted) return;
            setState(() => _result = proceed ? 'yes' : 'no');
          },
          child: const Text('ask'),
        ),
      ],
    );
  }
}
