/// One 12-second diaphragmatic cycle, as motor timings.
///
/// Five breaths a minute: 5.5s in, 0.5s at the top, 5.5s out, 0.5s at the
/// bottom. A long continuous buzz is cut off by the OS, so each moving phase
/// is short pulses instead.
class BreathWaveform {
  final List<int> timings;
  final List<int> intensities;

  const BreathWaveform(this.timings, this.intensities);

  int get durationMs {
    var total = 0;
    for (final timing in timings) {
      total += timing;
    }
    return total;
  }
}

class BreathHapticPattern {
  BreathHapticPattern._();

  static const inhaleMs = 5500;
  static const topHoldMs = 500;
  static const exhaleMs = 5500;
  static const bottomHoldMs = 500;
  static const cycleMs = inhaleMs + topHoldMs + exhaleMs + bottomHoldMs;

  static const pulseOnMs = 50;
  static const pulseOffMs = 150;

  /// One-shot length used when the device cannot play a custom pattern.
  static const simplePulseMs = 80;

  /// Inhale plus the top hold, and exhale plus the bottom hold.
  static const simpleHalfMs = 6000;

  /// Amplitude-paired waveform. [intensities] matches [timings] one to one.
  /// Zero intensity is a pause. The first and last moving pulses are 1 and
  /// 255 on the way in, then 255 and 1 on the way out.
  static BreathWaveform ramp() {
    final timings = <int>[];
    final intensities = <int>[];
    _appendPhase(timings, intensities, inhaleMs, rising: true);
    _appendHold(timings, intensities, topHoldMs);
    _appendPhase(timings, intensities, exhaleMs, rising: false);
    _appendHold(timings, intensities, bottomHoldMs);
    return BreathWaveform(timings, intensities);
  }

  /// One moving phase. The length matches [phaseMs]. Pulses rise or fall
  /// across that phase. A phase shorter than one pulse is a single buzz.
  static BreathWaveform phase(int phaseMs, {required bool rising}) {
    final timings = <int>[];
    final intensities = <int>[];
    if (phaseMs > 0) {
      _appendPhase(timings, intensities, phaseMs, rising: rising);
    }
    if (timings.isEmpty) {
      timings.add(pulseOnMs);
      intensities.add(rising ? 1 : 255);
    }
    return BreathWaveform(timings, intensities);
  }

  /// Older motors ignore an amplitude array and read the timings as
  /// off, on, off, on, starting with a delay. This is that shape of [ramp],
  /// with a leading zero so the first pulse starts immediately.
  static List<int> legacy() => asLegacy(ramp());

  /// Same off/on reading as [legacy], for one phase waveform.
  static List<int> asLegacy(BreathWaveform wave) {
    final timings = <int>[];
    final amps = <int>[];
    for (var i = 0; i < wave.timings.length; i++) {
      final amp = wave.intensities[i];
      if (amps.isNotEmpty && amps.last == 0 && amp == 0) {
        timings[timings.length - 1] += wave.timings[i];
        continue;
      }
      timings.add(wave.timings[i]);
      amps.add(amp);
    }

    final pattern = <int>[0];
    for (final timing in timings) {
      pattern.add(timing);
    }
    return pattern;
  }

  static void _appendHold(
    List<int> timings,
    List<int> intensities,
    int milliseconds,
  ) {
    timings.add(milliseconds);
    intensities.add(0);
  }

  /// 27 pulses of 50ms on and 150ms off fill 5400ms. The last gap keeps the
  /// remaining 100ms so the phase lands on 5500ms.
  static void _appendPhase(
    List<int> timings,
    List<int> intensities,
    int phaseMs, {
    required bool rising,
  }) {
    final slot = pulseOnMs + pulseOffMs;
    final pulses = phaseMs ~/ slot;
    final remainder = phaseMs - (pulses * slot);
    for (var i = 0; i < pulses; i++) {
      timings.add(pulseOnMs);
      intensities.add(_level(i, pulses, rising: rising));
      var gap = pulseOffMs;
      if (i == pulses - 1) gap += remainder;
      timings.add(gap);
      intensities.add(0);
    }
  }

  static int _level(int index, int count, {required bool rising}) {
    if (count <= 1) return rising ? 255 : 1;
    final steps = count - 1;
    final scaled = ((index * 254) + (steps ~/ 2)) ~/ steps;
    final value = rising ? 1 + scaled : 255 - scaled;
    if (value < 1) return 1;
    if (value > 255) return 255;
    return value;
  }
}
