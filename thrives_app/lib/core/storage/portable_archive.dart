import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_encrypted_store.dart';
import 'passphrase_seal.dart';
import 'prefs_service.dart';

/// A local copy of history and preferences, sealed with a passphrase.
///
/// The device secret stays on this install. Encrypted records are opened
/// here and sealed again inside the copy, so another device can restore
/// them without that secret. The copy is not uploaded.
class PortableArchive {
  PortableArchive._();

  static const format = 'monkeythrive-local-copy';

  static const plainKeys = <String>[
    'journal_entries',
    'hrv_readings',
    'session_log',
    'tolerance_log',
    'safe_place_description',
    'onboarding_done',
    'wot_state',
    'wot_date',
    'profile_primary_goal',
    'profile_familiarity',
    'profile_has_wearable',
    'profile_work_style',
    'profile_reduce_motion',
    'profile_reduce_audio',
    'profile_reduce_vibration',
    'profile_has_therapist',
    'crisis_directory_country',
    PrefsService.trustedPeopleKey,
    'appearance_accent',
    'appearance_contrast',
    'tier2_unlocked',
    'tier3_unlocked',
  ];

  static const encryptedKeys = <String>[
    'baseline_feedback_log_v1',
    'baseline_prompt_state_v1',
  ];

  static Future<String> exportSealed(
    String passphrase, {
    int iterations = PassphraseSeal.productionIterations,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final plain = <String, dynamic>{};
    for (final key in plainKeys) {
      final value = prefs.get(key);
      if (value == null) continue;
      plain[key] = _encodeValue(value);
    }

    final opened = <String, dynamic>{};
    for (final key in encryptedKeys) {
      if (prefs.getString(key) == null) continue;
      opened[key] = await LocalEncryptedStore.readJsonList(key);
    }

    final document = jsonEncode({
      'format': format,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'plain': plain,
      'records': opened,
    });
    return PassphraseSeal.seal(document, passphrase, iterations: iterations);
  }

  static Future<void> importSealed(String token, String passphrase) async {
    final document = jsonDecode(PassphraseSeal.open(token, passphrase));
    if (document is! Map<String, dynamic> || document['format'] != format) {
      throw const FormatException('This is not a MonkeyThrive copy.');
    }
    if (document['version'] != 1) {
      throw const FormatException('This copy is from a newer version.');
    }

    final plain = document['plain'];
    final records = document['records'];
    if (plain is! Map<String, dynamic> || records is! Map<String, dynamic>) {
      throw const FormatException('This copy could not be read.');
    }

    final prefs = await SharedPreferences.getInstance();
    for (final key in plainKeys) {
      await prefs.remove(key);
    }
    for (final entry in plain.entries) {
      if (!plainKeys.contains(entry.key)) continue;
      final encoded = entry.value;
      if (encoded is! Map) continue;
      await _writeValue(prefs, entry.key, Map<String, dynamic>.from(encoded));
    }

    for (final key in encryptedKeys) {
      final raw = records[key];
      if (raw is! List) {
        if (prefs.getString(key) != null) {
          await LocalEncryptedStore.writeJsonList(key, const []);
        }
        continue;
      }
      final rows = <Map<String, dynamic>>[];
      for (final row in raw) {
        if (row is Map) rows.add(Map<String, dynamic>.from(row));
      }
      await LocalEncryptedStore.writeJsonList(key, rows);
    }
  }

  static Map<String, dynamic> _encodeValue(Object value) {
    if (value is bool) return {'t': 'bool', 'v': value};
    if (value is int) return {'t': 'int', 'v': value};
    if (value is double) return {'t': 'double', 'v': value};
    if (value is String) return {'t': 'string', 'v': value};
    throw FormatException(
        'Cannot copy a preference of type ${value.runtimeType}.');
  }

  static Future<void> _writeValue(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic> encoded,
  ) async {
    final type = encoded['t'];
    final value = encoded['v'];
    switch (type) {
      case 'bool':
        if (value is bool) await prefs.setBool(key, value);
      case 'int':
        if (value is int) await prefs.setInt(key, value);
      case 'double':
        if (value is num) await prefs.setDouble(key, value.toDouble());
      case 'string':
        if (value is String) await prefs.setString(key, value);
      default:
        throw const FormatException('This copy could not be read.');
    }
  }
}
