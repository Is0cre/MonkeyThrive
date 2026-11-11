import 'dart:math' as math;
import 'dart:typed_data';

import 'wav_source.dart';

/// Procedurally generated ambient noise sources for nervous system regulation.
///
/// All sounds are synthesised in-memory — no audio assets required.
/// Each source generates a 60-second loopable WAV using a fixed random seed
/// so quality is deterministic across plays.
///
/// Noise shapes:
///   Rain    — Pink noise (1/f spectrum), fine high-frequency texture
///   Ocean   — Brown noise + slow 0.1 Hz amplitude modulation (wave cycles)
///   Forest  — Pink noise mid-band, slow random texture variation
///   River   — Pink noise with 0.4–1.2 Hz shallow flutter
///   Thunder — Brown noise + random low-frequency percussion pulses
///   Wind    — Brown noise with 0.2 Hz sinusoidal swell
///
/// Clinical context: sustained non-threatening auditory input (noise floors)
/// activates the parasympathetic branch and reduces hypervigilance by giving
/// the auditory threat-detection system a stable, low-salience background.
/// Ref: Stanchina et al. (2005) — white/pink noise for ICU sleep; Brown & Berry
/// (2019) — nature sounds for ANS recovery.
enum NatureNoiseType {
  rain,
  ocean,
  forest,
  river,
  thunder,
  wind,
}

extension NatureNoiseTypeInfo on NatureNoiseType {
  String get label {
    switch (this) {
      case NatureNoiseType.rain:
        return 'Rain';
      case NatureNoiseType.ocean:
        return 'Ocean';
      case NatureNoiseType.forest:
        return 'Forest';
      case NatureNoiseType.river:
        return 'River';
      case NatureNoiseType.thunder:
        return 'Thunder';
      case NatureNoiseType.wind:
        return 'Wind';
    }
  }
}

class NatureNoiseSource extends CachedWavSource {
  final NatureNoiseType type;
  final double amplitude;

  static const int _sampleRate = 44100;
  static const int _durationSeconds = 60;

  NatureNoiseSource(this.type, {this.amplitude = 0.30});

  @override
  Uint8List buildWav() {
    final numSamples = _sampleRate * _durationSeconds;
    final buf = ByteData(44 + numSamples * 2); // mono int16

    writeWavHeader(
      buf,
      sampleRate: _sampleRate,
      numSamples: numSamples,
      channels: 1,
    );

    final rng = math.Random(type.index + 42); // fixed seed per type
    final rawNoise = Float64List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      rawNoise[i] = rng.nextDouble() * 2.0 - 1.0;
    }

    final samples = _shape(rawNoise, numSamples, rng);

    // Normalise peak to amplitude, apply fade in/out
    double peak = 0;
    for (int i = 0; i < numSamples; i++) {
      final absVal = samples[i].abs();
      if (absVal > peak) peak = absVal;
    }
    final scale = peak > 0 ? amplitude / peak : amplitude;

    for (int i = 0; i < numSamples; i++) {
      final env = _envelope(i, numSamples);
      final v = (samples[i] * scale * env).clamp(-1.0, 1.0);
      buf.setInt16(44 + i * 2, pcm16(v), Endian.little);
    }

    return buf.buffer.asUint8List();
  }

  Float64List _shape(Float64List white, int n, math.Random rng) {
    switch (type) {
      case NatureNoiseType.rain:
        return _pink(white, n);
      case NatureNoiseType.ocean:
        return _oceanShape(white, n);
      case NatureNoiseType.forest:
        return _forestShape(white, n, rng);
      case NatureNoiseType.river:
        return _riverShape(white, n, rng);
      case NatureNoiseType.thunder:
        return _thunderShape(white, n, rng);
      case NatureNoiseType.wind:
        return _windShape(white, n);
    }
  }

  // ── Noise colouring ────────────────────────────────────────────────────────

  /// Pink noise via Paul Kellet's IIR approximation.
  /// Spectral density ∝ 1/f — sounds like rain, steady static.
  static Float64List _pink(Float64List w, int n) {
    final out = Float64List(n);
    double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (int i = 0; i < n; i++) {
      final white = w[i];
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      b3 = 0.86650 * b3 + white * 0.3104856;
      b4 = 0.55000 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.0168980;
      out[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
      b6 = white * 0.115926;
    }
    return out;
  }

  /// Brown noise via cumulative sum — spectral density ∝ 1/f².
  /// Deep, low rumble. Reset drift periodically.
  static Float64List _brown(Float64List w, int n) {
    final out = Float64List(n);
    double acc = 0;
    for (int i = 0; i < n; i++) {
      acc = (acc + w[i] * 0.02) * 0.9997;
      out[i] = acc;
    }
    return out;
  }

  Float64List _oceanShape(Float64List w, int n) {
    final brown = _brown(w, n);
    // Slow wave AM: 0.1 Hz — mimics wave surge and retreat
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final wave = 0.6 + 0.4 * math.sin(2 * math.pi * 0.10 * t + 1.0);
      brown[i] *= wave;
    }
    return brown;
  }

  Float64List _forestShape(Float64List w, int n, math.Random rng) {
    // Pink noise with a gentle slow swell (0.05 Hz) for organic variation
    final pink = _pink(w, n);
    final phase = rng.nextDouble() * math.pi * 2;
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final swell = 0.75 + 0.25 * math.sin(2 * math.pi * 0.05 * t + phase);
      pink[i] *= swell;
    }
    return pink;
  }

  Float64List _riverShape(Float64List w, int n, math.Random rng) {
    final pink = _pink(w, n);
    // Flutter: fast modulation (0.4–1.2 Hz) — babbling water texture
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final flutter = 0.75 +
          0.25 *
              math.sin(2 * math.pi * 0.7 * t) *
              math.cos(2 * math.pi * 0.3 * t + 0.5);
      pink[i] *= flutter.clamp(0.4, 1.0);
    }
    return pink;
  }

  Float64List _thunderShape(Float64List w, int n, math.Random rng) {
    final brown = _brown(w, n);
    // Random distant thunder pulses every 8–20 seconds
    int nextPulse = _sampleRate * (8 + rng.nextInt(12));
    while (nextPulse < n) {
      final pulseLen = _sampleRate * (2 + rng.nextInt(3)); // 2–4 second rumble
      final pulseAmp = 0.6 + rng.nextDouble() * 0.4;
      for (int j = 0; j < pulseLen && nextPulse + j < n; j++) {
        final env = math.sin(math.pi * j / pulseLen);
        brown[nextPulse + j] +=
            w[(nextPulse + j) % w.length] * pulseAmp * env * 2.0;
      }
      nextPulse += _sampleRate * (8 + rng.nextInt(12));
    }
    return brown;
  }

  Float64List _windShape(Float64List w, int n) {
    final brown = _brown(w, n);
    // Slow gust: 0.2 Hz sinusoidal swell
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final gust = 0.5 + 0.5 * math.sin(2 * math.pi * 0.20 * t);
      brown[i] *= gust;
    }
    return brown;
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static double _envelope(int i, int total) {
    const fadeFrames = 4410; // 100 ms
    return fadeEnvelope(i, total, fadeFrames);
  }
}
