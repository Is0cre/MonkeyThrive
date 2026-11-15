import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';

import '../../../l10n/l10n.dart';
import '../attune_mask_playlist.dart';

/// One mask the Attune player can open with no network.
///
/// A bundled season uses [assetPath]. A file from an expansion pack uses
/// [filePath]. [keyName] is the musical root written in the pack manifest.
/// A bare note is octave 3 at A=440, the same octave as the Vivaldi seasons.
/// [bpm] is stored with the pack and is not a brainwave rate.
/// [composer], [title], and [movement] come from the pack catalog.
class AttuneTrack {
  const AttuneTrack({
    required this.id,
    required this.label,
    required this.packName,
    required this.keyName,
    required this.bpm,
    this.composer = '',
    this.title = '',
    this.movement = '',
    this.assetPath,
    this.filePath,
    this.durationSeconds,
  });

  final String id;
  final String label;
  final String packName;
  final String keyName;
  final int bpm;
  final String composer;
  final String title;
  final String movement;
  final String? assetPath;
  final String? filePath;
  final int? durationSeconds;

  bool get isBundled => assetPath != null;

  /// Composer and title, with the movement after a middle dot.
  String get choiceLabel {
    final piece = composer.isNotEmpty && title.isNotEmpty
        ? '$composer, $title'
        : (title.isNotEmpty ? title : composer);
    if (movement.isEmpty) return piece.isEmpty ? label : piece;
    if (piece.isEmpty) return movement;
    return '$piece · $movement';
  }

  /// Carrier root in hertz. Null when the manifest key is empty or unknown.
  double? get carrierHz => carrierHzForKey(keyName);

  AudioSource get source {
    final asset = assetPath;
    if (asset != null) return AudioSource.asset(asset);
    final file = filePath;
    if (file == null) {
      throw StateError('Attune track $id has no audio');
    }
    return AudioSource.file(file);
  }
}

/// Season name for a bundled mask, or [AttuneTrack.choiceLabel] for a pack.
String attuneTrackTitle(AttuneTrack track, AppLocalizations l10n) {
  switch (track.assetPath) {
    case 'assets/audio/01_vivaldi_spring.ogg':
      return l10n.attuneMaskTrackSpring;
    case 'assets/audio/02_vivaldi_summer.ogg':
      return l10n.attuneMaskTrackSummer;
    case 'assets/audio/03_vivaldi_autumn.ogg':
      return l10n.attuneMaskTrackAutumn;
    case 'assets/audio/04_vivaldi_winter.ogg':
      return l10n.attuneMaskTrackWinter;
    default:
      return track.choiceLabel;
  }
}

/// Group heading in the music list. A pack uses its composer when it has one.
String attunePackHeading(AttuneTrack track, AppLocalizations l10n) {
  if (track.isBundled) return l10n.attuneIncluded;
  if (track.composer.isNotEmpty) return track.composer;
  return track.packName;
}

/// The four seasons that ship inside the app, in playlist order.
List<AttuneTrack> bundledAttuneTracks() {
  const keys = <String>['E', 'G', 'F', 'F'];
  return [
    for (var i = 0; i < attuneMaskAssets.length; i++)
      AttuneTrack(
        id: attuneMaskAssets[i],
        label: attuneMaskAssets[i].split('/').last,
        packName: 'built-in',
        keyName: keys[i],
        bpm: 0,
        assetPath: attuneMaskAssets[i],
        durationSeconds: attuneMaskDurationSeconds[i],
      ),
  ];
}

/// Root in hertz for a manifest key.
///
/// Accepts a number such as `174.6`, or a note such as `F`, `Bb`, or `E4`.
/// A bare note uses octave 3. An empty or unknown key returns null.
double? carrierHzForKey(String keyName) {
  final text = keyName.trim();
  if (text.isEmpty) return null;
  final numeric = double.tryParse(text);
  if (numeric != null) {
    if (!numeric.isFinite || numeric <= 0) return null;
    return numeric;
  }
  final match = RegExp(r'^([A-Ga-g])([#bB])?([0-8])?$').firstMatch(text);
  if (match == null) return null;
  const semitone = <String, int>{
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };
  var pitch = semitone[match.group(1)!.toUpperCase()]!;
  final accidental = match.group(2);
  if (accidental == '#') pitch += 1;
  if (accidental == 'b' || accidental == 'B') pitch -= 1;
  final octave = match.group(3) == null ? 3 : int.parse(match.group(3)!);
  final midi = (octave + 1) * 12 + pitch;
  final raw = 440 * math.pow(2, (midi - 69) / 12);
  return (raw * 10).round() / 10;
}

/// Why a pack did not install. The files already on disk stay as they are.
enum ExpansionFailure {
  /// No route to the file. The release build has no network permission,
  /// the device is off-grid, or the request timed out.
  unreachable,

  /// The address was not https, or the server did not return the archive.
  badResponse,

  /// The bytes were not a zip, or the zip had no manifest.
  notAZip,

  /// A name tried to leave the pack directory, or a file was not an ogg
  /// or the manifest.
  unsafeArchive,

  /// The archive is larger than the local cap.
  tooLarge,

  /// The pack name cannot be used as a directory name.
  unusableName,

  /// This install has no local expansion directory. The web app is one.
  unavailable,
}

class ExpansionInstallResult {
  const ExpansionInstallResult._({
    required this.installed,
    this.failure,
    this.trackCount = 0,
  });

  const ExpansionInstallResult.installed(int trackCount)
      : this._(installed: true, trackCount: trackCount);

  const ExpansionInstallResult.failed(ExpansionFailure failure)
      : this._(installed: false, failure: failure);

  final bool installed;
  final ExpansionFailure? failure;
  final int trackCount;
}

class ExpansionFetch {
  const ExpansionFetch(this.statusCode, this.body);

  final int statusCode;
  final List<int> body;
}

typedef ExpansionFetcher = Future<ExpansionFetch> Function(Uri url);
