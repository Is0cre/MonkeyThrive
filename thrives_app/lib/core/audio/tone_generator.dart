import 'dart:math' as math;
import 'dart:typed_data';

import 'wav_source.dart';

/// Frequency bands for binaural/isochronic entrainment.
enum BrainwaveBand {
  delta,
  theta,
  alpha,
  beta,
}

extension BrainwaveBandInfo on BrainwaveBand {
  String get label {
    switch (this) {
      case BrainwaveBand.delta:
        return 'Delta';
      case BrainwaveBand.theta:
        return 'Theta';
      case BrainwaveBand.alpha:
        return 'Alpha';
      case BrainwaveBand.beta:
        return 'Beta';
    }
  }

  String get range {
    switch (this) {
      case BrainwaveBand.delta:
        return '0.5–4 Hz';
      case BrainwaveBand.theta:
        return '4–8 Hz';
      case BrainwaveBand.alpha:
        return '8–14 Hz';
      case BrainwaveBand.beta:
        return '14–30 Hz';
    }
  }

  String get use {
    switch (this) {
      case BrainwaveBand.delta:
        return 'Deep sleep · Recovery';
      case BrainwaveBand.theta:
        return 'Deep relaxation · Processing';
      case BrainwaveBand.alpha:
        return 'Calm focus · Grounded';
      case BrainwaveBand.beta:
        return 'Alert · Present';
    }
  }

  /// Default beat frequency in Hz for this band
  double get defaultBeatHz {
    switch (this) {
      case BrainwaveBand.delta:
        return 2.0;
      case BrainwaveBand.theta:
        return 6.0;
      case BrainwaveBand.alpha:
        return 10.0;
      case BrainwaveBand.beta:
        return 20.0;
    }
  }
}

/// Generates a loopable WAV audio source for binaural beats.
///
/// Binaural beats: left ear gets [carrierHz], right ear gets [carrierHz + beatHz].
/// The brain perceives the difference as a beat at [beatHz].
/// Requires stereo headphones.
class BinauralBeatSource extends CachedWavSource {
  final double carrierHz;
  final double beatHz;
  final double amplitude;

  static const int _sampleRate = 44100;
  static const int _durationSeconds = 30; // loop chunk length

  BinauralBeatSource({
    required this.carrierHz,
    required this.beatHz,
    this.amplitude = 0.28,
  });

  @override
  Uint8List buildWav() {
    final numSamples = _sampleRate * _durationSeconds;
    // 44-byte WAV header + stereo int16 samples (2 channels × 2 bytes)
    final buf = ByteData(44 + numSamples * 4);
    writeWavHeader(
      buf,
      sampleRate: _sampleRate,
      numSamples: numSamples,
      channels: 2,
    );

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      // Fade in/out over first/last 0.1s to avoid clicks
      final env = _envelope(i, numSamples);
      final left = env * amplitude * math.sin(2 * math.pi * carrierHz * t);
      final right =
          env * amplitude * math.sin(2 * math.pi * (carrierHz + beatHz) * t);
      buf.setInt16(44 + i * 4, pcm16(left), Endian.little);
      buf.setInt16(44 + i * 4 + 2, pcm16(right), Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  static double _envelope(int i, int total) {
    const fadeFrames = 4410; // 0.1s
    return fadeEnvelope(i, total, fadeFrames);
  }
}

/// Generates isochronic tones — works without headphones.
///
/// A single carrier frequency with amplitude pulsed at [beatHz].
/// Sharper than binaural, audible on speakers.
class IsochronicToneSource extends CachedWavSource {
  final double carrierHz;
  final double beatHz;
  final double amplitude;

  static const int _sampleRate = 44100;
  static const int _durationSeconds = 30;

  IsochronicToneSource({
    required this.carrierHz,
    required this.beatHz,
    this.amplitude = 0.32,
  });

  @override
  Uint8List buildWav() {
    final numSamples = _sampleRate * _durationSeconds;
    // Mono: 1 channel × 2 bytes per sample
    final buf = ByteData(44 + numSamples * 2);
    writeWavHeader(
      buf,
      sampleRate: _sampleRate,
      numSamples: numSamples,
      channels: 1,
    );

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      // Pulse: rectangular gate at beat frequency (50% duty cycle)
      final gate = math.sin(math.pi * beatHz * t) >= 0 ? 1.0 : 0.0;
      // Smooth the gate edges slightly to reduce harshness
      final smoothedGate = gate * _softgate(i, beatHz);
      final env = BinauralBeatSource._envelope(i, numSamples);
      final sample = env *
          amplitude *
          smoothedGate *
          math.sin(2 * math.pi * carrierHz * t);
      buf.setInt16(44 + i * 2, pcm16(sample), Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  double _softgate(int i, double beatHz) {
    // Apply a very short cosine fade at each gate transition to avoid clicks
    final t = i / _sampleRate;
    final phaseInCycle = (t * beatHz) % 1.0;
    const fadeWidth = 0.05; // 5% of cycle
    if (phaseInCycle < fadeWidth) {
      return (1 - math.cos(math.pi * phaseInCycle / fadeWidth)) / 2;
    }
    if (phaseInCycle > 0.5 - fadeWidth && phaseInCycle < 0.5) {
      return (1 +
              math.cos(
                  math.pi * (phaseInCycle - (0.5 - fadeWidth)) / fadeWidth)) /
          2;
    }
    if (phaseInCycle >= 0.5) return 0.0;
    return 1.0;
  }
}
