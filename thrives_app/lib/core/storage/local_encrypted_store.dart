import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small authenticated encrypted store for local-only records.
///
/// This avoids plaintext SharedPreferences values for sensitive modelling data
/// without adding a platform storage dependency. The per-install secret is
/// local to this app install and is removed by Settings -> Clear all data.
class LocalEncryptedStore {
  LocalEncryptedStore._();

  static const _secretKey = 'thrives_local_secret_v1';
  static const _version = 1;

  static Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final secret = await _loadOrCreateSecret(prefs);
    final plain = utf8.encode(jsonEncode(values));
    final nonce = _randomBytes(16);
    final cipher = _xorWithKeystream(plain, secret, nonce);
    final mac = _mac(secret, nonce, cipher);
    final payload = jsonEncode({
      'v': _version,
      'n': base64Encode(nonce),
      'c': base64Encode(cipher),
      'm': base64Encode(mac),
    });
    await prefs.setString(key, payload);
  }

  static Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(key);
    if (payload == null) return [];

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    if (decoded['v'] != _version) return [];

    final secret = await _loadOrCreateSecret(prefs);
    final nonce = base64Decode(decoded['n'] as String);
    final cipher = base64Decode(decoded['c'] as String);
    final expectedMac = base64Decode(decoded['m'] as String);
    final actualMac = _mac(secret, nonce, cipher);
    if (!_constantTimeEquals(expectedMac, actualMac)) {
      throw StateError('Encrypted local data failed integrity check.');
    }

    final plain = _xorWithKeystream(cipher, secret, nonce);
    final list = jsonDecode(utf8.decode(plain)) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<Uint8List> _loadOrCreateSecret(SharedPreferences prefs) async {
    final existing = prefs.getString(_secretKey);
    if (existing != null) return base64Decode(existing);

    final secret = _randomBytes(32);
    await prefs.setString(_secretKey, base64Encode(secret));
    return secret;
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  static Uint8List _xorWithKeystream(
    List<int> input,
    Uint8List secret,
    List<int> nonce,
  ) {
    final out = Uint8List(input.length);
    var offset = 0;
    var counter = 0;
    while (offset < input.length) {
      final block = _keystreamBlock(secret, nonce, counter++);
      for (var i = 0; i < block.length && offset < input.length; i++) {
        out[offset] = input[offset] ^ block[i];
        offset++;
      }
    }
    return out;
  }

  static List<int> _keystreamBlock(
    Uint8List secret,
    List<int> nonce,
    int counter,
  ) {
    final counterBytes = ByteData(8)..setUint64(0, counter);
    return Hmac(sha256, secret)
        .convert([...nonce, ...counterBytes.buffer.asUint8List()]).bytes;
  }

  static Uint8List _mac(
    Uint8List secret,
    List<int> nonce,
    List<int> cipher,
  ) {
    return Uint8List.fromList(
      Hmac(sha256, secret).convert([...nonce, ...cipher]).bytes,
    );
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
