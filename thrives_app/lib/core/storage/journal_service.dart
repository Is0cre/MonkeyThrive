import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'vault_service.dart';

/// A single journal entry. Stored locally, never leaves the device.
/// Once a Reflect key exists, the body is AES-256 sealed before it is written.
class JournalEntry {
  final String id;
  final DateTime timestamp;
  final String body;

  const JournalEntry({
    required this.id,
    required this.timestamp,
    required this.body,
  });

  int get wordCount {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  String get preview {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    final first = trimmed.replaceAll('\n', ' ');
    return first.length > 72 ? '${first.substring(0, 72)}…' : first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'body': body,
      };

  static JournalEntry fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        body: j['body'] as String,
      );

  JournalEntry copyWith({String? body}) => JournalEntry(
        id: id,
        timestamp: timestamp,
        body: body ?? this.body,
      );
}

class JournalService {
  JournalService._();

  static const _key = 'journal_entries';
  static const _maxEntries = 500;

  static void _requireOpen(VaultService vault) {
    if (vault.storageBroken || (vault.isProtected && !vault.isUnlocked)) {
      throw const VaultLockedException();
    }
  }

  static Future<List<JournalEntry>> load() async {
    await VaultService.instance.ensureLoaded();
    final vault = VaultService.instance;
    _requireOpen(vault);
    final stored = await _readMaps();
    if (stored == null) return [];

    final opened = <JournalEntry>[];
    var dirty = false;
    for (final map in stored) {
      final body = map['body'];
      if (body is! String) continue;
      if (vault.isUnlocked) {
        if (body.startsWith(VaultService.textPrefix)) {
          map['body'] = vault.openText(body);
        } else {
          dirty = true;
        }
      }
      opened.add(JournalEntry.fromJson(map));
    }
    if (dirty) await _writeEntries(opened);
    return opened.reversed.toList();
  }

  /// Plain JSON for a passphrase-sealed backup. Refuses while the vault
  /// is locked, so a copy does not carry unreadable ciphertext.
  static Future<String> plaintextSnapshot(String stored) async {
    await VaultService.instance.ensureLoaded();
    final vault = VaultService.instance;
    _requireOpen(vault);
    if (!vault.isProtected) return stored;
    final list = jsonDecode(stored) as List<dynamic>;
    final opened = <Map<String, dynamic>>[];
    for (final item in list) {
      final map = Map<String, dynamic>.from(item as Map);
      final body = map['body'];
      if (body is String) map['body'] = vault.openText(body);
      opened.add(map);
    }
    return jsonEncode(opened);
  }

  /// Seals any plaintext bodies. No work until the vault is unlocked.
  static Future<void> resealAll() async {
    final vault = VaultService.instance;
    if (!vault.isUnlocked) return;
    final stored = await _readMaps();
    if (stored == null) return;
    final opened = <JournalEntry>[];
    for (final map in stored) {
      final body = map['body'];
      if (body is String) map['body'] = vault.openText(body);
      opened.add(JournalEntry.fromJson(map));
    }
    await _writeEntries(opened);
  }

  static Future<void> save(JournalEntry entry) async {
    await VaultService.instance.ensureLoaded();
    _requireOpen(VaultService.instance);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];

    final stored = _storedJson(entry);
    final idx = list.indexWhere((e) => (e as Map)['id'] == entry.id);
    if (idx >= 0) {
      list[idx] = stored;
    } else {
      list.add(stored);
      if (list.length > _maxEntries) {
        list.removeRange(0, list.length - _maxEntries);
      }
    }
    await prefs.setString(_key, jsonEncode(list));
  }

  static Map<String, dynamic> _storedJson(JournalEntry entry) {
    final json = entry.toJson();
    final vault = VaultService.instance;
    if (vault.isUnlocked) {
      json['body'] = vault.sealText(entry.body);
    }
    return json;
  }

  static Future<List<Map<String, dynamic>>?> _readMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list) Map<String, dynamic>.from(item as Map),
    ];
  }

  static Future<void> _writeEntries(List<JournalEntry> oldestFirst) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final entry in oldestFirst) _storedJson(entry)]),
    );
  }

  static Future<void> delete(String id) async {
    await VaultService.instance.ensureLoaded();
    _requireOpen(VaultService.instance);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List<dynamic>)
        .where((e) => (e as Map)['id'] != id)
        .toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  static String newId() => DateTime.now().millisecondsSinceEpoch.toString();
}
