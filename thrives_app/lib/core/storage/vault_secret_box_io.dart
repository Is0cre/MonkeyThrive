import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'vault_secret_box.dart';

/// Keystore on Android and the keychain on iOS. The record is a verifier
/// and a wrapped data key, not the PIN. The keychain item stays on this
/// device and is not synced.
VaultSecretBox createSecureVaultSecretBox() => SecureVaultSecretBox();

class SecureVaultSecretBox implements VaultSecretBox {
  SecureVaultSecretBox({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
