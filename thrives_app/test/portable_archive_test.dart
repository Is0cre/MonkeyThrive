import 'package:flutter_test/flutter_test.dart';
import 'package:monkeythrive/core/storage/local_encrypted_store.dart';
import 'package:monkeythrive/core/storage/passphrase_seal.dart';
import 'package:monkeythrive/core/storage/portable_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const passphrase = 'correct horse';

  test('a sealed copy hides the journal and opens with the passphrase', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': '[{"id":"1","body":"secret journal"}]',
    });

    final token = await PortableArchive.exportSealed(
      passphrase,
      iterations: 1000,
    );

    expect(token.startsWith(PassphraseSeal.prefix), isTrue);
    expect(token.contains('secret journal'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('journal_entries');
    await PortableArchive.importSealed(token, passphrase);

    expect(prefs.getString('journal_entries'), contains('secret journal'));
  });

  test('the wrong passphrase does not open a copy', () async {
    SharedPreferences.setMockInitialValues({});
    final token = await PortableArchive.exportSealed(
      passphrase,
      iterations: 1000,
    );

    expect(
      () => PortableArchive.importSealed(token, 'wrong passphrase'),
      throwsFormatException,
    );
  });

  test('encrypted records survive a restore onto a fresh install secret', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalEncryptedStore.writeJsonList('baseline_feedback_log_v1', [
      {'user_response': 'notReally'},
    ]);

    final token = await PortableArchive.exportSealed(
      passphrase,
      iterations: 1000,
    );
    expect(token.contains('notReally'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('baseline_feedback_log_v1');
    await prefs.remove('thrives_local_secret_v1');

    await PortableArchive.importSealed(token, passphrase);
    final rows =
        await LocalEncryptedStore.readJsonList('baseline_feedback_log_v1');
    expect(rows.single['user_response'], 'notReally');
  });
}
