import 'attune_track.dart';

/// The web app has no expansion directory and does not fetch packs.
class ExpansionStore {
  ExpansionStore({
    ExpansionFetcher? fetcher,
    String? rootPath,
    int maxBytes = 200 * 1024 * 1024,
  });

  Future<ExpansionInstallResult> downloadPack({
    required Uri url,
    required String packName,
  }) async {
    return const ExpansionInstallResult.failed(ExpansionFailure.unavailable);
  }

  Future<ExpansionInstallResult> installArchive(
    List<int> bytes, {
    required String packName,
  }) async {
    return const ExpansionInstallResult.failed(ExpansionFailure.unavailable);
  }

  Future<List<AttuneTrack>> loadTracks() async => bundledAttuneTracks();
}
