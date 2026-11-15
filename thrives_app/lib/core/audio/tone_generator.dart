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

  BinauralBeatSource({
    required this.carrierHz,
    required this.beatHz,
    this.amplitude = 0.28,
  });

  @override
  Uint8List buildWav() {
    final numSamples = toneLoopSamples(
      _sampleRate,
      [carrierHz, carrierHz + beatHz],
    );
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
      final left = amplitude * math.sin(2 * math.pi * carrierHz * t);
      final right =
          amplitude * math.sin(2 * math.pi * (carrierHz + beatHz) * t);
      buf.setInt16(44 + i * 4, pcm16(left), Endian.little);
      buf.setInt16(44 + i * 4 + 2, pcm16(right), Endian.little);
    }
    return buf.buffer.asUint8List();
  }
}

/// Top-level so [compute] can run it in a release isolate.
/// [carrierAndBeat] is `[carrierHz, beatHz]`.
Uint8List synthesizeBinauralWav(List<double> carrierAndBeat) {
  return BinauralBeatSource(
    carrierHz: carrierAndBeat[0],
    beatHz: carrierAndBeat[1],
  ).bytes;
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

  IsochronicToneSource({
    required this.carrierHz,
    required this.beatHz,
    this.amplitude = 0.32,
  });

  @override
  Uint8List buildWav() {
    final numSamples = toneLoopSamples(
      _sampleRate,
      [carrierHz, beatHz],
    );
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
      final sample =
          amplitude * smoothedGate * math.sin(2 * math.pi * carrierHz * t);
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

/// Top-level so [compute] can run it in a release isolate.
/// [carrierAndBeat] is `[carrierHz, beatHz]`.
Uint8List synthesizeIsochronicWav(List<double> carrierAndBeat) {
  return IsochronicToneSource(
    carrierHz: carrierAndBeat[0],
    beatHz: carrierAndBeat[1],
  ).bytes;
}

/// Shortest loop, up to ten seconds, that brings every frequency back to a
/// whole cycle. An integer rate stays one second. 164.8 Hz needs five,
/// because 164.8 × 5 is a whole number of cycles, so the join does not click.
int toneLoopSamples(int sampleRate, List<double> frequencies) {
  const maxSeconds = 10;
  for (var seconds = 1; seconds <= maxSeconds; seconds++) {
    var closed = true;
    for (final hz in frequencies) {
      final cycles = hz * seconds;
      if ((cycles - cycles.round()).abs() > 0.0001) {
        closed = false;
        break;
      }
    }
    if (closed) return sampleRate * seconds;
  }
  return sampleRate * maxSeconds;
}
