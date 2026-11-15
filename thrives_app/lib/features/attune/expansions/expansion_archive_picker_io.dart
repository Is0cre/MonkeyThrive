import 'package:file_selector/file_selector.dart';

import 'expansion_archive_pick.dart';

/// Storage Access Framework on Android. No storage permission is requested.
Future<ExpansionArchivePick?> openExpansionArchive() async {
  const group = XTypeGroup(
    label: 'zip',
    extensions: <String>['zip'],
    mimeTypes: <String>[
      'application/zip',
      'application/x-zip-compressed',
      'application/octet-stream',
    ],
  );
  final file = await openFile(acceptedTypeGroups: <XTypeGroup>[group]);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return ExpansionArchivePick(name: file.name, bytes: bytes);
}
