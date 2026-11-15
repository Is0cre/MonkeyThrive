import 'attune_track.dart';
import 'expansion_pack_io.dart'
    if (dart.library.js_interop) 'expansion_pack_web.dart';

/// Installs an expansion zip and lists every Attune mask on this device.
///
/// Built-in seasons and extracted packs are returned together. After a pack
/// is on disk, [loadTracks] does not use the network.
class ExpansionPackService {
  ExpansionPackService({
    ExpansionFetcher? fetcher,
    String? rootPath,
    int maxBytes = 200 * 1024 * 1024,
  }) : _store = ExpansionStore(
          fetcher: fetcher,
          rootPath: rootPath,
          maxBytes: maxBytes,
        );

  final ExpansionStore _store;

  /// GET [url] and extract it under documents/expansions/[packName].
  ///
  /// Network failure, a missing permission, and a bad archive do not throw.
  /// The previous copy of the pack is left in place when install fails
  /// before the new files are ready.
  Future<ExpansionInstallResult> downloadPack({
    required Uri url,
    required String packName,
  }) {
    return _store.downloadPack(url: url, packName: packName);
  }

  /// Extract a zip that is already on this machine. No request is made.
  Future<ExpansionInstallResult> installArchive(
    List<int> bytes, {
    required String packName,
  }) {
    return _store.installArchive(bytes, packName: packName);
  }

  /// Bundled seasons, then local packs, for an audio player that stays offline.
  Future<List<AttuneTrack>> loadTracks() => _store.loadTracks();
}
