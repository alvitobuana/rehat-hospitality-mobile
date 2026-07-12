import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
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
          throw AppFailure.local(data['message'] ?? 'Check-In ditolak.', data['code'] ?? 'CHECKIN_REJECTED');
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      // Baca pesan dari response body HTTP 400/403 dll
      final res = e.response;
      if (res != null && res.data is Map<String, dynamic>) {
        final resData = res.data as Map<String, dynamic>;
        throw AppFailure.local(
          resData['message'] ?? 'Check-In ditolak oleh server.',
          resData['code']    ?? 'CHECKIN_REJECTED',
        );
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengirim data Check-In: $e');
    }
  }


  /// Mengirim data verifikasi Check Out lokasi staf ke server
  ///
  /// Sprint 7.3: Mendukung parameter [confirmIncomplete] dan penanganan custom untuk
  /// respon 422 INCOMPLETE_TASKS.
  Future<bool> checkOut({
    required int userId,
    double? latitude,
    double? longitude,
    required String deviceId,
    bool confirmIncomplete = false,
  }) async {
    try {
      _logger.i('Mengirim data Check-Out ke server: UserID=$userId, Lat=$latitude, Lng=$longitude, DeviceID=$deviceId, ConfirmIncomplete=$confirmIncomplete');
      
      final response = await _dioClient.post(
        '/Housekeeping/api_check_out.php',
        data: {
          'user_id': userId,
          'device_id': deviceId,
          'latitude': latitude,
          'longitude': longitude,
          'confirm_incomplete': confirmIncomplete,
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
    } on DioException catch (e) {
      final res = e.response;
      if (res != null && res.data is Map<String, dynamic>) {
        final resData = res.data as Map<String, dynamic>;
        if (resData['code'] == 'INCOMPLETE_TASKS') {
          final List<String> rooms = [];
          if (resData['data'] is List) {
            for (var item in resData['data']) {
              if (item is Map && item['room_number'] != null) {
                rooms.add('Kamar ${item['room_number']}');
              }
            }
          }
          throw IncompleteTasksFailure(
            rooms: rooms,
            message: resData['message'] ?? 'Anda masih memiliki tugas yang belum selesai.',
          );
        }
        throw AppFailure.local(
          resData['message'] ?? 'Check-Out ditolak oleh server.',
          resData['code'] ?? 'CHECKOUT_REJECTED',
        );
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengirim data Check-Out: $e');
    }
  }

  /// Mengambil waktu server (WIB) terkini
  Future<String?> getServerTime() async {
    try {
      final response = await _dioClient.get('/Housekeeping/api_server_time.php');
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data['server_time'] as String?;
      }
    } catch (e) {
      _logger.e('Gagal mendapatkan waktu server: $e');
    }
    return null;
  }
}
