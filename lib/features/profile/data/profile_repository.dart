import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/session_manager.dart';
import '../../../core/utils/env_config.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return ProfileRepository(dioClient, sessionManager);
});

class ProfileRepository {
  final DioClient _dioClient;
  final SessionManager _sessionManager;

  /// Endpoint untuk upload/hapus foto profil
  static const String _uploadPath = '/Housekeeping/api_upload_profile_photo.php';

  ProfileRepository(this._dioClient, this._sessionManager);

  // ---------------------------------------------------------------------------
  // Image Compression
  // ---------------------------------------------------------------------------

  /// Kompresi gambar sebelum diunggah.
  /// Target kualitas 75% dengan lebar/tinggi max 720px.
  /// Jika hasil kompresi lebih besar dari aslinya, kembalikan file asli.
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

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/profile_compressed_$timestamp.$ext';

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 75,
        minWidth: 720,
        minHeight: 720,
        format: format,
      );

      if (compressedXFile != null) {
        final compressed = File(compressedXFile.path);
        final originalSize = await imageFile.length();
        final compressedSize = await compressed.length();
        // Gunakan file yang lebih kecil
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
  // Upload Profile Photo
  // ---------------------------------------------------------------------------

  /// Mengkompresi dan mengunggah foto profil ke server.
  /// Mengembalikan path foto baru yang tersimpan di server.
  Future<String> uploadProfilePhoto(File imageFile) async {
    // Validasi ekstensi
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      throw AppFailure.local(
        'Format file tidak didukung. Gunakan JPG atau PNG.',
        'UNSUPPORTED_MEDIA_TYPE',
      );
    }

    // Kompresi sebelum upload
    final compressedFile = await _compressImage(imageFile);

    // Validasi ukuran setelah kompresi (max 2MB)
    final sizeBytes = await compressedFile.length();
    if (sizeBytes > 2 * 1024 * 1024) {
      throw AppFailure.local(
        'Ukuran foto setelah kompresi melebihi 2MB. Silakan pilih foto lain.',
        'FILE_TOO_LARGE',
      );
    }

    try {
      final formData = FormData.fromMap({
        'action': 'upload',
        'photo': await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'profile_photo.$extension',
        ),
      });

      final response = await _dioClient.post(_uploadPath, data: formData);
      final data = response.data;

      if (data is Map<String, dynamic> && data['status'] == 'success') {
        final photoPath = data['profile_photo'] as String? ?? '';
        // Perbarui session lokal
        await _sessionManager.saveProfilePhoto(photoPath);
        return photoPath;
      }

      throw AppFailure.local(
        data?['message'] ?? 'Gagal mengunggah foto profil.',
        'UPLOAD_FAILED',
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal mengunggah foto profil: $e', 'UPLOAD_FAILED');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Profile Photo
  // ---------------------------------------------------------------------------

  /// Menghapus foto profil dari server dan membersihkan session lokal.
  Future<void> deleteProfilePhoto() async {
    try {
      final response = await _dioClient.post(
        _uploadPath,
        data: {'action': 'delete'},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final data = response.data;

      if (data is Map<String, dynamic> && data['status'] == 'success') {
        await _sessionManager.saveProfilePhoto('');
        return;
      }

      throw AppFailure.local(
        data?['message'] ?? 'Gagal menghapus foto profil.',
        'DELETE_FAILED',
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal menghapus foto profil: $e', 'DELETE_FAILED');
    }
  }

  // ---------------------------------------------------------------------------
  // Build Photo URL
  // ---------------------------------------------------------------------------

  /// Membangun URL lengkap dari path relatif foto profil yang disimpan di server.
  static String buildPhotoUrl(String relativePath) {
    if (relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    return '${EnvConfig.baseUrl}/$relativePath';
  }
}
