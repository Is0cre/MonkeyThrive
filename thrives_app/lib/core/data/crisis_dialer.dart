import 'crisis_dialer_io.dart'
    if (dart.library.js_interop) 'crisis_dialer_web.dart' as platform_dialer;

/// Opens the device phone or messages app for a crisis contact.
///
/// Only `tel:` and `sms:` links are accepted. A network URL is refused before
/// any platform code runs, so this path cannot fetch a page or send the
/// selected country anywhere.
class CrisisDialer {
  const CrisisDialer({this.launch});

  /// Test seam. Production leaves this null and uses the platform handler.
  final Future<bool> Function(Uri uri)? launch;

  Future<bool> open(Uri uri) {
    validateCrisisUri(uri);
    final override = launch;
    if (override != null) return override(uri);
    return platform_dialer.openLocalUri(uri);
  }
}

/// Throws unless [uri] is a phone or text link with no host.
void validateCrisisUri(Uri uri) {
  final rendered = uri.toString();
  if (rendered.contains('://') || uri.hasAuthority || uri.host.isNotEmpty) {
    throw ArgumentError.value(
      rendered,
      'uri',
      'Crisis links cannot be network URLs.',
    );
  }
  if (uri.userInfo.isNotEmpty || uri.fragment.isNotEmpty) {
    throw ArgumentError.value(
      rendered,
      'uri',
      'Crisis links cannot carry extra routing data.',
    );
  }

  if (uri.scheme == 'tel') {
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(uri.path) || uri.query.isNotEmpty) {
      throw ArgumentError.value(
        rendered,
        'uri',
        'A phone link can only contain the number.',
      );
    }
    return;
  }

  if (uri.scheme == 'sms') {
    final body = uri.queryParameters['body'];
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(uri.path) ||
        body == null ||
        body.isEmpty ||
        body.length > 160 ||
        uri.queryParameters.length != 1) {
      throw ArgumentError.value(
        rendered,
        'uri',
        'A text link can only contain the number and the message.',
      );
    }
    return;
  }

  throw ArgumentError.value(
    rendered,
    'uri',
    'Only phone and text links can be opened from crisis support.',
  );
}
