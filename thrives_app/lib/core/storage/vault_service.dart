import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vault_secret_box.dart';
import 'vault_secret_box_io.dart'
    if (dart.library.js_interop) 'vault_secret_box_web.dart' as platform_box;

/// Thrown when journal text is sealed and the vault is locked.
class VaultLockedException implements Exception {
  const VaultLockedException();
}

/// Reflect key and the journal data key.
///
/// The PIN is stretched with PBKDF2-HMAC-SHA256. Only a verifier and a
/// wrapped random data key are written to secure storage. Journal text is
/// AES-256-CBC, then HMAC-SHA256 over the IV and ciphertext. The PIN is not
/// kept after unlock.
class VaultService extends ChangeNotifier {
  VaultService._();

  static final VaultService instance = VaultService._();

  static const storageKey = 'vault_key_v1';
  static const textPrefix = 'MTV1.';
  static const productionIterations = 120000;
  static const lockAfter = Duration(minutes: 5);

  VaultSecretBox _box = platform_box.createSecureVaultSecretBox();
  int _iterations = productionIterations;
  DateTime Function() _now = DateTime.now;

  bool _ready = false;
  bool isUnlocked = false;
  bool storageBroken = false;
  Map<String, dynamic>? _record;
  Uint8List? _dataKey;

  DateTime? _pausedAt;
  DateTime _lastActivity = DateTime.now();
  Timer? _idle;
  int _failures = 0;
  DateTime? _nextTry;
  Future<void>? _loadFuture;

  bool get isReady => _ready;
  bool get isProtected => _record != null;

  /// Test hook. Uses a memory box and a short KDF.
  void debugReset(
    VaultSecretBox box, {
    int iterations = 1000,
    DateTime Function()? now,
  }) {
    _idle?.cancel();
    _forgetKey();
    _box = box;
    _iterations = iterations;
    if (now != null) _now = now;
    _record = null;
    _ready = true;
    _loadFuture = Future<void>.value();
    isUnlocked = false;
    storageBroken = false;
    _pausedAt = null;
    _failures = 0;
    _nextTry = null;
    _lastActivity = _now();
    notifyListeners();
  }

