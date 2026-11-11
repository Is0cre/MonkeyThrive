import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single journal entry. Stored locally, never leaves the device.
/// No encryption in v0.1 — AES-256 encryption planned for v0.2.
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

  static Future<List<JournalEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList(); // newest first
  }

  static Future<void> save(JournalEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];

    final idx = list.indexWhere((e) => (e as Map)['id'] == entry.id);
    if (idx >= 0) {
      list[idx] = entry.toJson();
    } else {
      list.add(entry.toJson());
      if (list.length > _maxEntries) {
        list.removeRange(0, list.length - _maxEntries);
      }
    }
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> delete(String id) async {
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
