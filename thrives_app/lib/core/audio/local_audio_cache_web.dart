import 'dart:typed_data';

Future<Uri> writeWavFile(String safeKey, Uint8List bytes) async {
  return Uri.dataFromBytes(bytes, mimeType: 'audio/wav');
}
