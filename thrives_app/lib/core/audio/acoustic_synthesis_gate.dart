/// Holds deterministic tone, noise, and bilateral-cue synthesis off
/// until calibration can rule out sudden sensory triggers.
///
/// While [enabled] is false, callers must not construct an audio player
/// or run a WAV builder. Playback entry points check this before they
/// allocate a player or a synthesis buffer.
class AcousticSynthesisGate {
  AcousticSynthesisGate._();

  /// Runtime switch so the placeholder and the player both stay reachable
  /// to the analyzer. Playback code must still lazy-create players.
  static final bool enabled = false;

  static const String message =
      'Deterministic acoustic synthesis is undergoing calibration to prevent sudden sensory triggers. Available in a future release.';
}
