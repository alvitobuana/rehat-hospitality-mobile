import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return AuthRepository(dioClient);
});

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  /// Melakukan request login karyawan ke server
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Melakukan POST login, response map kini berisi user_id (int) dari Hostinger
      final response = await _dioClient.post(
        AppConstants.pathLogin,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType, // Mendukung form POST backend
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['status'] == 'success') {
          return data;
        } else {
          throw AppFailure.local(data['message'] ?? 'Login gagal.', 'LOGIN_FAILED');
        }
      }
      throw AppFailure.local('Respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Terjadi kesalahan koneksi saat login: $e');
    }
  }

  /// Memverifikasi sesi cookie PHPSESSID lokal ke server (Auto Login check)
  Future<Map<String, dynamic>> checkSession() async {
    try {
      final response = await _dioClient.get(AppConstants.pathAuthCheck);
      final data = response.data;
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        return data;
      }
      throw const AppFailure(
        message: 'Sesi tidak aktif.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal memverifikasi sesi: $e');
    }
  }

  /// Mengakhiri sesi masuk pengguna di server dan menghapus cookie lokal
  Future<void> logout() async {
    try {
      // Panggil endpoint logout server secara optimal (fire and forget jika offline)
      await _dioClient.get(AppConstants.pathLogout).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Abaikan error jaringan saat logout agar pembersihan lokal tetap berjalan
    } finally {
      // Bersihkan seluruh persistent cookies lokal
      await _dioClient.clearCookies();
    }
  }
}
