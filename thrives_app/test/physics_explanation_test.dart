import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/features/attune/screens/physics_explanation_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';

void main() {
  testWidgets('the physics screen names the limits and forbids driving',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PhysicsExplanationScreen(),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('The hearing barrier'), findsOneWidget);
    expect(find.text('Carrier and beat'), findsOneWidget);
    expect(find.text('Frequency following response'), findsOneWidget);
    expect(find.text('Lamp and laser'), findsOneWidget);
    expect(find.text('WARNING'), findsOneWidget);
    expect(
      find.textContaining('Do not drive or operate machinery'),
      findsOneWidget,
    );
    expect(find.textContaining('does not put you to sleep'), findsOneWidget);
    expect(
      find.textContaining('manually override the nervous system'),
      findsNothing,
    );
    expect(find.byIcon(Icons.hearing_rounded), findsOneWidget);
    expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    expect(find.byIcon(Icons.flare_rounded), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.text('WARNING'), findsNothing);
  });
}
