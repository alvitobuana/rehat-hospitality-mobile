import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Helper untuk menyimpan dan membaca data sensitif (seperti session tokens)
/// secara aman di tingkat sistem operasi (Android Keystore / iOS Keychain).
class SecureStorageHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Menyimpan string value secara aman
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Membaca string value
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Menghapus item berdasarkan key
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Menghapus seluruh data secure storage
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
