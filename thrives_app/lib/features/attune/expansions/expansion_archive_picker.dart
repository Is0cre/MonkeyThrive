import 'expansion_archive_pick.dart';
import 'expansion_archive_picker_io.dart'
    if (dart.library.js_interop) 'expansion_archive_picker_web.dart' as impl;

/// Asks the system file dialog for one zip. Nothing is downloaded.
///
/// The web build has no expansion directory, so this returns null there.
Future<ExpansionArchivePick?> pickExpansionArchive() {
  return impl.openExpansionArchive();
}
