import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/haptics/breath_haptic_pattern.dart';
import 'package:monkeythrive/core/haptics/breath_haptics_controller.dart';
import 'package:monkeythrive/core/storage/session_tracker.dart';

void main() {
  test('the 12-second cycle ramps in and back out', () {
    final wave = BreathHapticPattern.ramp();

    expect(wave.durationMs, BreathHapticPattern.cycleMs);
    expect(wave.durationMs, 12000);
    expect(wave.timings.length, wave.intensities.length);

    final inhale = <int>[];
    final exhale = <int>[];
    var holds = 0;
    var phase = 0;
    for (var i = 0; i < wave.timings.length; i++) {
      final timing = wave.timings[i];
      final level = wave.intensities[i];
      expect(level, inInclusiveRange(0, 255));
      expect(timing, greaterThan(0));
      if (timing == BreathHapticPattern.topHoldMs && level == 0) {
        holds++;
        phase++;
        continue;
      }
      if (level == 0) continue;
      expect(level, inInclusiveRange(1, 255));
      expect(timing, BreathHapticPattern.pulseOnMs);
      if (phase == 0) {
        inhale.add(level);
      } else if (phase == 1) {
        exhale.add(level);
      } else {
        fail('a pulse sits after the bottom hold');
      }
    }

    expect(holds, 2);
    expect(inhale.first, 1);
    expect(inhale.last, 255);
    expect(exhale.first, 255);
    expect(exhale.last, 1);
    expect(_nonDecreasing(inhale), isTrue);
    expect(_nonIncreasing(exhale), isTrue);

    var moving = 0;
    for (final timing in wave.timings) {
      moving += timing;
    }
    expect(moving, 5500 + 500 + 5500 + 500);
  });

  test('the legacy pattern keeps the same 12 seconds without amplitudes', () {
    final pattern = BreathHapticPattern.legacy();
    var total = 0;
    for (final timing in pattern) {
      total += timing;
    }
    expect(pattern.first, 0);
    expect(total, 12000);
  });

  test('amplitude control loops the ramp until stop', () async {
    final output = _FakeOutput(custom: true, amplitude: true);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );

    await controller.startBreathingHaptics();
    await _flush();
    expect(output.ramps, 1);
    expect(output.wave?.durationMs, 12000);
    expect(output.wave?.intensities.first, 1);

    gates.release();
    await _flush();
    expect(output.ramps, 2);

    controller.stopBreathingHaptics();
    gates.release();
    await _flush();
    expect(output.ramps, 2);
    expect(output.cancels, 1);
    expect(controller.isHapticsActive, isFalse);
  });

  test('a second start does not stack another loop', () async {
    final output = _FakeOutput(custom: true, amplitude: true);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );

    await controller.startBreathingHaptics();
    await controller.startBreathingHaptics();
    await _flush();
    expect(output.ramps, 1);
    controller.stopBreathingHaptics();
    gates.release();
    await _flush();
  });

  test('iOS-style custom haptics still use the amplitude ramp', () async {
    final output = _FakeOutput(custom: true, amplitude: false);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: true,
    );

    await controller.startBreathingHaptics();
    await _flush();
    expect(output.ramps, 1);
    expect(output.legacy, isEmpty);
    controller.stopBreathingHaptics();
    gates.release();
    await _flush();
  });

  test('no amplitude control uses the on-off pattern', () async {
    final output = _FakeOutput(custom: true, amplitude: false);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );

    await controller.startBreathingHaptics();
    await _flush();
    expect(output.ramps, 0);
    expect(output.legacy.length, 1);
    var total = 0;
    for (final timing in output.legacy.single) {
      total += timing;
    }
    expect(total, 12000);
    controller.stopBreathingHaptics();
    gates.release();
    await _flush();
  });

  test('without a custom pattern the inhale and exhale each get one pulse',
      () async {
    final output = _FakeOutput(custom: false, amplitude: false);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );

    await controller.startBreathingHaptics();
    await _flush();
    expect(output.pulses, [BreathHapticPattern.simplePulseMs]);
    expect(gates.waits, [BreathHapticPattern.simpleHalfMs]);

    gates.release();
    await _flush();
    expect(output.pulses, [
      BreathHapticPattern.simplePulseMs,
      BreathHapticPattern.simplePulseMs,
    ]);
    expect(gates.waits, [
      BreathHapticPattern.simpleHalfMs,
      BreathHapticPattern.simpleHalfMs,
    ]);
    controller.stopBreathingHaptics();
    gates.release();
    await _flush();
    expect(output.pulses.length, 2);
  });

  test('a phase matches the exercise length and a hold stays quiet', () async {
    final rise = BreathHapticPattern.phase(4000, rising: true);
    final fall = BreathHapticPattern.phase(8000, rising: false);
    expect(rise.durationMs, 4000);
    expect(fall.durationMs, 8000);
    expect(rise.intensities.where((level) => level > 0).first, 1);
    expect(rise.intensities.where((level) => level > 0).last, 255);
    expect(fall.intensities.where((level) => level > 0).first, 255);
    expect(fall.intensities.where((level) => level > 0).last, 1);

    final output = _FakeOutput(custom: true, amplitude: true);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );

    final playing = controller.playPhase(
      durationMs: 4000,
      motion: BreathHapticMotion.rise,
    );
    await _flush();
    expect(output.ramps, 1);
    expect(output.wave?.durationMs, 4000);
    expect(controller.isHapticsActive, isTrue);

    controller.stopBreathingHaptics();
    gates.release();
    await playing;
    expect(controller.isHapticsActive, isFalse);
    expect(output.cancels, greaterThanOrEqualTo(1));
    expect(output.ramps, 1);

    await controller.playPhase(
      durationMs: 4000,
      motion: BreathHapticMotion.still,
    );
    await _flush();
    expect(output.ramps, 1);
    expect(controller.isHapticsActive, isFalse);
  });

  test('a phone with no vibrator never starts the loop', () async {
    final output = _FakeOutput(
      custom: true,
      amplitude: true,
      vibrator: false,
    );
    final controller = BreathHapticsController(
      output: output,
      delay: (_) async {},
      rampWithoutAmplitudeControl: false,
    );

    await controller.startBreathingHaptics();
    await _flush();
    expect(controller.isHapticsActive, isFalse);
    expect(output.ramps, 0);
  });

  test('the emergency bailout stops a running breath loop', () async {
    final output = _FakeOutput(custom: true, amplitude: true);
    final gates = _Gates();
    final controller = BreathHapticsController(
      output: output,
      delay: gates.delay,
      rampWithoutAmplitudeControl: false,
    );

    await controller.startBreathingHaptics();
    await _flush();
    expect(output.ramps, 1);

    SessionActivity.triggerEmergencyBailout();
    gates.release();
    await _flush();

    expect(controller.isHapticsActive, isFalse);
    expect(output.cancels, greaterThanOrEqualTo(1));
    expect(output.ramps, 1);
  });
}

