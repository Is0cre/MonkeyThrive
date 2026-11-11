import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('app.monkeythrive/crisis_dial');

/// Opens a validated tel: or sms: link in the platform handler.
///
/// Android uses ACTION_DIAL / ACTION_SENDTO, which do not need the internet
/// permission and do not place the call or send the text by themselves.
/// Desktop development builds hand the same link to the OS handler.
Future<bool> openLocalUri(Uri uri) async {
  final value = uri.toString();
  if (Platform.isAndroid) {
    try {
      final opened = await _channel.invokeMethod<bool>('open', {'uri': value});
      return opened ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  try {
    final result = await Process.run('xdg-open', [value]);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
