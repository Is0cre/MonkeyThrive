import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Passphrase-sealed payload.
///
/// AES-256-CBC encrypts the bytes. HMAC-SHA256 covers the IV and ciphertext.
/// The key comes from PBKDF2-HMAC-SHA256. Nothing here contacts a network.
class PassphraseSeal {
  PassphraseSeal._();

  static const prefix = 'MT1.';
  static const productionIterations = 120000;
  static const _minPassphrase = 8;

  static String seal(
    String plaintext,
    String passphrase, {
    int iterations = productionIterations,
  }) {
    _checkPassphrase(passphrase);
    if (iterations < 1000) {
      throw ArgumentError('Iteration count is too low.');
    }

    final salt = _randomBytes(16);
    final derived = _pbkdf2(
      password: utf8.encode(passphrase),
      salt: salt,
      iterations: iterations,
      length: 64,
    );
    final iv = enc.IV(_randomBytes(16));
    final aes = enc.Encrypter(
      enc.AES(enc.Key(derived.sublist(0, 32)), mode: enc.AESMode.cbc),
    );
    final cipher = aes.encrypt(plaintext, iv: iv).bytes;
    final mac = Hmac(sha256, derived.sublist(32)).convert([...iv.bytes, ...cipher]);
    final envelope = jsonEncode({
      'v': 1,
      'alg': 'AES-256-CBC+HMAC-SHA256',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iter': iterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv.bytes),
      'ct': base64Encode(cipher),
      'mac': base64Encode(mac.bytes),
    });
    return '$prefix${base64Encode(utf8.encode(envelope))}';
  }

  static String open(String token, String passphrase) {
    _checkPassphrase(passphrase);
    final trimmed = token.trim();
    if (!trimmed.startsWith(prefix)) {
      throw const FormatException('This is not a MonkeyThrive copy.');
    }

    final Map<String, dynamic> envelope;
    try {
      final raw = utf8.decode(base64Decode(trimmed.substring(prefix.length)));
      envelope = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      throw const FormatException('This copy could not be read.');
    }

    if (envelope['v'] != 1) {
      throw const FormatException('This copy is from a newer version.');
    }
    final iterations = envelope['iter'];
    if (iterations is! int || iterations < 1000 || iterations > 500000) {
      throw const FormatException('This copy could not be read.');
    }

    final salt = base64Decode(envelope['salt'] as String);
    final ivBytes = base64Decode(envelope['iv'] as String);
    final cipher = base64Decode(envelope['ct'] as String);
    final expectedMac = base64Decode(envelope['mac'] as String);
    final derived = _pbkdf2(
      password: utf8.encode(passphrase),
      salt: salt,
      iterations: iterations,
      length: 64,
    );
    final actualMac =
        Hmac(sha256, derived.sublist(32)).convert([...ivBytes, ...cipher]).bytes;
    if (!_constantTimeEquals(expectedMac, actualMac)) {
      throw const FormatException('That passphrase did not open this copy.');
    }

    final aes = enc.Encrypter(
      enc.AES(enc.Key(derived.sublist(0, 32)), mode: enc.AESMode.cbc),
    );
    try {
      return aes.decrypt(enc.Encrypted(cipher), iv: enc.IV(ivBytes));
    } on ArgumentError {
      throw const FormatException('That passphrase did not open this copy.');
    }
  }

  static void _checkPassphrase(String passphrase) {
    if (passphrase.length < _minPassphrase) {
      throw ArgumentError('Use at least $_minPassphrase characters.');
    }
  }

  static Uint8List _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final hmac = Hmac(sha256, password);
    final blocks = (length + 31) ~/ 32;
    final out = BytesBuilder(copy: false);
    for (var i = 1; i <= blocks; i++) {
      final blockIndex = ByteData(4)..setUint32(0, i, Endian.big);
      var u = Uint8List.fromList(
        hmac.convert([...salt, ...blockIndex.buffer.asUint8List()]).bytes,
      );
      final t = Uint8List.fromList(u);
      for (var round = 1; round < iterations; round++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
    }
    return Uint8List.fromList(out.toBytes().sublist(0, length));
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
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
