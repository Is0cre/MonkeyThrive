import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<Uri> writeWavFile(String safeKey, Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/thrives_audio_$safeKey.wav');
  if (!await file.exists() || await file.length() != bytes.length) {
    await file.writeAsBytes(bytes, flush: false);
  }
  return file.uri;
}
