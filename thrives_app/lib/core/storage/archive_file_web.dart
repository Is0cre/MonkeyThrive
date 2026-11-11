import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<String> saveTextFile(String name, String contents) async {
  final bytes = Uint8List.fromList(utf8.encode(contents));
  final blob = Blob(
    [bytes.toJS].toJS,
    BlobPropertyBag(type: 'text/plain'),
  );
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = name;
  final body = document.body;
  if (body != null) body.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
  return name;
}
