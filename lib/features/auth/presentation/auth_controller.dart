import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/device/device_service.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/location/location_service.dart';
import '../../../core/storage/session_manager.dart';
import '../data/auth_repository.dart';

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
  return AuthController(authRepo, deviceService, locationService, sessionManager);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final DeviceService _deviceService;
  final LocationService _locationService;
  final SessionManager _sessionManager;

  AuthController(
    this._authRepository,
    this._deviceService,
    this._locationService,
    this._sessionManager,
  ) : super(AuthState.initial()) {
    // Jalankan cek sesi otomatis saat inisialisasi controller
    checkAutoLogin();
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
      
      if (username != null && userId != null) {
        await _sessionManager.saveSession(
          phpSessionId: phpSessionId,
          userId: userId,
          username: username,
          role: role,
          level: level,
        );
        await _validateAccessChain(username);
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

      final phpSessionId = await _sessionManager.getPhpSessionId() ?? '';
      
      if (userId != null) {
        await _sessionManager.saveSession(
          phpSessionId: phpSessionId,
          userId: userId,
          username: loggedInUser,
          role: role,
          level: level,
        );
        await _validateAccessChain(loggedInUser);
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

  /// Mengevaluasi Izin Lokasi GPS
  Future<void> checkGpsPermission() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    try {
      final gpsEnabled = await _locationService.isLocationEnabled();
      if (!gpsEnabled) {
        throw AppFailure.local('Layanan GPS ponsel Anda tidak aktif. Harap nyalakan GPS.', 'GPS_DISABLED');
      }

      final permissionGranted = await _locationService.requestPermission();
      if (permissionGranted) {
        state = AuthState(
          status: AuthStatus.authenticated,
          username: state.username,
        );
      } else {
        state = AuthState(
          status: AuthStatus.locationPermissionRequired,
          username: state.username,
          errorMessage: 'Aplikasi memerlukan izin GPS untuk absensi.',
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

      // 2. Validasi Layanan Lokasi & Izin GPS
      final gpsEnabled = await _locationService.isLocationEnabled();
      if (!gpsEnabled) {
        state = AuthState(
          status: AuthStatus.locationPermissionRequired,
          username: username,
          errorMessage: 'GPS tidak aktif.',
        );
        return;
      }

      final permissionGranted = await _locationService.requestPermission();
      if (!permissionGranted) {
        state = AuthState(
          status: AuthStatus.locationPermissionRequired,
          username: username,
          errorMessage: 'Izin GPS ditolak.',
        );
        return;
      }

      // Jika seluruh rantai lolos, user diotentikasi penuh
      state = AuthState(
        status: AuthStatus.authenticated,
        username: username,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        username: username,
        errorMessage: 'Validasi keamanan gagal: $e',
      );
    }
  }
}
