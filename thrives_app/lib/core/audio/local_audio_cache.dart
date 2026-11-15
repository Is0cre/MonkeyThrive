import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'acoustic_synthesis_gate.dart';
import 'local_audio_cache_io.dart'
    if (dart.library.js_interop) 'local_audio_cache_web.dart' as platform_cache;
import 'tone_generator.dart';

class LocalAudioCache {
  LocalAudioCache._();

  static final Map<String, AudioSource> _memorySources = {};

  /// Returns a ready-to-play [AudioSource] that works 100% offline on both
  /// Android/desktop (via temp file) and iOS/Web PWA (via in-memory data URI).
  /// Runs heavy WAV synthesis in a background isolate on native platforms.
  ///
  /// Refuses before [builder] runs when this synthesis is gated, so no
  /// isolate is spawned and no WAV buffer is allocated. Attune carriers use
  /// [toneSource]. Nature and bilateral cues stay on the closed gate.
  static Future<AudioSource> audioSource(
    String key,
    Uint8List Function() builder, {
    bool tone = false,
  }) async {
    final allowed = tone
        ? AcousticSynthesisGate.tonesEnabled
        : AcousticSynthesisGate.enabled;
    if (!allowed) {
      throw StateError(AcousticSynthesisGate.message);
    }

    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final cached = _memorySources[safeKey];
    if (cached != null) return cached;

    final bytes = kIsWeb ? builder() : await compute(_runBuilder, builder);

    return _remember(safeKey, bytes);
  }

  /// Binaural or isochronic carrier. The builder is a top-level function so a
  /// release isolate can run it. A failed isolate falls back to this one.
  static Future<AudioSource> toneSource({
    required String key,
    required bool binaural,
    required double carrierHz,
    required double beatHz,
  }) async {
    if (!AcousticSynthesisGate.tonesEnabled) {
      throw StateError(AcousticSynthesisGate.message);
    }

    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final cached = _memorySources[safeKey];
    if (cached != null) return cached;

    final args = <double>[carrierHz, beatHz];
    final synthesize =
        binaural ? synthesizeBinauralWav : synthesizeIsochronicWav;
    Uint8List bytes;
    if (kIsWeb) {
      bytes = synthesize(args);
    } else {
      try {
        bytes = await compute(synthesize, args);
      } catch (_) {
        bytes = synthesize(args);
      }
    }
    return _remember(safeKey, bytes);
  }

  static Future<AudioSource> _remember(String safeKey, Uint8List bytes) async {
    if (kIsWeb) {
      final dataUri = Uri.dataFromBytes(bytes, mimeType: 'audio/wav');
      final source = AudioSource.uri(dataUri);
      _memorySources[safeKey] = source;
      return source;
    }
    final fileUri = await platform_cache.writeWavFile(safeKey, bytes);
    final source = AudioSource.uri(fileUri);
    _memorySources[safeKey] = source;
    return source;
  }

  static Uint8List _runBuilder(Uint8List Function() builder) => builder();
}
