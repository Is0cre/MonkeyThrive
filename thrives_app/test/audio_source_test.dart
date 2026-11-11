import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/audio/bilateral_cue_source.dart';
import 'package:monkeythrive/core/audio/noise_generator.dart';
import 'package:monkeythrive/core/audio/tone_generator.dart';

void main() {
  test('generated tone sources produce non-empty WAV audio', () {
    final sources = [
      BinauralBeatSource(carrierHz: 200, beatHz: 10),
      IsochronicToneSource(carrierHz: 200, beatHz: 10),
      NatureNoiseSource(NatureNoiseType.rain),
    ];

    for (final source in sources) {
      final bytes = source.bytes;
      expect(_ascii(bytes, 0, 4), 'RIFF');
      expect(_ascii(bytes, 8, 4), 'WAVE');
      expect(_ascii(bytes, 36, 4), 'data');
      expect(_hasNonZeroSample(bytes), true);
    }
  });

  test('bilateral cue routes audio to the requested channel', () {
    final left = BilateralCueSource(right: false).bytes;
    final right = BilateralCueSource(right: true).bytes;

    expect(_channelHasSignal(left, channel: 0), true);
    expect(_channelHasSignal(left, channel: 1), false);
    expect(_channelHasSignal(right, channel: 0), false);
    expect(_channelHasSignal(right, channel: 1), true);
  });
}

String _ascii(Uint8List bytes, int offset, int length) {
  return ascii.decode(bytes.sublist(offset, offset + length));
}

bool _hasNonZeroSample(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  for (var i = 44; i < bytes.length - 1; i += 2) {
    if (data.getInt16(i, Endian.little) != 0) return true;
  }
  return false;
}

bool _channelHasSignal(Uint8List bytes, {required int channel}) {
  final data = ByteData.sublistView(bytes);
  final offset = 44 + channel * 2;
  for (var i = offset; i < bytes.length - 3; i += 4) {
    if (data.getInt16(i, Endian.little) != 0) return true;
  }
  return false;
}
