import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return AttendanceRepository(dioClient);
});

class AttendanceRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  AttendanceRepository(this._dioClient);

  /// Mengirim data verifikasi Check In lokasi staf ke server
  Future<bool> checkIn({
    required int userId,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    try {
      _logger.i('Mengirim data Check-In ke server: UserID=$userId, Lat=$latitude, Lng=$longitude, DeviceID=$deviceId');
      
      final response = await _dioClient.post(
        '/Housekeeping/api_check_in.php',
        data: {
          'user_id': userId,
          'device_id': deviceId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          return true;
        } else {
          throw AppFailure.local(data['message'] ?? 'Check-In ditolak.', 'CHECKIN_REJECTED');
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal mengirim data Check-In: $e');
    }
  }

  /// Mengirim data verifikasi Check Out lokasi staf ke server
  Future<bool> checkOut({
    required int userId,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    try {
      _logger.i('Mengirim data Check-Out ke server: UserID=$userId, Lat=$latitude, Lng=$longitude, DeviceID=$deviceId');
      
      final response = await _dioClient.post(
        '/Housekeeping/api_check_out.php',
        data: {
          'user_id': userId,
          'device_id': deviceId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          return true;
        } else {
          throw AppFailure.local(data['message'] ?? 'Check-Out ditolak.', 'CHECKOUT_REJECTED');
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal mengirim data Check-Out: $e');
    }
  }
}
