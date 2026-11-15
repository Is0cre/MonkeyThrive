import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'attune_track.dart';

/// Local expansion packs on Android, desktop, and tests.
///
/// A download is one GET for the address the caller passed. Nothing else is
/// sent. The release manifest removes INTERNET, so that GET fails on a
/// release build and comes back as [ExpansionFailure.unreachable]. Files
/// already extracted keep working with no network.
class ExpansionStore {
  ExpansionStore({
    ExpansionFetcher? fetcher,
    String? rootPath,
    this.maxBytes = 200 * 1024 * 1024,
  })  : _fetcher = fetcher,
        _rootPath = rootPath;

  final ExpansionFetcher? _fetcher;
  final String? _rootPath;
  final int maxBytes;

  Future<ExpansionInstallResult> downloadPack({
    required Uri url,
    required String packName,
  }) async {
    if (!_usableName(packName)) {
      return const ExpansionInstallResult.failed(ExpansionFailure.unusableName);
    }
    if (url.scheme != 'https') {
      return const ExpansionInstallResult.failed(ExpansionFailure.badResponse);
    }
    final ExpansionFetch fetched;
    try {
      fetched = await (_fetcher ?? _httpFetch)(url);
    } catch (_) {
      return const ExpansionInstallResult.failed(ExpansionFailure.unreachable);
    }
    if (fetched.statusCode != 200 || fetched.body.isEmpty) {
      return const ExpansionInstallResult.failed(ExpansionFailure.badResponse);
    }
    return installArchive(fetched.body, packName: packName);
  }

  Future<ExpansionInstallResult> installArchive(
    List<int> bytes, {
    required String packName,
  }) async {
    if (!_usableName(packName)) {
      return const ExpansionInstallResult.failed(ExpansionFailure.unusableName);
    }
    if (bytes.length > maxBytes) {
      return const ExpansionInstallResult.failed(ExpansionFailure.tooLarge);
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return const ExpansionInstallResult.failed(ExpansionFailure.notAZip);
    }

    final files = <String, List<int>>{};
    var total = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll('\\', '/');
      if (!_safeEntry(name)) {
        return const ExpansionInstallResult.failed(
          ExpansionFailure.unsafeArchive,
        );
      }
      final content = entry.content;
      total += content.length;
      if (total > maxBytes) {
        return const ExpansionInstallResult.failed(ExpansionFailure.tooLarge);
      }
      files[name] = content;
    }

    final manifestBytes = files['manifest.json'];
    if (manifestBytes == null) {
      return const ExpansionInstallResult.failed(ExpansionFailure.notAZip);
    }
    try {
      final decoded = jsonDecode(utf8.decode(manifestBytes));
      if (decoded is! Map && decoded is! List) {
        return const ExpansionInstallResult.failed(ExpansionFailure.notAZip);
      }
    } catch (_) {
      return const ExpansionInstallResult.failed(ExpansionFailure.notAZip);
    }

    final root = await _documentsRoot();
    final packDir = Directory(_join(_join(root, 'expansions'), packName));
    final staging = Directory('${packDir.path}.partial');
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    staging.createSync(recursive: true);
    try {
      for (final item in files.entries) {
        final file = File(_join(staging.path, item.key));
        await file.writeAsBytes(item.value, flush: true);
      }
      if (packDir.existsSync()) packDir.deleteSync(recursive: true);
      staging.renameSync(packDir.path);
    } catch (_) {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
      return const ExpansionInstallResult.failed(ExpansionFailure.unreachable);
    }

    final tracks = await _tracksIn(packDir, packName);
    return ExpansionInstallResult.installed(tracks.length);
  }

  /// Bundled seasons first, then every pack already stored on this device.
  Future<List<AttuneTrack>> loadTracks() async {
    final tracks = bundledAttuneTracks();
    final root = await _documentsRoot();
    final expansions = Directory(_join(root, 'expansions'));
    if (!expansions.existsSync()) return tracks;
    final packs = expansions.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final pack in packs) {
      final name = pack.path.split('/').last;
      if (name.endsWith('.partial') || !_usableName(name)) continue;
      tracks.addAll(await _tracksIn(pack, name));
    }
    return tracks;
  }

  Future<List<AttuneTrack>> _tracksIn(Directory pack, String packName) async {
    final manifestFile = File(_join(pack.path, 'manifest.json'));
    if (!manifestFile.existsSync()) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(await manifestFile.readAsString());
    } catch (_) {
      return const [];
    }
    final rows = _manifestRows(decoded);
    if (rows == null) return const [];
    final tracks = <AttuneTrack>[];
    for (final row in rows) {
      final built = _trackFromRow(pack.path, packName, row);
      if (built != null) tracks.add(built);
    }
    return tracks;
  }

  AttuneTrack? _trackFromRow(
    String packPath,
    String packName,
    ({String name, Object? entry}) row,
  ) {
    final name = row.name;
    if (!name.toLowerCase().endsWith('.ogg') || !_safeEntry(name)) return null;
    final audio = File(_join(packPath, name));
    if (!audio.existsSync()) return null;
    final entry = row.entry;
    var keyName = '';
    var bpm = 0;
    var composer = '';
    var title = '';
    var movement = '';
    if (entry is Map) {
      keyName = _stringField(entry, 'key');
      composer = _stringField(entry, 'composer');
      title = _stringField(entry, 'title');
      movement = _stringField(entry, 'movement');
      bpm = _bpmField(entry['bpm']);
    }
    return AttuneTrack(
      id: '$packName/$name',
      label: title.isEmpty ? name : title,
      packName: packName,
      keyName: keyName,
      bpm: bpm,
      composer: composer,
      title: title,
      movement: movement,
      filePath: audio.path,
    );
  }

  Future<String> _documentsRoot() async {
    final injected = _rootPath;
    if (injected != null) return injected;
    final documents = await getApplicationDocumentsDirectory();
    return documents.path;
  }

  static Future<ExpansionFetch> _httpFetch(Uri url) async {
    final client = http.Client();
    try {
      final response =
          await client.get(url).timeout(const Duration(minutes: 3));
      return ExpansionFetch(response.statusCode, response.bodyBytes);
    } finally {
      client.close();
    }
  }
}

List<({String name, Object? entry})>? _manifestRows(Object? decoded) {
  if (decoded is List) {
    final rows = <({String name, Object? entry})>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final file = item['file'];
      if (file is! String || file.isEmpty) continue;
      rows.add((name: file, entry: item));
    }
    return rows;
  }
  if (decoded is! Map) return null;
  final names = decoded.keys.map((key) => key.toString()).toList()..sort();
  return [
    for (final name in names) (name: name, entry: decoded[name]),
  ];
}

String _stringField(Map<dynamic, dynamic> entry, String field) {
  final value = entry[field];
  return value is String ? value : '';
}

int _bpmField(Object? raw) {
  if (raw is int && raw >= 0) return raw;
  if (raw is double && raw >= 0 && raw.isFinite) return raw.round();
  return 0;
}

bool _usableName(String name) {
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(name);
}

bool _safeEntry(String name) {
  if (name.isEmpty || name.contains('/') || name.contains('..')) return false;
  if (name.startsWith('.')) return false;
  return name == 'manifest.json' || name.toLowerCase().endsWith('.ogg');
}

String _join(String dir, String name) {
  if (dir.endsWith('/')) return '$dir$name';
  return '$dir/$name';
}
