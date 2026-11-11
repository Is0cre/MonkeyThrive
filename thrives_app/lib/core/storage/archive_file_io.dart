import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveTextFile(String name, String contents) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsString(contents, flush: true);
  return file.path;
}
