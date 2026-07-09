import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return DeviceRepository(dioClient);
});

class DeviceRepository {
  final DioClient _dioClient;

  DeviceRepository(this._dioClient);

  /// Memvalidasi status device binding karyawan ke server
  Future<bool> validateDevice({
    required int userId,
    required String deviceId,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.pathValidateDevice,
        data: {
          'user_id': userId,
          'device_id': deviceId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final nestedData = data['data'];
        if (nestedData is Map<String, dynamic>) {
          return nestedData['registered'] == true;
        }
      }
      return false;
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal memvalidasi perangkat: $e');
    }
  }

  /// Mendaftarkan device binding karyawan ke server
  Future<bool> registerDevice({
    required int userId,
    required String deviceId,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.pathRegisterDevice,
        data: {
          'user_id': userId,
          'device_id': deviceId,
          'device_model': deviceModel,
          'os_version': osVersion,
          'app_version': appVersion,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          return true;
        } else {
          throw AppFailure.local(data['message'] ?? 'Gagal mengikat perangkat.', 'BINDING_FAILED');
        }
      }
      return false;
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal mendaftarkan perangkat: $e');
    }
  }
}
