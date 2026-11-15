import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/theme/app_appearance.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/features/attune/expansions/attune_track.dart';
import 'package:monkeythrive/features/attune/widgets/attune_pack_sheet.dart';
import 'package:monkeythrive/features/checkin/screens/checkin_screen.dart';
import 'package:monkeythrive/features/process/screens/process_home_screen.dart';
import 'package:monkeythrive/features/regulate/screens/grounding_521_screen.dart';
import 'package:monkeythrive/features/regulate/screens/vagal_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';
import 'package:monkeythrive/main.dart';

void main() {
  final controller = AppAppearanceController.instance;

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await controller.setAccent(AppAccent.teal);
    await controller.setContrast(AppContrast.standard);
  });

  test('appearance settings persist accent and contrast', () async {
    SharedPreferences.setMockInitialValues({});

    await controller.load();
    await controller.setAccent(AppAccent.blue);
    await controller.setContrast(AppContrast.high);
    await controller.load();

    expect(controller.notifier.value.accent, AppAccent.blue);
    expect(controller.notifier.value.contrast, AppContrast.high);
  });

  testWidgets('the scheme chosen in settings paints every tool',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await controller.setAccent(AppAccent.blue);
    await controller.setContrast(AppContrast.high);

    const blue = Color(0xFF66A6FF);
    const green = Color(0xFF6FCF97);

    await tester.pumpWidget(const ThrivesApp(
      onboardingDone: true,
      initialWot: ToleranceState.regulated,
    ));
    await tester.pump();

    expect(_iconsColored(blue), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.bySemanticsLabel('green'));
    await tester.tap(find.bySemanticsLabel('green'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.notifier.value.accent, AppAccent.green);

    expect(tester.widget<Text>(find.text('MONKEYTHRIVE')).style?.color, green);
    expect(find.byType(Scaffold).last, findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_iconsColored(green), findsWidgets);

    await _pumpTool(
      tester,
      const CheckInScreen(onComplete: _ignoreReading),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF000000),
    );

    await _pumpTool(
      tester,
      WoTScope(
        notifier: ValueNotifier(ToleranceState.regulated),
        child: const ProcessHomeScreen(),
      ),
    );
    expect(_iconsColored(green), findsWidgets);

    await _pumpTool(tester, const Grounding521Screen());
    expect(_iconsColored(green), findsWidgets);

    await _pumpTool(tester, const VagalScreen());
    expect(_iconsColored(green), findsWidgets);

    await _pumpTool(
      tester,
      Scaffold(
        body: AttunePackSheet(
          tracks: bundledAttuneTracks(),
          selectedIndex: 0,
          onSelect: (_) {},
          onAdd: () {},
        ),
      ),
    );
    expect(_iconsColored(green), findsWidgets);
  });
}

Finder _iconsColored(Color color) {
  return find
      .byWidgetPredicate((widget) => widget is Icon && widget.color == color);
}

Future<void> _pumpTool(WidgetTester tester, Widget home) {
  final look = AppAppearanceController.instance.notifier.value;
  return tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.dark(look),
    home: home,
  ));
}

void _ignoreReading(ToleranceState state) {}