bool _nonDecreasing(List<int> values) {
  for (var i = 1; i < values.length; i++) {
    if (values[i] < values[i - 1]) return false;
  }
  return values.isNotEmpty;
}

bool _nonIncreasing(List<int> values) {
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[i - 1]) return false;
  }
  return values.isNotEmpty;
}

Future<void> _flush() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Gates {
  final List<Completer<void>> _pending = [];
  final List<int> waits = [];

  Future<void> delay(Duration duration) {
    waits.add(duration.inMilliseconds);
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

class _FakeOutput implements BreathHapticOutput {
  _FakeOutput({
    required this.custom,
    required this.amplitude,
    this.vibrator = true,
  });

  final bool custom;
  final bool amplitude;
  final bool vibrator;

  int ramps = 0;
  int cancels = 0;
  BreathWaveform? wave;
  final List<List<int>> legacy = [];
  final List<int> pulses = [];

  @override
  Future<bool> hasVibrator() async => vibrator;

  @override
  Future<bool> hasCustomVibrationsSupport() async => custom;

  @override
  Future<bool> hasAmplitudeControl() async => amplitude;

  @override
  Future<void> playRamp(BreathWaveform waveform) async {
    ramps++;
    wave = waveform;
  }

  @override
  Future<void> playLegacy(List<int> pattern) async {
    legacy.add(pattern);
  }

  @override
  Future<void> playPulse(int durationMs) async {
    pulses.add(durationMs);
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }
}
