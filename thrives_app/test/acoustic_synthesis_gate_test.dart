import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/audio/acoustic_synthesis_gate.dart';
import 'package:monkeythrive/core/audio/local_audio_cache.dart';
import 'package:monkeythrive/core/audio/tone_generator.dart';
import 'package:monkeythrive/core/audio/wav_source.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/storage/prefs_service.dart';
import 'package:monkeythrive/features/attune/attune_mask_playlist.dart';
import 'package:monkeythrive/features/attune/screens/attune_home_screen.dart';
import 'package:monkeythrive/features/attune/widgets/attune_listening.dart';
import 'package:monkeythrive/features/process/screens/emdr_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('zen collapse folds setup controls away', (tester) async {
    var show = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ZenCollapse(
                  show: show,
                  child: const Text('Carrier frequency'),
                ),
                const Text('Stop'),
                TextButton(
                  onPressed: () => setState(() => show = false),
                  child: const Text('begin'),
                ),
              ],
            );
          },
        ),
      ),
    ));

    expect(tester.getSize(find.byType(ZenCollapse)).height, greaterThan(0));
    await tester.tap(find.text('begin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.getSize(find.byType(ZenCollapse)).height, 0);
    expect(find.text('Stop'), findsOneWidget);
  });

  test('the mask playlist is the four seasons in order', () {
    expect(attuneMaskAssets, [
      'assets/audio/01_vivaldi_spring.ogg',
      'assets/audio/02_vivaldi_summer.ogg',
      'assets/audio/03_vivaldi_autumn.ogg',
      'assets/audio/04_vivaldi_winter.ogg',
    ]);
    final source = attuneMaskSource();
    expect(source.children, hasLength(4));
    expect(source.useLazyPreparation, isTrue);
    expect(attuneMaskDurationMinutes(0), 10);
    expect(attuneMaskDurationMinutes(1), 10);
    expect(attuneMaskDurationMinutes(2), 12);
    expect(attuneMaskDurationMinutes(3), 9);
    expect(attuneMaskCarrierHz(0), 164.8);
    expect(attuneMaskCarrierHz(1), 196.0);
    expect(attuneMaskCarrierHz(2), 174.6);
    expect(attuneMaskCarrierHz(3), 174.6);
    expect(attuneMaskCarrierHz(9), 164.8);
    for (var i = 0; i < attuneMaskDurationSeconds.length; i++) {
      expect(
        attuneMaskDurationMinutes(i) * 60,
        lessThanOrEqualTo(attuneMaskDurationSeconds[i]),
      );
    }
  });

  test('playback cache does not synthesize while acoustic tools are gated',
      () async {
    expect(AcousticSynthesisGate.enabled, isFalse);
    expect(AcousticSynthesisGate.tonesEnabled, isTrue);
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

  test('an Attune tone builds a one-second looping wav off the UI isolate',
      () async {
    final bytes = await compute(synthesizeBinauralWav, <double>[200, 10]);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(bytes.length, 44 + 44100 * 4);
    final data = ByteData.sublistView(bytes);
    expect(data.getInt16(44, Endian.little), 0);
    var heard = false;
    for (var i = 44; i < bytes.length - 1; i += 4) {
      if (data.getInt16(i, Endian.little) != 0) {
        heard = true;
        break;
      }
    }
    expect(heard, isTrue);
  });

  test('a tenth-hertz root loops until every cycle closes', () {
    expect(toneLoopSamples(44100, [200, 210]), 44100);
    expect(toneLoopSamples(44100, [196, 206]), 44100);
    expect(toneLoopSamples(44100, [164.8, 174.8]), 44100 * 5);
    expect(toneLoopSamples(44100, [174.6, 184.6]), 44100 * 5);
    final bytes = BinauralBeatSource(carrierHz: 164.8, beatHz: 10).bytes;
    expect(bytes.length, 44 + 44100 * 5 * 4);
  });

  test('a player request does not allocate a synthesis buffer', () async {
    final source = _CountingSource();
    await expectLater(
      source.request(),
      throwsA(isA<StateError>()),
    );
    expect(source.builds, 0);
  });

  testWidgets('Attune frequencies can be chosen and nature stays closed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AttuneHomeScreen())));
    await tester.pump();
    expect(find.text('Play'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Two tones, one in each ear'), findsOneWidget);
    expect(
        find.textContaining('Stereo headphones are required'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.text('I understand'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Hemispheric sound is strong'), findsOneWidget);
    expect(
      find.textContaining('hemispheric synchronization'),
      findsOneWidget,
    );
    expect(find.textContaining('history of seizures'), findsOneWidget);
    expect(find.textContaining('while driving'), findsOneWidget);
    expect(
      find.text(
        'This is not treatment, and it is not EMDR. The Anchor stays available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Play'), findsNothing);
    expect(find.byKey(const Key('attune-onboarding-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('attune-onboarding-dot-3')), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Frequency following response'), findsOneWidget);
    expect(find.text('Hemispheric sound is strong'), findsNothing);
    expect(find.text('Play'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefsService.attuneIntroKey), isNot(true));
    expect(prefs.getBool(PrefsService.attuneWaiverKey), isNot(true));
    expect(prefs.getBool(PrefsService.attuneUnlockedKey), isNot(true));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsNothing);
    expect(find.text('I Understand and Accept'), findsOneWidget);

    expect(
      find.text('I do not have a history of epilepsy or seizure disorders.'),
      findsOneWidget,
    );
    expect(
      find.text('I will not operate heavy machinery or drive while listening.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'I assume all risks associated with brainwave entrainment, releasing the creators from liability regarding adverse psychiatric reactions.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('attune-waiver-enter')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text(
      'I do not have a history of epilepsy or seizure disorders.',
    ));
    await tester.pump();
    await tester.tap(find.text(
      'I will not operate heavy machinery or drive while listening.',
    ));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('attune-waiver-enter')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text(
      'I assume all risks associated with brainwave entrainment, releasing the creators from liability regarding adverse psychiatric reactions.',
    ));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('attune-waiver-enter')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('attune-waiver-enter')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(PrefsService.attuneIntroKey), isTrue);
    expect(prefs.getBool(PrefsService.attuneWaiverKey), isTrue);
    expect(prefs.getBool(PrefsService.attuneUnlockedKey), isTrue);

    expect(find.text('Attune'), findsOneWidget);
    expect(find.text('About these frequencies'), findsOneWidget);
    expect(find.text('Binaural'), findsOneWidget);
    expect(find.text('Isochronic'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.text(AcousticSynthesisGate.message), findsNothing);

    await tester.ensureVisible(find.text('Nature soundscapes'));
    await tester.pump();
    await tester.tap(find.text('Nature soundscapes'));
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text(AcousticSynthesisGate.message), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(AcousticSynthesisGate.message), findsNothing);

    await tester.tap(find.text('Binaural'));
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('CARRIER FREQUENCY'), findsOneWidget);
    expect(
      find.text('Binaural beats require stereo headphones to work.'),
      findsOneWidget,
    );
    final slider = tester.widget<Slider>(
      find.byKey(const Key('attune-carrier-slider')),
    );
    expect(slider.min, 100);
    expect(slider.max, 400);
    expect(slider.divisions, isNull);
    expect(slider.value, 164.8);
    expect(find.text('164.8 Hz'), findsOneWidget);
    slider.onChanged!(210);
    await tester.pump();
    expect(
      tester
          .widget<Slider>(find.byKey(const Key('attune-carrier-slider')))
          .value,
      210,
    );
    final session = tester.widget<Slider>(
      find.byKey(const Key('attune-session-slider')),
    );
    expect(session.min, 10);
    expect(session.max, 10);
    expect(session.value, 10);
    expect(find.text('10m'), findsWidgets);
    expect(find.text('90m'), findsNothing);
    expect(find.text('50m'), findsNothing);
    final toneBox =
        tester.getRect(find.byKey(const Key('attune-engine-slider')));
    final maskBox = tester.getRect(find.byKey(const Key('attune-mask-slider')));
    expect(toneBox.left, maskBox.left);
    expect(toneBox.right, maskBox.right);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('attune-tone-toggle')))
          .onPressed,
      isNull,
    );
    expect(find.byIcon(Icons.pause), findsOneWidget);
    final tone = tester.widget<Slider>(
      find.byKey(const Key('attune-engine-slider')),
    );
    expect(tone.min, 0);
    expect(tone.max, 1);
    expect(tone.value, 0.25);
    expect(tone.onChanged, isNotNull);
    final mask = tester.widget<Slider>(
      find.byKey(const Key('attune-mask-slider')),
    );
    expect(mask.onChanged, isNotNull);
    expect(mask.value, 0.75);
    expect(
      find.text(
        'Using your own music? Choose ambient tracks or classical music around 60 BPM. Fast or aggressive music will clash with the entrainment frequencies and may cause anxiety.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('Vivaldi, Spring'), findsOneWidget);
    expect(find.textContaining('Modena Chamber Orchestra'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('attune-mask-next')));
    await tester.tap(find.byKey(const Key('attune-mask-next')));
    await tester.pump();
    expect(find.text('Vivaldi, Summer'), findsOneWidget);
    expect(_carrierValue(tester), 196.0);
    expect(find.text('196.0 Hz', skipOffstage: false), findsOneWidget);
    await tester.tap(find.byKey(const Key('attune-mask-next')));
    await tester.pump();
    expect(find.text('Vivaldi, Autumn'), findsOneWidget);
    expect(_carrierValue(tester), 174.6);
    expect(
      tester.widget<Slider>(find.byKey(const Key('attune-session-slider'))).max,
      12,
    );
    expect(find.text('12m'), findsWidgets);
    expect(find.text('10m'), findsWidgets);
    await tester.tap(find.byKey(const Key('attune-mask-next')));
    await tester.pump();
    expect(find.text('Vivaldi, Winter'), findsOneWidget);
    expect(_carrierValue(tester), 174.6);
    expect(
      tester.widget<Slider>(find.byKey(const Key('attune-session-slider'))).max,
      9,
    );
    expect(
      tester.widget<Slider>(find.byKey(const Key('attune-session-slider'))).min,
      9,
    );
    expect(find.text('9m'), findsWidgets);
    await tester.tap(find.byKey(const Key('attune-mask-next')));
    await tester.pump();
    expect(find.text('Vivaldi, Spring'), findsOneWidget);
    expect(_carrierValue(tester), 164.8);
    expect(
      find.text(
        'A local recording can be added later. This slider stays quiet until then.',
      ),
      findsNothing,
    );
    expect(find.text(AcousticSynthesisGate.message), findsNothing);
  });

  testWidgets('the unlock flag alone does not open Attune', (tester) async {
    SharedPreferences.setMockInitialValues({
      PrefsService.attuneUnlockedKey: true,
    });
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AttuneHomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Two tones, one in each ear'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.text('Attune'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefsService.attuneIntroKey), isNot(true));
    expect(prefs.getBool(PrefsService.attuneWaiverKey), isNot(true));
  });

  testWidgets('a finished frequency introduction can be read again',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      PrefsService.attuneIntroKey: true,
      PrefsService.attuneWaiverKey: true,
    });
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AttuneHomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Two tones, one in each ear'), findsNothing);
    expect(find.text('Attune'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefsService.attuneUnlockedKey), isTrue);

    await tester.tap(find.text('About these frequencies'));
    await tester.pumpAndSettle();

    expect(find.text('Two tones, one in each ear'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Attune'), findsOneWidget);
    expect(find.text('Two tones, one in each ear'), findsNothing);
    expect(find.text('Play'), findsNothing);
  });

  testWidgets('bilateral audio modes stay closed and do not start playback',
      (tester) async {
    await tester.pumpWidget(
      WoTScope(
        notifier: ValueNotifier<ToleranceState?>(ToleranceState.regulated),
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EmdrScreen()),
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
    // ensureVisible jumps during scrollUntilVisible. Lay that jump out before
    // the tap, so the label is above the docked anchor.
    await tester.pump();
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

double _carrierValue(WidgetTester tester) {
  return tester
      .widget<Slider>(
        find.byKey(const Key('attune-carrier-slider'), skipOffstage: false),
      )
      .value;
}

class _CountingSource extends CachedWavSource {
  int builds = 0;

  @override
  Uint8List buildWav() {
    builds++;
    return Uint8List(44);
  }
}
