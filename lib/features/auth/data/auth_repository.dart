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
          // Ekstraksi PHPSESSID secara langsung dari response untuk menghindari race condition async
          String? phpSessionId;
          
          // Cara 1: Baca dari header set-cookie
          final setCookies = response.headers['set-cookie'];
          if (setCookies != null && setCookies.isNotEmpty) {
            for (var cookie in setCookies) {
              if (cookie.contains('PHPSESSID=')) {
                final match = RegExp(r'PHPSESSID=([^;]+)').firstMatch(cookie);
                if (match != null) {
                  phpSessionId = match.group(1);
                  break;
                }
              }
            }
          }
          
          // Cara 2: Fallback ke cookie jar milik DioClient
          if (phpSessionId == null) {
            try {
              final cookies = await _dioClient.cookieJar.loadForRequest(
                Uri.parse(response.requestOptions.baseUrl),
              );
              for (var cookie in cookies) {
                if (cookie.name == 'PHPSESSID') {
                  phpSessionId = cookie.value;
                  break;
                }
              }
            } catch (_) {
              // Abaikan jika pemuatan dari cookie jar gagal
            }
          }
          
          if (phpSessionId != null && phpSessionId.isNotEmpty) {
            data['phpSessionId'] = phpSessionId;
          }
          
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

  /// Melakukan registrasi staf housekeeping baru
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String hotelId,
    required String department,
    required String position,
    String? employeeId,
    required String deviceId,
    required String deviceModel,
    required String osVersion,
    required String appVersion,
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.pathRegister,
        data: {
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'hotel_id': hotelId,
          'department': department,
          'position': position,
          'employee_id': employeeId,
          'device_id': deviceId,
          'device_model': deviceModel,
          'os_version': osVersion,
          'app_version': appVersion,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['status'] == 'success') {
          return data;
        } else {
          throw AppFailure.local(data['message'] ?? 'Registrasi gagal.', 'REGISTRATION_FAILED');
        }
      }
      throw AppFailure.local('Respon server tidak valid.', 'INVALID_RESPONSE');
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Terjadi kesalahan koneksi saat registrasi: $e');
    }
  }

  /// Memeriksa status registrasi berdasarkan email
  Future<Map<String, dynamic>> checkRegistrationStatus(String email) async {
    try {
      final response = await _dioClient.get(
        AppConstants.pathRegistrationStatus,
        queryParameters: {
          'email': email,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        return data;
      }
      throw AppFailure.local(data is Map ? data['message'] ?? 'Gagal memeriksa status.' : 'Gagal memeriksa status.', 'STATUS_CHECK_FAILED');
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Terjadi kesalahan koneksi saat memeriksa status registrasi: $e');
    }
  }
}
