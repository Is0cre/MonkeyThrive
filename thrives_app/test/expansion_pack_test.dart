import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:monkeythrive/features/attune/attune_mask_playlist.dart';
import 'package:monkeythrive/features/attune/expansions/attune_track.dart';
import 'package:monkeythrive/features/attune/expansions/expansion_pack_service.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('mt-expansion');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a note name uses the season octave and an empty key has no carrier',
      () {
    expect(carrierHzForKey(''), isNull);
    expect(carrierHzForKey('later'), isNull);
    expect(carrierHzForKey('E'), attuneMaskCarrierHz(0));
    expect(carrierHzForKey('G'), attuneMaskCarrierHz(1));
    expect(carrierHzForKey('F'), attuneMaskCarrierHz(2));
    expect(carrierHzForKey('E4'), 329.6);
    expect(carrierHzForKey('174.6'), 174.6);
    expect(carrierHzForKey('0'), isNull);
  });

  test('a local zip joins the bundled seasons and plays from disk', () async {
    final service = ExpansionPackService(rootPath: root.path);
    final result = await service.installArchive(
      _zip({
        'manifest.json': utf8.encode(
          '{"05_satie_gymnopedie_1.ogg":{"key":"E","bpm":72}}',
        ),
        '05_satie_gymnopedie_1.ogg': <int>[1, 2, 3, 4],
      }),
      packName: 'satie_expansion',
    );

    expect(result.installed, isTrue);
    expect(result.trackCount, 1);
    final tracks = await service.loadTracks();
    expect(tracks, hasLength(5));
    expect(tracks.first.assetPath, attuneMaskAssets.first);
    expect(tracks.first.carrierHz, 164.8);
    final satie = tracks.last;
    expect(satie.packName, 'satie_expansion');
    expect(satie.keyName, 'E');
    expect(satie.bpm, 72);
    expect(satie.carrierHz, 164.8);
    expect(satie.filePath, endsWith('05_satie_gymnopedie_1.ogg'));
    expect(File(satie.filePath!).readAsBytesSync(), [1, 2, 3, 4]);
    expect(satie.source, isA<AudioSource>());
    expect(satie.composer, isEmpty);
    expect(satie.title, isEmpty);
  });

  test('a catalog list keeps composer, title, and movement', () async {
    final service = ExpansionPackService(rootPath: root.path);
    final result = await service.installArchive(
      _zip({
        'manifest.json': utf8.encode(jsonEncode([
          {
            'file': '10_beethoven_op132_mvt3.ogg',
            'composer': 'Ludwig van Beethoven',
            'title': 'String Quartet No. 15 in A minor, Op. 132',
            'movement': '3 (Heiliger Dankgesang)',
            'key': '',
            'bpm': 0,
          },
          {
            'file': '08_beethoven_op132_mvt1.ogg',
            'composer': 'Ludwig van Beethoven',
            'title': 'String Quartet No. 15 in A minor, Op. 132',
            'movement': '1',
            'key': 'A',
            'bpm': 0,
          },
        ])),
        '10_beethoven_op132_mvt3.ogg': <int>[1],
        '08_beethoven_op132_mvt1.ogg': <int>[2],
      }),
      packName: 'beethoven_expansion',
    );

    expect(result.installed, isTrue);
    expect(result.trackCount, 2);
    final tracks = await service.loadTracks();
    final beethoven = tracks.where((track) => !track.isBundled).toList();
    expect(beethoven, hasLength(2));
    expect(beethoven.first.filePath, endsWith('10_beethoven_op132_mvt3.ogg'));
    expect(beethoven.first.composer, 'Ludwig van Beethoven');
    expect(
      beethoven.first.title,
      'String Quartet No. 15 in A minor, Op. 132',
    );
    expect(beethoven.first.label, beethoven.first.title);
    expect(beethoven.first.movement, '3 (Heiliger Dankgesang)');
    expect(beethoven.first.keyName, isEmpty);
    expect(beethoven.first.carrierHz, isNull);
    expect(beethoven.last.movement, '1');
    expect(beethoven.last.keyName, 'A');
    expect(beethoven.last.carrierHz, 220.0);
  });

  test('a zip that leaves the pack directory is refused', () async {
    final service = ExpansionPackService(rootPath: root.path);
    final result = await service.installArchive(
      _zip({
        'manifest.json': utf8.encode('{}'),
        '../escape.ogg': <int>[9],
      }),
      packName: 'satie_expansion',
    );

    expect(result.installed, isFalse);
    expect(result.failure, ExpansionFailure.unsafeArchive);
    expect(File('${root.path}/escape.ogg').existsSync(), isFalse);
    expect(Directory('${root.path}/expansions').existsSync(), isFalse);
  });

  test('download keeps the device quiet when the network is absent', () async {
    final service = ExpansionPackService(
      rootPath: root.path,
      fetcher: (url) async => throw StateError('offline $url'),
    );
    final result = await service.downloadPack(
      url: Uri.parse('https://monkeythrive.app/expansions/satie_expansion.zip'),
      packName: 'satie_expansion',
    );
    expect(result.installed, isFalse);
    expect(result.failure, ExpansionFailure.unreachable);
    expect(Directory('${root.path}/expansions').existsSync(), isFalse);
  });

  test('a failed download does not replace a pack already on disk', () async {
    final service = ExpansionPackService(
      rootPath: root.path,
      fetcher: (_) async => const ExpansionFetch(404, []),
    );
    await service.installArchive(
      _zip({
        'manifest.json': utf8.encode(
          '{"05_satie_gymnopedie_1.ogg":{"key":"F","bpm":0}}',
        ),
        '05_satie_gymnopedie_1.ogg': <int>[7],
      }),
      packName: 'satie_expansion',
    );
    final result = await service.downloadPack(
      url: Uri.parse('https://monkeythrive.app/expansions/satie_expansion.zip'),
      packName: 'satie_expansion',
    );
    expect(result.failure, ExpansionFailure.badResponse);
    final tracks = await service.loadTracks();
    expect(tracks.last.keyName, 'F');
    expect(File(tracks.last.filePath!).readAsBytesSync(), [7]);
  });

  test('plain http and a bad pack name are refused before a fetch', () async {
    var called = false;
    final service = ExpansionPackService(
      rootPath: root.path,
      fetcher: (_) async {
        called = true;
        return const ExpansionFetch(200, []);
      },
    );
    final insecure = await service.downloadPack(
      url: Uri.parse('http://monkeythrive.app/expansions/satie_expansion.zip'),
      packName: 'satie_expansion',
    );
    final named = await service.downloadPack(
      url: Uri.parse('https://monkeythrive.app/expansions/satie_expansion.zip'),
      packName: '../satie',
    );
    expect(insecure.failure, ExpansionFailure.badResponse);
    expect(named.failure, ExpansionFailure.unusableName);
    expect(called, isFalse);
  });
}

List<int> _zip(Map<String, List<int>> files) {
  final archive = Archive();
  for (final item in files.entries) {
    archive.addFile(ArchiveFile(item.key, item.value.length, item.value));
  }
  return ZipEncoder().encode(archive);
}
