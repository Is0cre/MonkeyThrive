/// Holds nature soundscapes and bilateral-cue synthesis off until
/// calibration can rule out sudden sensory triggers.
///
/// [tonesEnabled] opens Attune's binaural and isochronic carriers. Those
/// tones start only after Play, and the level rises from silence. While
/// [enabled] is false, nature and EMDR audio must not construct a player
/// or run a WAV builder.
class AcousticSynthesisGate {
  AcousticSynthesisGate._();

  /// Runtime switch so the placeholder and the player both stay reachable
  /// to the analyzer. Playback code must still lazy-create players.
  static final bool enabled = false;

  /// Binaural and isochronic frequencies in Attune.
  static final bool tonesEnabled = true;

  static const String message =
      'Deterministic acoustic synthesis is undergoing calibration to prevent sudden sensory triggers. Available in a future release.';
}
