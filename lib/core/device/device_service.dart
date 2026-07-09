import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/device_repository.dart';
import '../storage/session_manager.dart';
import 'device_info.dart';
import 'device_service_impl.dart';

/// Provider global untuk mengakses layanan Device Service
final deviceServiceProvider = Provider<DeviceService>((ref) {
  final deviceRepo = ref.read(deviceRepositoryProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return DeviceServiceImpl(deviceRepo, sessionManager);
});

/// Kontrak abstraksi layanan identifikasi perangkat keras dan Device Binding.
abstract class DeviceService {
  /// Mengambil metadata informasi perangkat keras saat ini secara async
  Future<DeviceInfo> getDeviceInfo();

  /// Memeriksa apakah perangkat ini sudah terikat dengan ID Karyawan bersangkutan di database
  /// 
  /// Endpoint backend yang dibutuhkan:
  /// - `GET /Housekeeping/api_check_device_binding.php?user_id={userId}&device_id={deviceId}`
  Future<bool> isDeviceBound(String userId);

  /// Mendaftarkan pengikatan perangkat fisik (Device Binding) baru ke server
  /// 
  /// Endpoint backend yang dibutuhkan:
  /// - `POST /Housekeeping/api_bind_device.php`
  Future<bool> bindDevice(String userId, DeviceInfo device);
}
