import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/audio/acoustic_synthesis_gate.dart';
import 'package:monkeythrive/core/audio/local_audio_cache.dart';
import 'package:monkeythrive/core/audio/wav_source.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/features/attune/screens/attune_home_screen.dart';
import 'package:monkeythrive/features/process/screens/emdr_screen.dart';

void main() {
  test('playback cache does not synthesize while acoustic tools are gated',
      () async {
    expect(AcousticSynthesisGate.enabled, isFalse);
    var built = false;
    await expectLater(
      LocalAudioCache.audioSource('gated', () {
        built = true;
        return Uint8List(0);
      }),
      throwsA(isA<StateError>().having(
        (error) => error.message,
        'message',
        AcousticSynthesisGate.message,
      )),
    );
    expect(built, isFalse);
  });

  test('a player request does not allocate a synthesis buffer', () async {
    final source = _CountingSource();
    await expectLater(
      source.request(),
      throwsA(isA<StateError>()),
    );
    expect(source.builds, 0);
  });

  testWidgets('Attune shows the calibration notice instead of a player',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AttuneHomeScreen()));
    await tester.pump();

    expect(find.text(AcousticSynthesisGate.message), findsOneWidget);
    expect(find.text('Binaural beats'), findsOneWidget);
    expect(find.text('Isochronic tones'), findsOneWidget);
    expect(find.text('Nature soundscapes'), findsOneWidget);
    expect(find.text('Play'), findsNothing);

    await tester.tap(find.text('Binaural beats'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text(AcousticSynthesisGate.message), findsNWidgets(2));

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text(AcousticSynthesisGate.message), findsOneWidget);
  });

  testWidgets('bilateral audio modes stay closed and do not start playback',
      (tester) async {
    await tester.pumpWidget(
      WoTScope(
        notifier: ValueNotifier<ToleranceState?>(ToleranceState.regulated),
        child: const MaterialApp(home: EmdrScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Visual only'), findsOneWidget);
    expect(find.text('Audio only'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('Audio only'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text(AcousticSynthesisGate.message), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visual + Audio'));
    await tester.pumpAndSettle();
    expect(find.text(AcousticSynthesisGate.message), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('All three'),
      80,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('All three'));
    await tester.pumpAndSettle();
    expect(find.text(AcousticSynthesisGate.message), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tactile only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tactile only'));
    await tester.pumpAndSettle();
    expect(find.text(AcousticSynthesisGate.message), findsNothing);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Tactile only'),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
  });
}

class _CountingSource extends CachedWavSource {
  int builds = 0;

  @override
  Uint8List buildWav() {
    builds++;
    return Uint8List(44);
  }
}
