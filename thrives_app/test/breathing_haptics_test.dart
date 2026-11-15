import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/haptics/breath_haptic_pattern.dart';
import 'package:monkeythrive/core/haptics/breath_haptics_controller.dart';
import 'package:monkeythrive/core/models/tolerance_state.dart';
import 'package:monkeythrive/core/state/wot_scope.dart';
import 'package:monkeythrive/core/theme/app_theme.dart';
import 'package:monkeythrive/features/regulate/screens/breathing_screen.dart';
import 'package:monkeythrive/features/regulate/screens/physiological_sigh_screen.dart';
import 'package:monkeythrive/l10n/app_localizations.dart';

void main() {
  testWidgets('box breathing paces the inhale and stops on pause',
      (tester) async {
    final harness = _Harness();
    await _pump(
      tester,
      BreathingScreen(mode: BreathingMode.box, haptics: harness.controller),
    );

    expect(find.byTooltip('Vibration pace on'), findsOneWidget);
    await tester.tap(find.text('Begin'));
    await _settle(tester);

    expect(harness.output.ramps, 1);
    expect(harness.output.wave?.durationMs, 4000);
    expect(harness.output.wave?.intensities.first, 1);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Hold'), findsOneWidget);
    expect(harness.output.ramps, 1);

    await tester.tap(find.text('Pause'));
    await _settle(tester);
    harness.release();
    expect(harness.controller.isHapticsActive, isFalse);
  });

  testWidgets('turning vibration off skips the motor', (tester) async {
    final harness = _Harness();
    await _pump(
      tester,
      BreathingScreen(mode: BreathingMode.box, haptics: harness.controller),
    );

    await tester.tap(find.byKey(const Key('breath-haptics-toggle')));
    await tester.pump();
    expect(find.byTooltip('Vibration pace off'), findsOneWidget);

    await tester.tap(find.text('Begin'));
    await _settle(tester);
    expect(harness.output.ramps, 0);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    harness.release();
  });

  testWidgets('4-7-8 stays quiet when the state is locked', (tester) async {
    final harness = _Harness();
    await _pump(
      tester,
      BreathingScreen(
        mode: BreathingMode.fourSevenEight,
        haptics: harness.controller,
      ),
      state: ToleranceState.hyperaroused,
    );
    await tester.ensureVisible(find.text('Begin'));
    await tester.pump();
    await tester.tap(find.text('Begin'));
    await _settle(tester);
    expect(harness.output.ramps, 0);
    expect(find.text('Pause'), findsNothing);
    expect(
      find.text('4-7-8 breathing is not available when overwhelmed.'),
      findsOneWidget,
    );
    harness.release();
  });

  testWidgets('4-7-8 paces the inhale when the state is regulated',
      (tester) async {
    final harness = _Harness();
    await _pump(
      tester,
      BreathingScreen(
        mode: BreathingMode.fourSevenEight,
        haptics: harness.controller,
      ),
      state: ToleranceState.regulated,
    );
    await tester.ensureVisible(find.text('Begin'));
    await tester.pump();
    await tester.tap(find.text('Begin'));
    await _settle(tester);
    expect(harness.output.wave?.durationMs, 4000);
    await tester.tap(find.text('Pause'));
    await tester.pump();
    harness.release();
  });

  testWidgets('the sigh paces the first inhale and stops when left',
      (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: PhysiologicalSighScreen(haptics: harness.controller),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.vibration), findsOneWidget);
    await tester.tap(find.text('begin'));
    await _settle(tester);
    expect(harness.output.wave?.durationMs, 3000);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    harness.release();
    expect(harness.controller.isHapticsActive, isFalse);
    expect(harness.output.cancels, greaterThanOrEqualTo(1));
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  ToleranceState? state = ToleranceState.hyperaroused,
}) async {
  await tester.pumpWidget(
    WoTScope(
      notifier: ValueNotifier<ToleranceState?>(state),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: home,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
}

class _Harness {
  _Harness() {
    controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );
  }

  final output = _QuietOutput();
  final gates = _Gates();
  late final BreathHapticsController controller;

  void release() => gates.release();
}

class _Gates {
  final List<Completer<void>> _pending = [];

  Future<void> delay(Duration duration) {
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void release() {
    final waiting = List<Completer<void>>.of(_pending);
    _pending.clear();
    for (final completer in waiting) {
      if (!completer.isCompleted) completer.complete();
    }
  }
}

class _QuietOutput implements BreathHapticOutput {
  int ramps = 0;
  int cancels = 0;
  BreathWaveform? wave;

  @override
  Future<bool> hasVibrator() async => true;

  @override
  Future<bool> hasCustomVibrationsSupport() async => true;

  @override
  Future<bool> hasAmplitudeControl() async => true;

  @override
  Future<void> playRamp(BreathWaveform waveform) async {
    ramps++;
    wave = waveform;
  }

  @override
  Future<void> playLegacy(List<int> pattern) async {}

  @override
  Future<void> playPulse(int durationMs) async {}

  @override
  Future<void> cancel() async {
    cancels++;
  }
}
