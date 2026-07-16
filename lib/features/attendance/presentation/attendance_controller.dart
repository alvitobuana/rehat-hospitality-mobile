import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/device/device_service.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/location/location_service.dart';
import '../../../core/storage/session_manager.dart';
import '../data/attendance_repository.dart';

enum AttendanceStatus {
  checkedOut,
  checkedIn,
  loading,
  success,
  error,
  incompleteTasksWarning, // Sprint 7.3: Warning untuk check-out dengan task belum selesai
}

class AttendanceState {
  final AttendanceStatus status;
  final String? errorMessage;
  final String? lastActionMessage;
  final List<String> incompleteRooms; // Sprint 7.3: Daftar kamar yang belum selesai

  const AttendanceState({
    required this.status,
    this.errorMessage,
    this.lastActionMessage,
    this.incompleteRooms = const [],
  });

  factory AttendanceState.initial() => const AttendanceState(status: AttendanceStatus.checkedOut);

  AttendanceState copyWith({
    AttendanceStatus? status,
    String? errorMessage,
    String? lastActionMessage,
    List<String>? incompleteRooms,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastActionMessage: lastActionMessage ?? this.lastActionMessage,
      incompleteRooms: incompleteRooms ?? this.incompleteRooms,
    );
  }
}

final attendanceControllerProvider = StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
  final attendanceRepo = ref.read(attendanceRepositoryProvider);
  final deviceService = ref.read(deviceServiceProvider);
  final locationService = ref.read(locationServiceProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return AttendanceController(attendanceRepo, deviceService, locationService, sessionManager);
});

class AttendanceController extends StateNotifier<AttendanceState> {
  final AttendanceRepository _attendanceRepository;
  final DeviceService _deviceService;
  final LocationService _locationService;
  final SessionManager _sessionManager;

  AttendanceController(
    this._attendanceRepository,
    this._deviceService,
    this._locationService,
    this._sessionManager,
  ) : super(AttendanceState.initial());

  /// Eksekusi Check-In Karyawan (Pengambilan GPS + Device Info ➔ Kirim API)
  Future<void> checkIn() async {
    state = state.copyWith(status: AttendanceStatus.loading);
    try {
      // 1. Dapatkan user_id dari Secure Storage
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        throw AppFailure.local('Sesi user_id tidak ditemukan. Silakan login kembali.', 'SESSION_INVALID');
      }

      // 2. Dapatkan parameter hardware perangkat
      final device = await _deviceService.getDeviceInfo();

      // 3. Cek status keaktifan GPS
      final gpsEnabled = await _locationService.isLocationEnabled();
      if (!gpsEnabled) {
        throw AppFailure.local('GPS Anda tidak aktif. Mohon hidupkan GPS ponsel.', 'GPS_OFF');
      }

      // 4. Ambil koordinat GPS real-time
      final coords = await _locationService.getCurrentLocation();
      final lat = coords['latitude']!;
      final lng = coords['longitude']!;

      // 5. Kirim data absensi ke server
      final success = await _attendanceRepository.checkIn(
        userId: userId,
        latitude: lat,
        longitude: lng,
        deviceId: device.deviceId,
      );

      if (success) {
        state = state.copyWith(
          status: AttendanceStatus.success,
          lastActionMessage: 'Check-In Berhasil!\nSelamat Bekerja.',
        );
        // Kembali ke status CheckedIn setelah visual sukses ditampilkan
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(status: AttendanceStatus.checkedIn);
      } else {
        throw AppFailure.local('Check-In ditolak oleh server.');
      }
    } on AppFailure catch (e) {
      if (e.code == 'ALREADY_CHECKED_IN') {
        state = state.copyWith(
          status: AttendanceStatus.success,
          lastActionMessage: 'Sesi Kerja Aktif Dipulihkan.',
        );
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(status: AttendanceStatus.checkedIn);
      } else {
        state = state.copyWith(status: AttendanceStatus.error, errorMessage: e.message);
        // Revert ke status awal setelah memunculkan pesan error
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(status: AttendanceStatus.checkedOut);
      }
    } catch (e) {
      state = state.copyWith(status: AttendanceStatus.error, errorMessage: 'Terjadi kesalahan: $e');
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(status: AttendanceStatus.checkedOut);
    }
  }

  /// Eksekusi Check-Out Karyawan (Pengambilan GPS + Device Info ➔ Kirim API)
  ///
  /// Sprint 7.3: Mendukung parameter [confirmIncomplete] untuk memotong validasi task.
  Future<void> checkOut({bool confirmIncomplete = false}) async {
    state = state.copyWith(status: AttendanceStatus.loading);
    try {
      // 1. Dapatkan user_id dari Secure Storage
      final userId = await _sessionManager.getUserId();
      if (userId == null) {
        throw AppFailure.local('Sesi user_id tidak ditemukan. Silakan login kembali.', 'SESSION_INVALID');
      }

      // 2. Dapatkan parameter hardware
      final device = await _deviceService.getDeviceInfo();

      // 3. Ambil koordinat GPS (opsional untuk Check Out)
      double? lat;
      double? lng;
      try {
        final gpsEnabled = await _locationService.isLocationEnabled();
        if (gpsEnabled) {
          final coords = await _locationService.getCurrentLocation();
          lat = coords['latitude'];
          lng = coords['longitude'];
        }
      } catch (e) {
        // Lokasi gagal diambil, biarkan lat/lng bernilai null dan jangan lempar exception
        print('Gagal mengambil lokasi GPS saat Check-Out: $e. Melanjutkan Check-Out tanpa koordinat.');
      }

      // 4. Kirim ke server
      final success = await _attendanceRepository.checkOut(
        userId: userId,
        latitude: lat,
        longitude: lng,
        deviceId: device.deviceId,
        confirmIncomplete: confirmIncomplete,
      );

      if (success) {
        state = state.copyWith(
          status: AttendanceStatus.success,
          lastActionMessage: 'Check-Out Berhasil!\nTerima Kasih Atas Kerja Keras Anda.',
          incompleteRooms: const [],
        );
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(status: AttendanceStatus.checkedOut);
      } else {
        throw AppFailure.local('Check-Out ditolak oleh server.');
      }
    } on IncompleteTasksFailure catch (e) {
      // Sprint 7.3: Set state ke warning dengan daftar kamar
      state = state.copyWith(
        status: AttendanceStatus.incompleteTasksWarning,
        incompleteRooms: e.rooms,
      );
    } on AppFailure catch (e) {
      state = state.copyWith(
        status: AttendanceStatus.error,
        errorMessage: e.message,
        incompleteRooms: const [],
      );
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(status: AttendanceStatus.checkedIn);
    } catch (e) {
      state = state.copyWith(
        status: AttendanceStatus.error,
        errorMessage: 'Terjadi kesalahan: $e',
        incompleteRooms: const [],
      );
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(status: AttendanceStatus.checkedIn);
    }
  }

  /// Sprint 7.3: Membatalkan Check-Out dan mengembalikan state ke CheckedIn
  void cancelCheckOut() {
    state = state.copyWith(
      status: AttendanceStatus.checkedIn,
      incompleteRooms: const [],
    );
  }

  /// Reset manual error status
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Memverifikasi status check-in terkini dari server
  Future<void> checkCurrentAttendanceStatus() async {
    try {
      final isCheckedIn = await _attendanceRepository.getAttendanceStatus();
      state = state.copyWith(
        status: isCheckedIn ? AttendanceStatus.checkedIn : AttendanceStatus.checkedOut,
      );
    } catch (_) {
      // Biarkan status default jika gagal request ke server
    }
  }
}
