import 'package:just_audio/just_audio.dart';

/// Bundled mask recordings, in season order. Playing these files does not
/// open nature synthesis.
///
/// Vivaldi, The Four Seasons, Op. 8. The Modena Chamber Orchestra. Musopen
/// distributes these performances as public-domain recordings. Each file is
/// a whole concerto, so it includes the faster allegro movements as well as
/// the slow one. Winter is the same file previously stored as
/// vivaldi_winter_rv297.mp3.
const attuneMaskAssets = <String>[
  'assets/audio/01_vivaldi_spring.ogg',
  'assets/audio/02_vivaldi_summer.ogg',
  'assets/audio/03_vivaldi_autumn.ogg',
  'assets/audio/04_vivaldi_winter.ogg',
];

/// Playback length of each file, in seconds, rounded down.
/// Spring is about 10:51, Summer 10:29, Autumn 12:13, and Winter 9:08.
/// The session slider uses the whole minutes of this length so a tone
/// cannot be set to run past the recording.
const attuneMaskDurationSeconds = <int>[650, 629, 733, 548];

/// Root of the season's home key, A=440.
/// Spring is E, Summer is G, Autumn and Winter are F.
double attuneMaskCarrierHz(int index) {
  switch (index) {
    case 0:
      return 164.8;
    case 1:
      return 196.0;
    case 2:
    case 3:
      return 174.6;
    default:
      return 164.8;
  }
}

/// Whole minutes of [attuneMaskDurationSeconds], never rounded up.
int attuneMaskDurationMinutes(int index) {
  final seconds = attuneMaskDurationSeconds[index];
  final minutes = seconds ~/ 60;
  return minutes < 1 ? 1 : minutes;
}

ConcatenatingAudioSource attuneMaskSource() {
  return ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [
      for (final asset in attuneMaskAssets) AudioSource.asset(asset),
    ],
  );
}
