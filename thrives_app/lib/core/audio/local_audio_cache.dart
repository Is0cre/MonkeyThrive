import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'acoustic_synthesis_gate.dart';
import 'local_audio_cache_io.dart'
    if (dart.library.js_interop) 'local_audio_cache_web.dart' as platform_cache;

class LocalAudioCache {
  LocalAudioCache._();

  static final Map<String, AudioSource> _memorySources = {};

  /// Returns a ready-to-play [AudioSource] that works 100% offline on both
  /// Android/desktop (via temp file) and iOS/Web PWA (via in-memory data URI).
  /// Runs heavy WAV synthesis in a background isolate on native platforms.
  ///
  /// Refuses before [builder] runs while acoustic synthesis is gated, so no
  /// isolate is spawned and no WAV buffer is allocated.
  static Future<AudioSource> audioSource(
    String key,
    Uint8List Function() builder,
  ) async {
    if (!AcousticSynthesisGate.enabled) {
      throw StateError(AcousticSynthesisGate.message);
    }

    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final cached = _memorySources[safeKey];
    if (cached != null) return cached;

    final bytes = kIsWeb ? builder() : await compute(_runBuilder, builder);

    if (kIsWeb) {
      final dataUri = Uri.dataFromBytes(bytes, mimeType: 'audio/wav');
      final source = AudioSource.uri(dataUri);
      _memorySources[safeKey] = source;
      return source;
    } else {
      final fileUri = await platform_cache.writeWavFile(safeKey, bytes);
      final source = AudioSource.uri(fileUri);
      _memorySources[safeKey] = source;
      return source;
    }
  }

  static Uint8List _runBuilder(Uint8List Function() builder) => builder();
}
