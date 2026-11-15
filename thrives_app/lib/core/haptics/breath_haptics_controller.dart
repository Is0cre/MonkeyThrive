import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import 'breath_haptic_pattern.dart';

/// How the motor moves during one phase of the exercise on screen.
enum BreathHapticMotion { rise, fall, still }

/// Plays one 12-second breath on the phone's vibrator, then repeats.
///
/// The phone keeps the pace. It does not sense the belly or the breath.
/// [stopBreathingHaptics] cuts the motor immediately. The emergency anchor
/// calls [stopAll] as well, so a running loop cannot restart under the sigh.
class BreathHapticsController {
  BreathHapticsController({
    BreathHapticOutput? output,
    Future<void> Function(Duration duration)? delay,
    bool? rampWithoutAmplitudeControl,
  })  : _output = output ?? const VibrationBreathOutput(),
        _delay = delay ?? Future<void>.delayed,
        _rampWithoutAmplitudeControl = rampWithoutAmplitudeControl;

  static final Set<BreathHapticsController> _live = <BreathHapticsController>{};

  final BreathHapticOutput _output;
  final Future<void> Function(Duration duration) _delay;
  final bool? _rampWithoutAmplitudeControl;

  bool _isHapticsActive = false;
  int _ticket = 0;

  bool get isHapticsActive => _isHapticsActive;

  /// Stops every running breath loop. Used by the emergency bailout.
  static void stopAll() {
    for (final controller in _live.toList()) {
      controller.stopBreathingHaptics();
    }
  }

  /// Loops the 12-second cycle while [_isHapticsActive] stays true.
  ///
  /// A second call while a loop is running does nothing. Devices that cannot
  /// vibrate return without starting. Amplitude control gets the rising and
  /// falling pulses. A custom motor without amplitude gets the same rhythm
  /// as on/off timings. Anything else gets one short pulse at the inhale and
  /// one at the exhale.
  Future<void> startBreathingHaptics() async {
    if (_isHapticsActive) return;
    _isHapticsActive = true;
    final ticket = ++_ticket;
    _live.add(this);

    final available = await _output.hasVibrator();
    if (!_running(ticket)) {
      _live.remove(this);
      return;
    }
    if (!available) {
      _isHapticsActive = false;
      _ticket++;
      _live.remove(this);
      return;
    }
    unawaited(_loop(ticket));
  }

  /// Plays one phase of the exercise on screen, then stops.
  ///
  /// [BreathHapticMotion.rise] is an inhale. [BreathHapticMotion.fall] is an
  /// exhale. [BreathHapticMotion.still] leaves the motor quiet for a hold.
  /// A new phase replaces the previous one. This does not start the
  /// 12-second belly cycle.
  Future<void> playPhase({
    required int durationMs,
    required BreathHapticMotion motion,
  }) async {
    stopBreathingHaptics();
    if (motion == BreathHapticMotion.still || durationMs <= 0) return;

    _isHapticsActive = true;
    final ticket = ++_ticket;
    _live.add(this);

    final available = await _output.hasVibrator();
    if (!_running(ticket)) return;
    if (!available) {
      _finish(ticket);
      return;
    }

    final custom = await _output.hasCustomVibrationsSupport();
    if (!_running(ticket)) return;
    final amplitude = custom ? await _output.hasAmplitudeControl() : false;
    if (!_running(ticket)) return;
    await _output.cancel();
    if (!_running(ticket)) return;

    final rising = motion == BreathHapticMotion.rise;
    final wave = BreathHapticPattern.phase(durationMs, rising: rising);
    if (_usesRamp(custom: custom, amplitude: amplitude)) {
      await _output.playRamp(wave);
    } else if (custom) {
      await _output.playLegacy(BreathHapticPattern.asLegacy(wave));
    } else {
      await _output.playPulse(BreathHapticPattern.simplePulseMs);
    }
    if (!_running(ticket)) return;
    if (!await _pause(ticket, Duration(milliseconds: durationMs))) return;
    _finish(ticket);
  }

