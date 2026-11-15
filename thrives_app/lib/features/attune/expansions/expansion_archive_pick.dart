/// A zip the person already has on this device.
class ExpansionArchivePick {
  const ExpansionArchivePick({required this.name, required this.bytes});

  /// File name, including `.zip`. The stem becomes the pack directory.
  final String name;
  final List<int> bytes;
}

/// Opens the system file dialog. Tests pass their own function.
typedef ExpansionArchivePicker = Future<ExpansionArchivePick?> Function();

/// Pack directory name from a zip the person picked.
///
/// `satie_expansion.zip` is `satie_expansion`. A name with spaces, a path,
/// or no `.zip` suffix is refused before anything is written.
String? expansionPackNameFromFilename(String filename) {
  final base = filename.replaceAll('\\', '/').split('/').last.trim();
  if (base.length < 5 || !base.toLowerCase().endsWith('.zip')) return null;
  final stem = base.substring(0, base.length - 4);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(stem)) {
    return null;
  }
  return stem;
}
