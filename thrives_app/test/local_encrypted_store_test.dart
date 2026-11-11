import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monkeythrive/core/storage/local_encrypted_store.dart';

void main() {
  test('LocalEncryptedStore does not persist plaintext JSON', () async {
    SharedPreferences.setMockInitialValues({});

    await LocalEncryptedStore.writeJsonList('baseline_feedback_log_v1', [
      {
        'timestamp': '2026-01-01T12:00:00.000',
        'sensor_snapshot_id': 'snapshot-1',
        'user_response': 'notReally',
      }
    ]);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('baseline_feedback_log_v1')!;

    expect(raw.contains('notReally'), false);
    expect(raw.contains('snapshot-1'), false);

    final decoded =
        await LocalEncryptedStore.readJsonList('baseline_feedback_log_v1');
    expect(decoded.single['user_response'], 'notReally');
  });
}