  /// Cancels the loop and the motor.
  void stopBreathingHaptics() {
    _isHapticsActive = false;
    _ticket++;
    _live.remove(this);
    unawaited(_output.cancel());
  }

  Future<void> _loop(int ticket) async {
    final custom = await _output.hasCustomVibrationsSupport();
    if (!_running(ticket)) return;
    final amplitude = custom ? await _output.hasAmplitudeControl() : false;
    if (!_running(ticket)) return;

    final waveform = BreathHapticPattern.ramp();
    final legacy = BreathHapticPattern.legacy();
    final ramp = _usesRamp(custom: custom, amplitude: amplitude);

    while (_running(ticket)) {
      if (ramp) {
        await _output.playRamp(waveform);
      } else if (custom) {
        await _output.playLegacy(legacy);
      } else {
        await _output.playPulse(BreathHapticPattern.simplePulseMs);
        if (!await _pause(
          ticket,
          const Duration(milliseconds: BreathHapticPattern.simpleHalfMs),
        )) {
          break;
        }
        await _output.playPulse(BreathHapticPattern.simplePulseMs);
      }
      if (!await _pause(ticket, _tail(ramp: ramp, custom: custom))) break;
    }
  }

  bool _usesRamp({required bool custom, required bool amplitude}) {
    if (!custom) return false;
    if (amplitude) return true;
    final override = _rampWithoutAmplitudeControl;
    if (override != null) return override;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  Duration _tail({required bool ramp, required bool custom}) {
    if (ramp || custom) {
      return const Duration(milliseconds: BreathHapticPattern.cycleMs);
    }
    return const Duration(milliseconds: BreathHapticPattern.simpleHalfMs);
  }

  Future<bool> _pause(int ticket, Duration duration) async {
    if (!_running(ticket)) return false;
    await _delay(duration);
    return _running(ticket);
  }

  bool _running(int ticket) => _isHapticsActive && ticket == _ticket;

  void _finish(int ticket) {
    if (ticket != _ticket) return;
    _isHapticsActive = false;
    _ticket++;
    _live.remove(this);
  }
}

/// The piece of the vibrator the breath loop is allowed to touch.
abstract class BreathHapticOutput {
  Future<bool> hasVibrator();
  Future<bool> hasCustomVibrationsSupport();
  Future<bool> hasAmplitudeControl();
  Future<void> playRamp(BreathWaveform waveform);
  Future<void> playLegacy(List<int> pattern);
  Future<void> playPulse(int durationMs);
  Future<void> cancel();
}

class VibrationBreathOutput implements BreathHapticOutput {
  const VibrationBreathOutput();

  Future<bool> _flag(Future<bool> future) async {
    try {
      return await future;
    } catch (_) {
      return false;
    }
  }

  Future<void> _play(Future<void> future) async {
    try {
      await future;
    } catch (_) {}
  }

  @override
  Future<bool> hasVibrator() => _flag(Vibration.hasVibrator());

  @override
  Future<bool> hasCustomVibrationsSupport() {
    return _flag(Vibration.hasCustomVibrationsSupport());
  }

  @override
  Future<bool> hasAmplitudeControl() => _flag(Vibration.hasAmplitudeControl());

  @override
  Future<void> playRamp(BreathWaveform waveform) {
    return _play(Vibration.vibrate(
      pattern: waveform.timings,
      intensities: waveform.intensities,
      repeat: -1,
    ));
  }

  @override
  Future<void> playLegacy(List<int> pattern) {
    return _play(Vibration.vibrate(pattern: pattern, repeat: -1));
  }

  @override
  Future<void> playPulse(int durationMs) {
    return _play(Vibration.vibrate(duration: durationMs));
  }

  @override
  Future<void> cancel() => _play(Vibration.cancel());
}
