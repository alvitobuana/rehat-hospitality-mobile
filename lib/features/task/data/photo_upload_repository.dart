import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/session_manager.dart';

final photoUploadRepositoryProvider = Provider<PhotoUploadRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return PhotoUploadRepository(dioClient, sessionManager);
});

/// Model respons setelah upload foto berhasil
class PhotoUploadResult {
  final String photoPath;

  PhotoUploadResult({required this.photoPath});

  factory PhotoUploadResult.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResult(
      photoPath: json['photo_path'] as String? ?? '',
    );
  }
}

/// Repository untuk mengunggah foto bukti penyelesaian tugas
/// melalui POST /Housekeeping/api_upload_photo.php
class PhotoUploadRepository {
  final DioClient _dioClient;
  final SessionManager _sessionManager;

  PhotoUploadRepository(this._dioClient, this._sessionManager);

  /// Mengunggah foto bukti penyelesaian tugas menggunakan multipart/form-data.
  ///
  /// Parameter:
  /// - [taskId]    : ID tugas yang fotonya diunggah.
  /// - [imageFile] : File gambar dari kamera/galeri.
  /// - [onSendProgress] : Callback untuk laporan progres upload (opsional).
  ///
  /// Validasi sebelum upload:
  /// - Ekstensi file harus JPG, JPEG, atau PNG.
  /// - Ukuran file maksimal 5 MB (5,242,880 bytes).
  Future<PhotoUploadResult> uploadPhoto({
    required int taskId,
    required File imageFile,
    ProgressCallback? onSendProgress,
  }) async {
    // 1. Ambil user_id dari session
    final userId = await _sessionManager.getUserId();
    if (userId == null) {
      throw AppFailure.local(
        'Sesi berakhir. Silakan masuk kembali.',
        'SESSION_EXPIRED',
      );
    }

    // 2. Validasi ekstensi file
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      throw AppFailure.local(
        'Format file tidak didukung. Gunakan JPG atau PNG.',
        'UNSUPPORTED_MEDIA_TYPE',
      );
    }

    // 3. Validasi ukuran file (maks 5 MB)
    final fileSize = await imageFile.length();
    const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
    if (fileSize > maxSizeBytes) {
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw AppFailure.local(
        'Ukuran file ($sizeMb MB) melebihi batas maksimum 5 MB.',
        'FILE_TOO_LARGE',
      );
    }

    try {
      // 4. Buat timestamp untuk nama file unik
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}_'
          '${now.month.toString().padLeft(2, '0')}_'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // 5. Bangun multipart form-data sesuai kontrak backend
      final fileName = 'task_${taskId}_proof_$timestamp.$extension';
      final formData = FormData.fromMap({
        'task_id': taskId.toString(),
        'user_id': userId.toString(),
        'timestamp': timestamp,
        'photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // 6. Kirim POST multipart dengan options khusus (override Content-Type)
      final response = await _dioClient.post(
        '/Housekeeping/api_upload_photo.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60), // Toleransi lebih lama untuk upload
          receiveTimeout: const Duration(seconds: 30),
        ),
        onSendProgress: onSendProgress,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          return PhotoUploadResult.fromJson(data['data']);
        }
        throw AppFailure.local(
          data['message'] ?? 'Gagal mengunggah foto.',
          'UPLOAD_FAILED',
        );
      }
      throw AppFailure.local('Format respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
        case 403:
          throw AppFailure.local('Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED');
        case 404:
          throw AppFailure.local('Tugas tidak ditemukan di server.', 'TASK_NOT_FOUND');
        case 413:
          throw AppFailure.local('Ukuran foto terlalu besar. Kurangi resolusi dan coba lagi.', 'PAYLOAD_TOO_LARGE');
        case 415:
          throw AppFailure.local('Format file tidak didukung oleh server.', 'UNSUPPORTED_MEDIA_TYPE');
        case 422:
          throw AppFailure.local('Data tidak valid. Pastikan task ID dan foto benar.', 'VALIDATION_ERROR');
        case 500:
          throw AppFailure.local('Terjadi gangguan pada server hotel.', 'SERVER_ERROR');
        default:
          throw AppFailure.fromDioException(e);
      }
    } catch (e) {
      throw AppFailure.local('Gagal mengunggah foto: $e');
    }
  }
}
