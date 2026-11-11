import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionEntry {
  final String tool;
  final String category;
  final DateTime timestamp;
  final int durationSeconds;

  SessionEntry({
    required this.tool,
    required this.category,
    required this.timestamp,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'tool': tool,
        'category': category,
        'timestamp': timestamp.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  static SessionEntry fromJson(Map<String, dynamic> j) => SessionEntry(
        tool: j['tool'] as String,
        category: j['category'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        durationSeconds: j['durationSeconds'] as int,
      );
}

class ToleranceEntry {
  final String state; // 'hyper' | 'regulated' | 'hypo'
  final DateTime timestamp;

  ToleranceEntry({required this.state, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'state': state,
        'timestamp': timestamp.toIso8601String(),
      };

  static ToleranceEntry fromJson(Map<String, dynamic> j) => ToleranceEntry(
        state: j['state'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

class SessionLog {
  SessionLog._();

  static const _keySession = 'session_log';
  static const _keyTolerance = 'tolerance_log';
  static const _maxEntries = 200;

  static Future<void> logSession(SessionEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySession);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.add(entry.toJson());
    if (list.length > _maxEntries) {
      list.removeRange(0, list.length - _maxEntries);
    }
    await prefs.setString(_keySession, jsonEncode(list));
  }

  static Future<List<SessionEntry>> getSessionLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySession);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => SessionEntry.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> logTolerance(ToleranceEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTolerance);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.add(entry.toJson());
    if (list.length > _maxEntries) {
      list.removeRange(0, list.length - _maxEntries);
    }
    await prefs.setString(_keyTolerance, jsonEncode(list));
  }

  static Future<List<ToleranceEntry>> getToleranceLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTolerance);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => ToleranceEntry.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
    await prefs.remove(_keyTolerance);
  }
}
