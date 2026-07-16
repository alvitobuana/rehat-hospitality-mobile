import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/device/device_service.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/location/location_service.dart';
import '../../../core/storage/session_manager.dart';
import '../../../services/firebase_messaging_service.dart';
import '../data/auth_repository.dart';
import '../data/device_repository.dart';

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
  deviceBindingRequired,
  locationPermissionRequired,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.username,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.uninitialized);

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final deviceService = ref.read(deviceServiceProvider);
  final locationService = ref.read(locationServiceProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  final fcmService = ref.read(firebaseMessagingServiceProvider);
  final deviceRepository = ref.read(deviceRepositoryProvider);
  return AuthController(authRepo, deviceService, locationService, sessionManager, fcmService, deviceRepository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final DeviceService _deviceService;
  final LocationService _locationService;
  final SessionManager _sessionManager;
  final FirebaseMessagingService _fcmService;
  final DeviceRepository _deviceRepository;
  final Logger _logger = Logger();

  AuthController(
    this._authRepository,
    this._deviceService,
    this._locationService,
    this._sessionManager,
    this._fcmService,
    this._deviceRepository,
  ) : super(AuthState.initial()) {
    // Jalankan cek sesi otomatis saat inisialisasi controller
    checkAutoLogin();

    // Daftarkan listener token refresh untuk sinkronisasi token otomatis ke backend
    _fcmService.setOnTokenRefresh((newToken) async {
      final userId = await _sessionManager.getUserId();
      if (userId != null) {
        await syncFcmToken(isActive: 1);
      }
    });
  }

  /// Cek Auto Login (Dipanggil saat splash screen dibuka)
  Future<void> checkAutoLogin() async {
    try {
      final phpSessionId = await _sessionManager.getPhpSessionId();
      if (phpSessionId == null || phpSessionId.isEmpty) {
        state = AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final sessionData = await _authRepository.checkSession();
      final username = sessionData['username'] as String?;
      final userId = sessionData['user_id'] as int?;
      final role = sessionData['role'] as String? ?? 'staff';
      final level = sessionData['level'] as String? ?? 'Non Admin';
      final hotelId = sessionData['property_id'] as String? ?? '';
      final hotelName = sessionData['property_name'] as String? ?? '';
      final fullName = sessionData['full_name'] as String? ?? '';
      final employeeId = sessionData['employee_id'] as String? ?? '';
      final profilePhoto = sessionData['profile_photo'] as String? ?? '';
      final email = sessionData['email'] as String? ?? '';
      final phone = sessionData['phone'] as String? ?? '';
      final status = sessionData['user_status'] as String? ?? 'ACTIVE';
      
      if (username != null && userId != null) {
        await _sessionManager.saveSession(
          phpSessionId: phpSessionId,
          userId: userId,
          username: username,
          role: role,
          level: level,
          hotelId: hotelId,
          hotelName: hotelName,
          fullName: fullName,
          employeeId: employeeId,
          profilePhoto: profilePhoto,
          email: email,
          phone: phone,
          status: status,
        );
        await _validateAccessChain(username);

        // Sync FCM token if authentication is successful
        if (state.status == AuthStatus.authenticated) {
          await syncFcmToken(isActive: 1);
        }
      } else {
        throw Exception('Data sesi server tidak lengkap.');
      }
    } catch (e) {
      await _sessionManager.clearSession();
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login Karyawan dengan Username & Password
  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final response = await _authRepository.login(username, password);
      final loggedInUser = response['username'] as String? ?? username;
      final userId = response['user_id'] as int?;
      final role = response['role'] as String? ?? 'staff';
      final level = response['level'] as String? ?? 'Non Admin';
      final hotelId = response['property_id'] as String? ?? '';
      final hotelName = response['property_name'] as String? ?? '';
      final fullName = response['full_name'] as String? ?? '';
      final employeeId = response['employee_id'] as String? ?? '';
      final profilePhoto = response['profile_photo'] as String? ?? '';
      final email = response['email'] as String? ?? '';
      final phone = response['phone'] as String? ?? '';
      final status = response['user_status'] as String? ?? 'ACTIVE';

      // Ambil phpSessionId dari response Map (yang diekstrak sinkron di repositori)
      // untuk menghindari race condition penulisan async secure storage
      final phpSessionId = response['phpSessionId'] as String? ?? 
          await _sessionManager.getPhpSessionId() ?? '';
      
      if (userId != null) {
        await _sessionManager.saveSession(
          phpSessionId: phpSessionId,
          userId: userId,
          username: loggedInUser,
          role: role,
          level: level,
          hotelId: hotelId,
          hotelName: hotelName,
          fullName: fullName,
          employeeId: employeeId,
          profilePhoto: profilePhoto,
          email: email,
          phone: phone,
          status: status,
        );
        await _validateAccessChain(loggedInUser);

        // Sync FCM token if authentication is successful
        if (state.status == AuthStatus.authenticated) {
          await syncFcmToken(isActive: 1);
        }
      } else {
        throw AppFailure.local('Gagal mendapatkan ID Karyawan dari server.', 'LOGIN_FAILED');
      }
    } on AppFailure catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Terjadi kesalahan sistem saat masuk: $e',
      );
    }
  }

  /// Mengikat perangkat karyawan (Device Binding)
  Future<void> performDeviceBinding() async {
    if (state.username == null) return;
    
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final device = await _deviceService.getDeviceInfo();
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        throw AppFailure.local('Data sesi lokal tidak valid.', 'SESSION_INVALID');
      }

      final success = await _deviceService.bindDevice(userId.toString(), device);
      
      if (success) {
        // Cek langkah berikutnya (GPS Permission)
        await _validateAccessChain(state.username);

        // Sync FCM token if authentication is successful
        if (state.status == AuthStatus.authenticated) {
          await syncFcmToken(isActive: 1);
        }
      } else {
        throw AppFailure.local('Gagal mendaftarkan binding perangkat ke server.', 'BINDING_FAILED');
      }
    } on AppFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Gagal mengikat perangkat: $e',
      );
    }
  }

  /// Mengevaluasi Izin Lokasi GPS — dipanggil ketika user menekan tombol di GpsPermissionScreen
  Future<void> checkGpsPermission() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      // Cek dulu apakah GPS service aktif
      final gpsEnabled = await _locationService.isLocationEnabled();
      if (!gpsEnabled) {
        // GPS mati — tampilkan error dengan code agar UI bisa bedakan
        state = AuthState(
          status: AuthStatus.locationPermissionRequired,
          username: state.username,
          errorMessage: 'GPS_SERVICE_DISABLED',
        );
        return;
      }

      // GPS aktif — cek status permission saat ini
      final permStatus = await _locationService.checkPermissionStatus();

      if (permStatus == LocationPermissionStatus.permanentlyDenied) {
        // Ditolak permanen — arahkan ke App Settings
        state = AuthState(
          status: AuthStatus.locationPermissionRequired,
          username: state.username,
          errorMessage: 'PERMISSION_PERMANENTLY_DENIED',
        );
        return;
      }

      if (permStatus == LocationPermissionStatus.granted) {
        // Sudah punya permission — lanjut ke dashboard
        state = AuthState(
          status: AuthStatus.authenticated,
          username: state.username,
        );
        await syncFcmToken(isActive: 1);
        return;
      }

      // belum diberikan atau denied — minta permission dialog sistem
      final granted = await _locationService.requestPermission();
      if (granted) {
        state = AuthState(
          status: AuthStatus.authenticated,
          username: state.username,
        );
        await syncFcmToken(isActive: 1);
      } else {
        // Cek sekali lagi apakah sekarang permanently denied
        final newStatus = await _locationService.checkPermissionStatus();
        final errCode = newStatus == LocationPermissionStatus.permanentlyDenied
            ? 'PERMISSION_PERMANENTLY_DENIED'
            : 'PERMISSION_DENIED';
        state = AuthState(
          status: AuthStatus.locationPermissionRequired,
          username: state.username,
          errorMessage: errCode,
        );
      }
    } on AppFailure catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        username: state.username,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        username: state.username,
        errorMessage: 'Gagal mendapatkan izin lokasi: $e',
      );
    }
  }

  /// Logout / Keluar
  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.authenticating);
    // Nonaktifkan FCM Token di backend sebelum local session dihapus
    await syncFcmToken(isActive: 0);
    await _authRepository.logout();
    await _sessionManager.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Reset error state kembali ke unauthenticated / form login
  void resetError() {
    state = AuthState(
      status: state.username != null ? AuthStatus.deviceBindingRequired : AuthStatus.unauthenticated,
      username: state.username,
    );
  }

  /// Rantai validasi: Check Session ➔ Device Binding check ➔ GPS permission check
  Future<void> _validateAccessChain(String? username) async {
    if (username == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      // 1. Validasi Device Binding
      final isBound = await _deviceService.isDeviceBound(username);
      if (!isBound) {
        state = AuthState(
          status: AuthStatus.deviceBindingRequired,
          username: username,
        );
        return;
      }

      // 2. Cek status permission TANPA memunculkan dialog sistem.
      //    Dialog sistem hanya dipanggil di GpsPermissionScreen via checkGpsPermission().
      final permStatus = await _locationService.checkPermissionStatus();

      if (permStatus == LocationPermissionStatus.granted) {
        // Permission sudah ada — langsung ke dashboard
        state = AuthState(
          status: AuthStatus.authenticated,
          username: username,
        );
        return;
      }

      // Permission belum ada (denied, permanentlyDenied, serviceDisabled, notDetermined)
      // Arahkan ke GpsPermissionScreen untuk menampilkan UI rationale yang tepat
      final errorCode = switch (permStatus) {
        LocationPermissionStatus.permanentlyDenied => 'PERMISSION_PERMANENTLY_DENIED',
        LocationPermissionStatus.serviceDisabled => 'GPS_SERVICE_DISABLED',
        _ => 'PERMISSION_NOT_GRANTED',
      };

      state = AuthState(
        status: AuthStatus.locationPermissionRequired,
        username: username,
        errorMessage: errorCode,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        username: username,
        errorMessage: 'Validasi keamanan gagal: $e',
      );
    }
  }

  /// Melakukan registrasi staf baru
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String hotelId,
    required String department,
    required String position,
    String? employeeId,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final device = await _deviceService.getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      
      await _authRepository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        hotelId: hotelId,
        department: department,
        position: position,
        employeeId: employeeId,
        deviceId: device.deviceId,
        deviceModel: device.deviceModel,
        osVersion: device.osVersion,
        appVersion: appVersion,
      );
      
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } on AppFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registrasi gagal: $e',
      );
      return false;
    }
  }

  /// Memeriksa status registrasi staf
  Future<Map<String, dynamic>> checkRegistrationStatus(String email) async {
    try {
      final res = await _authRepository.checkRegistrationStatus(email);
      return {
        'status': res['registration_status'] as String? ?? 'PENDING',
        'reason': res['rejection_reason'] as String?,
      };
    } catch (e) {
      return {
        'status': 'PENDING',
        'reason': 'Gagal memeriksa status: $e',
      };
    }
  }

  /// Sinkronisasi token FCM ke database backend (Push Notification Foundation)
  Future<void> syncFcmToken({int isActive = 1}) async {
    try {
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        _logger.w('Cannot sync FCM token: userId is null.');
        return;
      }

      // Ambil device ID dari secure storage, fallback ke device info jika kosong
      String? deviceId = await _sessionManager.getDeviceId();
      if (deviceId == null || deviceId.isEmpty) {
        final info = await _deviceService.getDeviceInfo();
        deviceId = info.deviceId;
        await _sessionManager.saveDeviceId(deviceId);
      }

      // Ambil token FCM yang terdaftar di Firebase
      final fcmToken = await _fcmService.getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        _logger.w('FCM Token is null, skipping registration.');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final platformName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown');

      _logger.i('Attempting to sync FCM token (isActive: $isActive) for user $userId...');
      final success = await _deviceRepository.registerFcmToken(
        userId: userId,
        deviceId: deviceId,
        fcmToken: fcmToken,
        platform: platformName,
        appVersion: appVersion,
        isActive: isActive,
      );

      if (success) {
        _logger.i('FCM Token sync success (isActive: $isActive).');
      } else {
        _logger.w('FCM Token sync failed on backend response.');
      }
    } catch (e) {
      _logger.e('Failed to synchronize FCM token: $e');
    }
  }
}
