import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_helper.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

class SessionManager {
  static const String _keyPhpSessionId = 'php_sess_id';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyRole = 'user_role';
  static const String _keyLevel = 'user_level';
  static const String _keyDeviceId = 'device_id';

  Future<void> saveSession({
    required String phpSessionId,
    required int userId,
    required String username,
    required String role,
    required String level,
  }) async {
    await SecureStorageHelper.write(_keyPhpSessionId, phpSessionId);
    await SecureStorageHelper.write(_keyUserId, userId.toString());
    await SecureStorageHelper.write(_keyUsername, username);
    await SecureStorageHelper.write(_keyRole, role);
    await SecureStorageHelper.write(_keyLevel, level);
  }

  Future<void> savePhpSessionId(String value) async {
    await SecureStorageHelper.write(_keyPhpSessionId, value);
  }

  Future<String?> getPhpSessionId() async {
    return await SecureStorageHelper.read(_keyPhpSessionId);
  }

  Future<int?> getUserId() async {
    final val = await SecureStorageHelper.read(_keyUserId);
    if (val != null) {
      return int.tryParse(val);
    }
    return null;
  }

  Future<String?> getUsername() async {
    return await SecureStorageHelper.read(_keyUsername);
  }

  Future<String?> getRole() async {
    return await SecureStorageHelper.read(_keyRole);
  }

  Future<String?> getLevel() async {
    return await SecureStorageHelper.read(_keyLevel);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await SecureStorageHelper.write(_keyDeviceId, deviceId);
  }

  Future<String?> getDeviceId() async {
    return await SecureStorageHelper.read(_keyDeviceId);
  }

  Future<void> clearSession() async {
    await SecureStorageHelper.delete(_keyPhpSessionId);
    await SecureStorageHelper.delete(_keyUserId);
    await SecureStorageHelper.delete(_keyUsername);
    await SecureStorageHelper.delete(_keyRole);
    await SecureStorageHelper.delete(_keyLevel);
  }
  
  Future<void> clearAll() async {
    await SecureStorageHelper.clearAll();
  }
}

class SessionData {
  final int? userId;
  final String? username;
  final String? role;
  final String? level;
  final String? deviceId;

  SessionData({
    this.userId,
    this.username,
    this.role,
    this.level,
    this.deviceId,
  });
}

final sessionDataProvider = FutureProvider<SessionData>((ref) async {
  final sessionManager = ref.read(sessionManagerProvider);
  final userId = await sessionManager.getUserId();
  final username = await sessionManager.getUsername();
  final role = await sessionManager.getRole();
  final level = await sessionManager.getLevel();
  final deviceId = await sessionManager.getDeviceId();
  return SessionData(
    userId: userId,
    username: username,
    role: role,
    level: level,
    deviceId: deviceId,
  );
});
