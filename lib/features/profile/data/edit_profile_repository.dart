import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/session_manager.dart';

final editProfileRepositoryProvider = Provider<EditProfileRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final sessionManager = ref.read(sessionManagerProvider);
  return EditProfileRepository(dioClient, sessionManager);
});

class EditProfileRepository {
  final DioClient _dioClient;
  final SessionManager _sessionManager;

  static const String _path = '/Housekeeping/api_update_profile.php';

  EditProfileRepository(this._dioClient, this._sessionManager);

  // ---------------------------------------------------------------------------
  // Update Profile (name, email, phone)
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> updateProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _dioClient.post(
        _path,
        data: {
          'action':    'update_profile',
          'full_name': fullName,
          'email':     email,
          'phone':     phone,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        final updatedFullName = data['full_name'] as String? ?? fullName;
        final updatedEmail    = data['email']     as String? ?? email;
        final updatedPhone    = data['phone']     as String? ?? phone;

        // Persist to local session
        await _sessionManager.saveProfileFields(
          fullName: updatedFullName,
          email: updatedEmail,
          phone: updatedPhone,
        );
        return {
          'full_name': updatedFullName,
          'email': updatedEmail,
          'phone': updatedPhone,
        };
      }
      throw AppFailure.local(
        data?['message'] ?? 'Gagal memperbarui profil.',
        'UPDATE_FAILED',
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal memperbarui profil: $e', 'UPDATE_FAILED');
    }
  }

  // ---------------------------------------------------------------------------
  // Change Password
  // ---------------------------------------------------------------------------
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dioClient.post(
        _path,
        data: {
          'action':           'change_password',
          'current_password': currentPassword,
          'new_password':     newPassword,
          'confirm_password': confirmPassword,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        return;
      }
      throw AppFailure.local(
        data?['message'] ?? 'Gagal mengubah password.',
        'PASSWORD_FAILED',
      );
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.local('Gagal mengubah password: $e', 'PASSWORD_FAILED');
    }
  }
}
