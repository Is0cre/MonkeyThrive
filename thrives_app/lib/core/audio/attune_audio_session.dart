import 'package:audio_session/audio_session.dart';

/// Lets Attune play beside Spotify, a podcast, or any other app.
///
/// [configureForMix] sets the iOS playback category to mixWithOthers and
/// stores media attributes for Android. It does not activate the session.
/// Activation is what calls requestAudioFocus, and the default gain type is
/// exclusive. Attune players are created with
/// `handleAudioSessionActivation: false`, so just_audio never activates it.
class AttuneAudioSession {
  AttuneAudioSession._();

  static Future<void> configureForMix() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        // If another app ducks us, keep playing at the slider level.
        androidWillPauseWhenDucked: false,
      ),
    );
  }
}
