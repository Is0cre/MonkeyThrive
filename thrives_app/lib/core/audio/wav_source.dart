// ignore_for_file: experimental_member_use

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'acoustic_synthesis_gate.dart';

abstract class CachedWavSource extends StreamAudioSource {
  Uint8List? _cache;

  Uint8List buildWav();

  Uint8List get bytes => _cache ??= buildWav();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    if (!AcousticSynthesisGate.enabled) {
      throw StateError(AcousticSynthesisGate.message);
    }
    final data = bytes;
    final safeStart = (start ?? 0).clamp(0, data.length).toInt();
    final safeEnd = (end ?? data.length).clamp(safeStart, data.length).toInt();
    return StreamAudioResponse(
      sourceLength: data.length,
      contentLength: safeEnd - safeStart,
      offset: safeStart,
      stream: Stream.value(data.sublist(safeStart, safeEnd)),
      contentType: 'audio/wav',
    );
  }
}

void writeWavHeader(
  ByteData data, {
  required int sampleRate,
  required int numSamples,
  required int channels,
}) {
  const bitsPerSample = 16;
  final dataSize = numSamples * channels * (bitsPerSample ~/ 8);
  writeAscii(data, 0, 'RIFF');
  data.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(data, 8, 'WAVE');
  writeAscii(data, 12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(
    28,
    sampleRate * channels * bitsPerSample ~/ 8,
    Endian.little,
  );
  data.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
  data.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(data, 36, 'data');
  data.setUint32(40, dataSize, Endian.little);
}

void writeAscii(ByteData data, int offset, String value) {
  for (var i = 0; i < value.length; i++) {
    data.setUint8(offset + i, value.codeUnitAt(i));
  }
}

int pcm16(double value) {
  return (value.clamp(-1.0, 1.0) * 32767).round().clamp(-32768, 32767).toInt();
}

double fadeEnvelope(int index, int total, int fadeFrames) {
  if (fadeFrames <= 0) return 1.0;
  if (index < fadeFrames) return index / fadeFrames;
  if (index > total - fadeFrames) return (total - index) / fadeFrames;
  return 1.0;
}

double sine(double hz, double seconds) => math.sin(2 * math.pi * hz * seconds);
