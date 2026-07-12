import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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
  final int photoIndex;

  PhotoUploadResult({required this.photoPath, required this.photoIndex});

  factory PhotoUploadResult.fromJson(Map<String, dynamic> json, {int photoIndex = 1}) {
    return PhotoUploadResult(
      photoPath: json['photo_path'] as String? ?? '',
      photoIndex: json['photo_index'] as int? ?? photoIndex,
    );
  }
}

/// Repository untuk mengunggah foto bukti penyelesaian tugas
/// melalui POST /Housekeeping/api_upload_photo.php
///
/// Sprint 7.1: mendukung multi-photo upload (max 3 foto per task)
/// dengan kompresi otomatis menggunakan flutter_image_compress.
class PhotoUploadRepository {
  final DioClient _dioClient;
  final SessionManager _sessionManager;

  /// Batas maksimum foto yang diizinkan per task
  static const int maxPhotosPerTask = 3;

  /// Ukuran file maksimum setelah kompresi (5 MB)
  static const int maxSizeBytes = 5 * 1024 * 1024;

  PhotoUploadRepository(this._dioClient, this._sessionManager);

  // ---------------------------------------------------------------------------
  // Sprint 7.1: Image Compression
  // ---------------------------------------------------------------------------

  /// Mengkompres gambar sebelum upload menggunakan flutter_image_compress.
  ///
  /// Target: kualitas 72%, resolusi max 1280×960.
  /// Jika kompresi gagal (bukan JPG/PNG), kembalikan file asli.
  Future<File> _compressImage(File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      CompressFormat format;
      switch (ext) {
        case 'png':
          format = CompressFormat.png;
          break;
        default:
          format = CompressFormat.jpeg;
      }

      // Simpan hasil kompresi di temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_$timestamp.$ext';

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 72,
        minWidth: 1280,
        minHeight: 960,
        format: format,
      );

      if (compressedXFile != null) {
        final compressed = File(compressedXFile.path);
        // Gunakan file yang lebih kecil
        final originalSize = await imageFile.length();
        final compressedSize = await compressed.length();
        if (compressedSize < originalSize) {
          return compressed;
        }
      }
    } catch (_) {
      // Jika kompresi gagal, lanjut dengan file asli
    }
    return imageFile;
  }

  // ---------------------------------------------------------------------------
  // Upload Single Photo
  // ---------------------------------------------------------------------------

  /// Mengunggah satu foto bukti penyelesaian tugas menggunakan multipart/form-data.
  ///
  /// Parameter:
  /// - [taskId]      : ID tugas yang fotonya diunggah.
  /// - [imageFile]   : File gambar dari kamera/galeri.
  /// - [photoIndex]  : Urutan foto (1–[maxPhotosPerTask]).
  /// - [onSendProgress] : Callback untuk laporan progres upload (opsional).
  ///
  /// Validasi sebelum upload:
  /// - Ekstensi file harus JPG, JPEG, atau PNG.
  /// - Ukuran file setelah kompresi maksimal 5 MB.
  Future<PhotoUploadResult> uploadPhoto({
    required int taskId,
    required File imageFile,
    required int photoIndex,
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

    // 2. Validasi photoIndex
    if (photoIndex < 1 || photoIndex > maxPhotosPerTask) {
      throw AppFailure.local(
        'Indeks foto tidak valid (harus 1–$maxPhotosPerTask).',
        'INVALID_PHOTO_INDEX',
      );
    }

    // 3. Validasi ekstensi file
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      throw AppFailure.local(
        'Format file tidak didukung. Gunakan JPG atau PNG.',
        'UNSUPPORTED_MEDIA_TYPE',
      );
    }

    // 4. Kompres gambar sebelum upload (Sprint 7.1)
    final compressedFile = await _compressImage(imageFile);

    // 5. Validasi ukuran file setelah kompresi (maks 5 MB)
    final fileSize = await compressedFile.length();
    if (fileSize > maxSizeBytes) {
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw AppFailure.local(
        'Ukuran file ($sizeMb MB) melebihi batas maksimum 5 MB.',
        'FILE_TOO_LARGE',
      );
    }

    try {
      // 6. Buat timestamp untuk nama file unik
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}_'
          '${now.month.toString().padLeft(2, '0')}_'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // 7. Bangun multipart form-data sesuai kontrak backend
      final compressedExt = compressedFile.path.split('.').last.toLowerCase();
      final fileName = 'task_${taskId}_photo${photoIndex}_proof_$timestamp.$compressedExt';
      final formData = FormData.fromMap({
        'task_id'     : taskId.toString(),
        'user_id'     : userId.toString(),
        'timestamp'   : timestamp,
        'photo_index' : photoIndex.toString(),
        'photo'       : await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName,
        ),
      });

      // 8. Kirim POST multipart
      final response = await _dioClient.post(
        '/Housekeeping/api_upload_photo.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
        onSendProgress: onSendProgress,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true && data['data'] != null) {
          return PhotoUploadResult.fromJson(data['data'], photoIndex: photoIndex);
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
          final msg = e.response?.data?['message'] as String?;
          throw AppFailure.local(
            msg ?? 'Batas maksimum foto per task telah tercapai.',
            'PHOTO_LIMIT_EXCEEDED',
          );
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
