/// Where the vault record lives. The PIN itself is never stored.
abstract class VaultSecretBox {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// In-memory box for tests. It does not touch the platform plugin.
class MemoryVaultSecretBox implements VaultSecretBox {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
