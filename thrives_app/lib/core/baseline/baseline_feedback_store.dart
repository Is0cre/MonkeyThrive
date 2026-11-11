import 'baseline_models.dart';
import '../storage/local_encrypted_store.dart';

class BaselineFeedbackStore {
  BaselineFeedbackStore._();

  static const _key = 'baseline_feedback_log_v1';
  static const _maxEntries = 500;

  static Future<void> append(UserFeedback feedback) async {
    final entries = await load();
    entries.add(feedback);
    final trimmed = entries.length > _maxEntries
        ? entries.sublist(entries.length - _maxEntries)
        : entries;
    await LocalEncryptedStore.writeJsonList(
      _key,
      trimmed.map((e) => e.toJson()).toList(),
    );
  }

  static Future<List<UserFeedback>> load() async {
    final raw = await LocalEncryptedStore.readJsonList(_key);
    return raw.map(UserFeedback.fromJson).toList();
  }

  static Future<void> replaceLast(UserFeedback feedback) async {
    final entries = await load();
    if (entries.isEmpty) {
      entries.add(feedback);
    } else {
      entries[entries.length - 1] = feedback;
    }
    await LocalEncryptedStore.writeJsonList(
      _key,
      entries.map((e) => e.toJson()).toList(),
    );
  }
}
