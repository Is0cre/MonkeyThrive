import 'dart:js_interop';

@JS('location')
external _BrowserLocation get _browserLocation;

extension type _BrowserLocation._(JSObject _) implements JSObject {
  external set href(JSString href);
}

/// Assigns a tel: or sms: link on the page. The browser hands it to the
/// device dialer or messages app. The link is not loaded as a document.
Future<bool> openLocalUri(Uri uri) async {
  _browserLocation.href = uri.toString().toJS;
  return true;
}
