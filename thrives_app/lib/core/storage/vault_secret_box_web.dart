import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:web/web.dart';

import 'vault_secret_box.dart';

/// Browser stand-in for the OS keystore.
///
/// flutter_secure_storage 9 cannot be imported here: its library pulls in
/// dart:io, which the web build cannot compile. This box matches that
/// plugin's web limit. The wrapper key sits in the same local storage as
/// the record, so a person who can read this browser profile can attempt
/// the PIN offline. Journal text is still sealed with the PIN-wrapped key.
VaultSecretBox createSecureVaultSecretBox() => WebVaultSecretBox();

class WebVaultSecretBox implements VaultSecretBox {
  static const _wrapKey = 'monkeythrive.vault.wrap';
  static const _prefix = 'monkeythrive.vault.box.';

  Storage get _storage => window.localStorage;

  @override
  Future<String?> read(String key) async {
    final stored = _storage.getItem('$_prefix$key');
    if (stored == null) return null;
    return _open(stored, await _aesKey());
  }

  @override
  Future<void> write(String key, String value) async {
    _storage.setItem('$_prefix$key', _seal(value, await _aesKey()));
  }

  @override
  Future<void> delete(String key) async {
    _storage.removeItem('$_prefix$key');
  }

  Future<Uint8List> _aesKey() async {
    final existing = _storage.getItem(_wrapKey);
    if (existing != null) return base64Decode(existing);
    final raw = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    _storage.setItem(_wrapKey, base64Encode(raw));
    return raw;
  }

  String _seal(String plaintext, Uint8List aesKey) {
    final iv = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final aes = enc.Encrypter(
      enc.AES(enc.Key(aesKey), mode: enc.AESMode.cbc),
    );
    final cipher = aes.encrypt(plaintext, iv: enc.IV(iv)).bytes;
    final mac = Hmac(sha256, _macKey(aesKey)).convert([...iv, ...cipher]);
    return '${base64Encode(iv)}.${base64Encode(cipher)}.${base64Encode(mac.bytes)}';
  }

  String _open(String stored, Uint8List aesKey) {
    final parts = stored.split('.');
    if (parts.length != 3) {
      throw const FormatException('The vault record could not be read.');
    }
    final iv = base64Decode(parts[0]);
    final cipher = base64Decode(parts[1]);
    final expected = base64Decode(parts[2]);
    final actual =
        Hmac(sha256, _macKey(aesKey)).convert([...iv, ...cipher]).bytes;
    if (!_same(expected, actual)) {
      throw const FormatException('The vault record could not be read.');
    }
    final aes = enc.Encrypter(
      enc.AES(enc.Key(aesKey), mode: enc.AESMode.cbc),
    );
    return aes.decrypt(enc.Encrypted(cipher), iv: enc.IV(iv));
  }

  Uint8List _macKey(Uint8List aesKey) {
    return Uint8List.fromList(
      Hmac(sha256, aesKey).convert(utf8.encode('vault-storage-mac')).bytes,
    );
  }

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
