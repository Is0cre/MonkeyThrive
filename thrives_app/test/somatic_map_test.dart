import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/features/checkin/screens/checkin_screen.dart';
import 'package:monkeythrive/features/checkin/somatic_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('tight chest reads as overwhelmed', () {
    expect(
      stateFromBodyMap({SomaticZone.chest: SomaticQuality.tight}),
      ToleranceState.hyperaroused,
    );
  });

  test('heavy stomach reads as flat', () {
    expect(
      stateFromBodyMap({SomaticZone.stomach: SomaticQuality.heavy}),
      ToleranceState.hypoaroused,
    );
  });

  test('an unmarked body does not read as present', () {
    expect(stateFromBodyMap(const {}), isNull);
  });

  test('more heaviness than tightness reads as flat', () {
    expect(
      stateFromBodyMap({
        SomaticZone.chest: SomaticQuality.tight,
        SomaticZone.stomach: SomaticQuality.heavy,
        SomaticZone.head: SomaticQuality.heavy,
      }),
      ToleranceState.hypoaroused,
    );
  });

  test('a tie between tight and heavy stays with charge', () {
    expect(
      stateFromBodyMap({
        SomaticZone.throat: SomaticQuality.tight,
        SomaticZone.stomach: SomaticQuality.heavy,
      }),
      ToleranceState.hyperaroused,
    );
  });

  testWidgets('tapping the chest shows the overwhelmed reading', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: CheckInScreen(onComplete: (_) {}),
      ),
    );

    expect(find.text('this reads as overwhelmed'), findsNothing);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Chest, unmarked'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.bySemanticsLabel('Chest, unmarked'));
    await tester.pump();
    expect(find.text('this reads as overwhelmed'), findsOneWidget);

    await tester.tap(find.text('nothing stands out'));
    await tester.pump();
    expect(find.text('this reads as present'), findsOneWidget);
  });
}
