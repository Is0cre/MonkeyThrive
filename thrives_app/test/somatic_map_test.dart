import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/features/checkin/screens/checkin_screen.dart';
import 'package:monkeythrive/features/checkin/somatic_body_map.dart';
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

  testWidgets('silhouette choice keeps the zone labels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: CheckInScreen(onComplete: (_) {}),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Feminine'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Masculine'));
    await tester.pump();
    await tester.tap(find.text('Feminine'));
    await tester.pump();

    expect(find.bySemanticsLabel('Chest, unmarked'), findsOneWidget);
    expect(find.bySemanticsLabel('Head, unmarked'), findsOneWidget);
    expect(find.bySemanticsLabel('Stomach, unmarked'), findsOneWidget);
  });

  testWidgets('head glow stays inside the silhouette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 200,
              child: RepaintBoundary(
                key: Key('shot'),
                child: SomaticBodyMap(
                  marks: {SomaticZone.head: SomaticQuality.tight},
                  onTap: _ignoreZone,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (final label in ['Neutral', 'Masculine', 'Feminine']) {
      if (label != 'Neutral') {
        await tester.tap(find.text(label));
        await tester.pump();
      }
      final sample = await _sampleHead(tester);
      expect(sample.insideRed, greaterThan(80), reason: '$label head glow');
      expect(sample.outsideAlpha, 0, reason: '$label glow leaked');
    }
  });
}

void _ignoreZone(SomaticZone zone) {}

class _HeadSample {
  final int insideRed;
  final int outsideAlpha;

  const _HeadSample(this.insideRed, this.outsideAlpha);
}

/// Head center is viewBox (100, 52). (62, 52) is outside the skull and inside
/// the unclipped radial gradient, so a leaked glow would color it.
Future<_HeadSample> _sampleHead(WidgetTester tester) async {
  const inside = Offset(100, 52);
  const outside = Offset(62, 52);
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final sample = await _readHead(tester, inside, outside);
    if (sample.insideRed > 80) return sample;
  }
  return _readHead(tester, inside, outside);
}

Future<_HeadSample> _readHead(
  WidgetTester tester,
  Offset inside,
  Offset outside,
) async {
  final shot = find.byKey(const Key('shot'));
  final paint = find.descendant(of: shot, matching: find.byType(CustomPaint));
  final delta = tester.getTopLeft(paint) - tester.getTopLeft(shot);
  final boundary = tester.renderObject<RenderRepaintBoundary>(shot);
  final image = await tester.runAsync(() => boundary.toImage());
  if (image == null) return const _HeadSample(0, 0);
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) return const _HeadSample(0, 0);
    int channel(Offset local, int channel) {
      final x = (delta.dx + local.dx).round();
      final y = (delta.dy + local.dy).round();
      final index = (y * image.width + x) * 4 + channel;
      return bytes.getUint8(index);
    }

    return _HeadSample(channel(inside, 0), channel(outside, 3));
  } finally {
    image.dispose();
  }
}
