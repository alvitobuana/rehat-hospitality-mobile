import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import 'package:logger/logger.dart';

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

  /// Mendaftarkan atau memperbarui FCM Token di database backend
  Future<bool> registerFcmToken({
    required int userId,
    required String deviceId,
    required String fcmToken,
    required String platform,
    required String appVersion,
    int isActive = 1,
  }) async {
    final logger = Logger();
    final url = AppConstants.pathRegisterFcmToken;
    final payload = {
      'user_id': userId,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'platform': platform,
      'app_version': appVersion,
      'is_active': isActive,
    };

    logger.i("HTTP REQUEST:\n"
        "URL: $url\n"
        "Method: POST\n"
        "Headers: Content-Type: application/json\n"
        "Body: $payload");

    try {
      final response = await _dioClient.post(
        url,
        data: payload,
      );

      final data = response.data;
      logger.i("HTTP RESPONSE:\n"
          "Status Code: ${response.statusCode}\n"
          "Headers: ${response.headers}\n"
          "Body: $data");

      if (data is Map<String, dynamic>) {
        return data['success'] == true;
      }
      return false;
    } on AppFailure catch (e) {
      logger.e("HTTP RESPONSE FAILURE (AppFailure): ${e.message}");
      rethrow;
    } catch (e) {
      logger.e("HTTP RESPONSE FAILURE (Exception): $e");
      throw AppFailure.local('Gagal mensinkronisasikan FCM Token: $e');
    }
  }
}
