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
  static const String _keyHotelId = 'hotel_id';
  static const String _keyHotelName = 'hotel_name';
  static const String _keyFullName = 'full_name';
  static const String _keyEmployeeId = 'employee_id';
  static const String _keyProfilePhoto = 'profile_photo';
  static const String _keyEmail = 'email';
  static const String _keyPhone = 'phone';
  static const String _keyStatus = 'status';

  Future<void> saveSession({
    required String phpSessionId,
    required int userId,
    required String username,
    required String role,
    required String level,
    required String hotelId,
    required String hotelName,
    required String fullName,
    required String employeeId,
    required String profilePhoto,
    required String email,
    required String phone,
    required String status,
  }) async {
    await SecureStorageHelper.write(_keyPhpSessionId, phpSessionId);
    await SecureStorageHelper.write(_keyUserId, userId.toString());
    await SecureStorageHelper.write(_keyUsername, username);
    await SecureStorageHelper.write(_keyRole, role);
    await SecureStorageHelper.write(_keyLevel, level);
    await SecureStorageHelper.write(_keyHotelId, hotelId);
    await SecureStorageHelper.write(_keyHotelName, hotelName);
    await SecureStorageHelper.write(_keyFullName, fullName);
    await SecureStorageHelper.write(_keyEmployeeId, employeeId);
    await SecureStorageHelper.write(_keyProfilePhoto, profilePhoto);
    await SecureStorageHelper.write(_keyEmail, email);
    await SecureStorageHelper.write(_keyPhone, phone);
    await SecureStorageHelper.write(_keyStatus, status);
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

  Future<String?> getHotelId() async {
    return await SecureStorageHelper.read(_keyHotelId);
  }

  Future<String?> getHotelName() async {
    return await SecureStorageHelper.read(_keyHotelName);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await SecureStorageHelper.write(_keyDeviceId, deviceId);
  }

  Future<String?> getDeviceId() async {
    return await SecureStorageHelper.read(_keyDeviceId);
  }

  Future<String?> getFullName() async {
    return await SecureStorageHelper.read(_keyFullName);
  }

  Future<String?> getEmployeeId() async {
    return await SecureStorageHelper.read(_keyEmployeeId);
  }

  Future<String?> getProfilePhoto() async {
    return await SecureStorageHelper.read(_keyProfilePhoto);
  }

  Future<String?> getEmail() async {
    return await SecureStorageHelper.read(_keyEmail);
  }

  Future<String?> getPhone() async {
    return await SecureStorageHelper.read(_keyPhone);
  }

  Future<String?> getStatus() async {
    return await SecureStorageHelper.read(_keyStatus);
  }

  /// Memperbarui hanya field foto profil di secure storage tanpa mengubah session lainnya.
  Future<void> saveProfilePhoto(String profilePhoto) async {
    await SecureStorageHelper.write(_keyProfilePhoto, profilePhoto);
  }

  /// Memperbarui field profil (nama, email, HP) tanpa menyentuh sesi lainnya.
  Future<void> saveProfileFields({
    String? fullName,
    String? email,
    String? phone,
  }) async {
    if (fullName != null) await SecureStorageHelper.write(_keyFullName, fullName);
    if (email != null) await SecureStorageHelper.write(_keyEmail, email);
    if (phone != null) await SecureStorageHelper.write(_keyPhone, phone);
  }

  Future<void> clearSession() async {
    await SecureStorageHelper.delete(_keyPhpSessionId);
    await SecureStorageHelper.delete(_keyUserId);
    await SecureStorageHelper.delete(_keyUsername);
    await SecureStorageHelper.delete(_keyRole);
    await SecureStorageHelper.delete(_keyLevel);
    await SecureStorageHelper.delete(_keyHotelId);
    await SecureStorageHelper.delete(_keyHotelName);
    await SecureStorageHelper.delete(_keyFullName);
    await SecureStorageHelper.delete(_keyEmployeeId);
    await SecureStorageHelper.delete(_keyProfilePhoto);
    await SecureStorageHelper.delete(_keyEmail);
    await SecureStorageHelper.delete(_keyPhone);
    await SecureStorageHelper.delete(_keyStatus);
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
  final String? hotelId;
  final String? hotelName;
  final String? fullName;
  final String? employeeId;
  final String? profilePhoto;
  final String? email;
  final String? phone;
  final String? status;

  SessionData({
    this.userId,
    this.username,
    this.role,
    this.level,
    this.deviceId,
    this.hotelId,
    this.hotelName,
    this.fullName,
    this.employeeId,
    this.profilePhoto,
    this.email,
    this.phone,
    this.status,
  });
}

final sessionDataProvider = FutureProvider<SessionData>((ref) async {
  final sessionManager = ref.read(sessionManagerProvider);
  final userId = await sessionManager.getUserId();
  final username = await sessionManager.getUsername();
  final role = await sessionManager.getRole();
  final level = await sessionManager.getLevel();
  final deviceId = await sessionManager.getDeviceId();
  final hotelId = await sessionManager.getHotelId();
  final hotelName = await sessionManager.getHotelName();
  final fullName = await sessionManager.getFullName();
  final employeeId = await sessionManager.getEmployeeId();
  final profilePhoto = await sessionManager.getProfilePhoto();
  final email = await sessionManager.getEmail();
  final phone = await sessionManager.getPhone();
  final status = await sessionManager.getStatus();
  return SessionData(
    userId: userId,
    username: username,
    role: role,
    level: level,
    deviceId: deviceId,
    hotelId: hotelId,
    hotelName: hotelName,
    fullName: fullName,
    employeeId: employeeId,
    profilePhoto: profilePhoto,
    email: email,
    phone: phone,
    status: status,
  );
});
