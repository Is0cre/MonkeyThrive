import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/features/regulate/screens/breathing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpBox(WidgetTester tester) async {
    final wot = ValueNotifier<ToleranceState?>(ToleranceState.regulated);
    await tester.pumpWidget(
      WoTScope(
        notifier: wot,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const BreathingScreen(mode: BreathingMode.box),
        ),
      ),
    );
  }

  testWidgets('the pacing circle stays within 300px on a wide screen',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpBox(tester);

    final size = tester.getSize(find.byKey(const Key('breath-circle')));
    expect(size.width, 300);
    expect(size.height, 300);
  });

  testWidgets('the pacing circle stays a fraction of a phone width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpBox(tester);

    final size = tester.getSize(find.byKey(const Key('breath-circle')));
    expect(size.width, lessThan(300));
    expect(size.width, greaterThan(120));
    expect(size.height, size.width);
  });
}
