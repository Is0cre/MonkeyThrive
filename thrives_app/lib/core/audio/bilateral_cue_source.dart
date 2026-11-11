import 'dart:typed_data';

import 'wav_source.dart';

class BilateralCueSource extends CachedWavSource {
  final bool right;
  final double carrierHz;
  final double amplitude;

  static const int _sampleRate = 44100;
  static const int _durationMs = 90;

  BilateralCueSource({
    required this.right,
    this.carrierHz = 440,
    this.amplitude = 0.22,
  });

  @override
  Uint8List buildWav() {
    final numSamples = (_sampleRate * _durationMs / 1000).round();
    final buffer = ByteData(44 + numSamples * 4);
    writeWavHeader(
      buffer,
      sampleRate: _sampleRate,
      numSamples: numSamples,
      channels: 2,
    );

    final fadeFrames = (_sampleRate * 0.015).round();
    for (var i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final env = fadeEnvelope(i, numSamples, fadeFrames);
      final value = pcm16(env * amplitude * sine(carrierHz, t));
      final left = right ? 0 : value;
      final rightValue = right ? value : 0;
      buffer.setInt16(44 + i * 4, left, Endian.little);
      buffer.setInt16(44 + i * 4 + 2, rightValue, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