  Future<void> ensureLoaded() {
    if (_ready) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _box.read(storageKey);
      if (raw == null) {
        _record = null;
      } else {
        final decoded = jsonDecode(raw);
        _record = decoded is Map<String, dynamic> ? decoded : null;
      }
      storageBroken = false;
    } on MissingPluginException {
      // Tests, and any build where the plugin is not registered.
      _record = null;
      storageBroken = false;
    } on FlutterError {
      // The binding is not up yet. There is no vault to protect.
      _record = null;
      storageBroken = false;
    } catch (_) {
      _record = null;
      storageBroken = true;
    }
    _ready = true;
    notifyListeners();
  }

  Future<bool> createPin(String pin) async {
    if (storageBroken || _record != null || !_digits(pin)) return false;
    final salt = _randomBytes(16);
    final dataKey = _randomBytes(32);
    final derived = await _derive(
      password: utf8.encode(pin),
      salt: salt,
      iterations: _iterations,
      length: 64,
    );
    final wrapped = _sealBytes(base64Encode(dataKey), derived);
    final check = Hmac(sha256, derived.sublist(32))
        .convert(utf8.encode('monkeythrive-vault-check'))
        .bytes;
    final record = <String, dynamic>{
      'v': 1,
      'iter': _iterations,
      'salt': base64Encode(salt),
      'check': base64Encode(check),
      'iv': wrapped.iv,
      'ct': wrapped.ct,
      'mac': wrapped.mac,
    };
    await _box.write(storageKey, jsonEncode(record));
    _record = record;
    _dataKey = dataKey;
    isUnlocked = true;
    _failures = 0;
    _nextTry = null;
    _lastActivity = _now();
    _armIdle();
    notifyListeners();
    return true;
  }

  Future<bool> unlock(String pin) async {
    final record = _record;
    if (record == null || !_digits(pin)) return false;
    final wait = _nextTry;
    if (wait != null && _now().isBefore(wait)) return false;

    final iterations = record['iter'];
    if (iterations is! int || iterations < 1000 || iterations > 500000) {
      return false;
    }
    final derived = await _derive(
      password: utf8.encode(pin),
      salt: base64Decode(record['salt'] as String),
      iterations: iterations,
      length: 64,
    );
    final expected = base64Decode(record['check'] as String);
    final actual = Hmac(sha256, derived.sublist(32))
        .convert(utf8.encode('monkeythrive-vault-check'))
        .bytes;
    if (!_constantTimeEquals(expected, actual)) {
      _noteFailure();
      return false;
    }
    try {
      final opened = _openBytes(
        iv: record['iv'] as String,
        ct: record['ct'] as String,
        mac: record['mac'] as String,
        derived: derived,
      );
      _dataKey = base64Decode(opened);
    } on FormatException {
      _noteFailure();
      return false;
    }
    isUnlocked = true;
    _failures = 0;
    _nextTry = null;
    _lastActivity = _now();
    _armIdle();
    notifyListeners();
    return true;
  }

  void lock() {
    _idle?.cancel();
    _idle = null;
    _forgetKey();
    if (!isUnlocked && _pausedAt == null) {
      isUnlocked = false;
      return;
    }
    isUnlocked = false;
    _pausedAt = null;
    notifyListeners();
  }

  Future<void> wipe() async {
    try {
      await _box.delete(storageKey);
    } on MissingPluginException {
      // Nothing was stored.
    }
    _record = null;
    storageBroken = false;
    lock();
    notifyListeners();
  }

  /// AES-256 helper. Uses the unlocked data key, which was unwrapped from
  /// [pin] by [unlock] or [createPin].
  String encryptText(String plaintext) => sealText(plaintext);

  /// Opens a value from [encryptText]. Plain legacy text is returned as-is.
  String decryptText(String stored) => openText(stored);

  /// Derives the key from [pin] again and seals [plaintext].
  Future<String> encryptJournalText(String plaintext, String pin) async {
    final key = await _dataKeyForPin(pin);
    if (key == null) {
      throw const FormatException('That key did not open this vault.');
    }
    final sealed = _sealBytes(plaintext, _expand(key));
    _wipe(key);
    return '$textPrefix${base64Encode(utf8.encode(jsonEncode({
          'v': 1,
          'iv': sealed.iv,
          'ct': sealed.ct,
          'mac': sealed.mac,
        })))}';
  }

  /// Opens text sealed by [encryptJournalText].
  Future<String> decryptJournalText(String stored, String pin) async {
    if (!stored.startsWith(textPrefix)) return stored;
    final key = await _dataKeyForPin(pin);
    if (key == null) {
      throw const FormatException('That key did not open this vault.');
    }
    try {
      return _openPrefixed(stored, key);
    } finally {
      _wipe(key);
    }
  }

  String sealText(String plaintext) {
    final key = _dataKey;
    if (key == null) throw const VaultLockedException();
    final sealed = _sealBytes(plaintext, _expand(key));
    return '$textPrefix${base64Encode(utf8.encode(jsonEncode({
          'v': 1,
          'iv': sealed.iv,
          'ct': sealed.ct,
          'mac': sealed.mac,
        })))}';
  }

  String openText(String stored) {
    if (!stored.startsWith(textPrefix)) return stored;
    final key = _dataKey;
    if (key == null) throw const VaultLockedException();
    return _openPrefixed(stored, key);
  }

  void onBackgrounded() {
    if (!isUnlocked) return;
    _pausedAt ??= _now();
  }

  void onResumed() {
    final paused = _pausedAt;
    _pausedAt = null;
    if (!isUnlocked || paused == null) return;
    if (_now().difference(paused) >= lockAfter) {
      lock();
    }
  }

  void onUserActivity() {
    if (!isUnlocked) return;
    _lastActivity = _now();
    _armIdle();
  }

  Future<Uint8List?> _dataKeyForPin(String pin) async {
    await ensureLoaded();
    final record = _record;
    if (record == null || !_digits(pin)) return null;
    final iterations = record['iter'];
    if (iterations is! int) return null;
    final derived = await _derive(
      password: utf8.encode(pin),
      salt: base64Decode(record['salt'] as String),
      iterations: iterations,
      length: 64,
    );
    final expected = base64Decode(record['check'] as String);
    final actual = Hmac(sha256, derived.sublist(32))
        .convert(utf8.encode('monkeythrive-vault-check'))
        .bytes;
    if (!_constantTimeEquals(expected, actual)) return null;
    final opened = _openBytes(
      iv: record['iv'] as String,
      ct: record['ct'] as String,
      mac: record['mac'] as String,
      derived: derived,
    );
    return base64Decode(opened);
  }

  String _openPrefixed(String stored, Uint8List dataKey) {
    final raw = utf8.decode(base64Decode(stored.substring(textPrefix.length)));
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    return _openBytes(
      iv: envelope['iv'] as String,
      ct: envelope['ct'] as String,
      mac: envelope['mac'] as String,
      derived: _expand(dataKey),
    );
  }

  void _armIdle() {
    _idle?.cancel();
    if (!isUnlocked) return;
    final left = lockAfter - _now().difference(_lastActivity);
    if (left <= Duration.zero) {
      lock();
      return;
    }
    _idle = Timer(left, () {
      if (!isUnlocked) return;
      if (_now().difference(_lastActivity) >= lockAfter) {
        lock();
      } else {
        _armIdle();
      }
    });
  }

  void _noteFailure() {
    _failures += 1;
    if (_failures >= 5) {
      _nextTry = _now().add(const Duration(seconds: 30));
      _failures = 0;
    }
  }

  void _forgetKey() {
    final key = _dataKey;
    if (key != null) _wipe(key);
    _dataKey = null;
  }

  void _wipe(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  Future<Uint8List> _derive({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    if (iterations < productionIterations) {
      return Future<Uint8List>.value(
        _pbkdf2(
          password: password,
          salt: salt,
          iterations: iterations,
          length: length,
        ),
      );
    }
    return compute(
      vaultPbkdf2Job,
      VaultPbkdf2Job(
        password: Uint8List.fromList(password),
        salt: Uint8List.fromList(salt),
        iterations: iterations,
        length: length,
      ),
    );
  }

  bool _digits(String pin) => RegExp(r'^\d{6,12}$').hasMatch(pin);

  /// 32-byte AES key plus 32-byte MAC key from the stored data key.
  Uint8List _expand(Uint8List dataKey) {
    final mac = Hmac(sha256, dataKey).convert(utf8.encode('vault-mac')).bytes;
    return Uint8List.fromList([...dataKey, ...mac]);
  }

  _Sealed _sealBytes(String plaintext, Uint8List derived64) {
    final iv = enc.IV(_randomBytes(16));
    final aes = enc.Encrypter(
      enc.AES(enc.Key(derived64.sublist(0, 32)), mode: enc.AESMode.cbc),
    );
    final cipher = aes.encrypt(plaintext, iv: iv).bytes;
    final mac =
        Hmac(sha256, derived64.sublist(32)).convert([...iv.bytes, ...cipher]);
    return _Sealed(
      base64Encode(iv.bytes),
      base64Encode(cipher),
      base64Encode(mac.bytes),
    );
  }

  String _openBytes({
    required String iv,
    required String ct,
    required String mac,
    required Uint8List derived,
  }) {
    final ivBytes = base64Decode(iv);
    final cipher = base64Decode(ct);
    final expectedMac = base64Decode(mac);
    final actualMac = Hmac(sha256, derived.sublist(32))
        .convert([...ivBytes, ...cipher]).bytes;
    if (!_constantTimeEquals(expectedMac, actualMac)) {
      throw const FormatException('That key did not open this vault.');
    }
    final aes = enc.Encrypter(
      enc.AES(enc.Key(derived.sublist(0, 32)), mode: enc.AESMode.cbc),
    );
    try {
      return aes.decrypt(enc.Encrypted(cipher), iv: enc.IV(ivBytes));
    } on ArgumentError {
      throw const FormatException('That key did not open this vault.');
    }
  }

  Uint8List _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    return _pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: iterations,
      length: length,
    );
  }

  Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class _Sealed {
  final String iv;
  final String ct;
  final String mac;
  const _Sealed(this.iv, this.ct, this.mac);
}

/// Sent to a background isolate for the production iteration count.
class VaultPbkdf2Job {
  final Uint8List password;
  final Uint8List salt;
  final int iterations;
  final int length;

  const VaultPbkdf2Job({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.length,
  });
}

Uint8List vaultPbkdf2Job(VaultPbkdf2Job job) {
  return _pbkdf2HmacSha256(
    password: job.password,
    salt: job.salt,
    iterations: job.iterations,
    length: job.length,
  );
}

Uint8List _pbkdf2HmacSha256({
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
