import 'archive_file_io.dart'
    if (dart.library.js_interop) 'archive_file_web.dart' as archive_file;

/// Writes the sealed copy onto the device. Does not upload it.
Future<String> saveTextFile(String name, String contents) {
  return archive_file.saveTextFile(name, contents);
}
