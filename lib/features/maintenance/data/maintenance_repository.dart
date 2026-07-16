import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return MaintenanceRepository(dioClient);
});

class MaintenanceRepository {
  final DioClient _dioClient;
  final Logger _logger = Logger();

  MaintenanceRepository(this._dioClient);

  /// Fetch list of rooms by hotel_id
  Future<List<Map<String, dynamic>>> getRooms(String hotelId) async {
    try {
      final response = await _dioClient.get(
        '/Housekeeping/api_get_rooms.php',
        queryParameters: {'hotel_id': hotelId},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          final list = data['data'] as List;
          return list.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          throw AppFailure.local(
            data['message'] ?? 'Gagal memuat daftar kamar.',
            'ROOM_LIST_FAILED',
          );
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengambil daftar kamar: $e');
    }
  }

  /// Submit maintenance report
  Future<bool> submitReport({
    required String hotelId,
    required String locationType,
    int? roomId,
    String? commonArea,
    String? customLocation,
    required String category,
    required String description,
    required List<File> photos,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'hotel_id': hotelId,
        'location_type': locationType,
        'category': category,
        'description': description,
      };

      if (roomId != null) {
        formMap['room_id'] = roomId.toString();
      }
      if (commonArea != null) {
        formMap['common_area'] = commonArea;
      }
      if (customLocation != null) {
        formMap['custom_location'] = customLocation;
      }

      for (int i = 0; i < photos.length; i++) {
        final key = 'photo${i + 1}';
        final file = photos[i];
        final ext = file.path.split('.').last.toLowerCase();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'maintenance_report_photo${i + 1}_$timestamp.$ext';

        formMap[key] = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(formMap);

      _logger.i('Mengirim laporan kerusakan ke server...');
      final response = await _dioClient.post(
        '/Housekeeping/api_submit_maintenance.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          return true;
        } else {
          throw AppFailure.local(
            data['message'] ?? 'Gagal mengirim laporan.',
            'SUBMIT_FAILED',
          );
        }
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
      }
      final resData = e.response?.data;
      if (resData is Map<String, dynamic> && resData['message'] != null) {
        throw AppFailure.local(resData['message'], 'SUBMIT_FAILED_SERVER');
      }
      throw AppFailure.local('Kesalahan jaringan: ${e.message}');
    } catch (e) {
      throw AppFailure.local('Gagal mengirim laporan: $e');
    }
  }
}
