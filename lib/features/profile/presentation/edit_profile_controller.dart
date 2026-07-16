import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/session_manager.dart';
import '../data/edit_profile_repository.dart';

// =============================================================================
// State
// =============================================================================

enum EditProfileStatus { idle, saving, success, error }
enum PasswordStatus { idle, saving, success, error }

class EditProfileState {
  final EditProfileStatus profileStatus;
  final PasswordStatus passwordStatus;
  final String? profileError;
  final String? passwordError;

  const EditProfileState({
    this.profileStatus = EditProfileStatus.idle,
    this.passwordStatus = PasswordStatus.idle,
    this.profileError,
    this.passwordError,
  });

  EditProfileState copyWith({
    EditProfileStatus? profileStatus,
    PasswordStatus? passwordStatus,
    String? profileError,
    String? passwordError,
    bool clearProfileError = false,
    bool clearPasswordError = false,
  }) {
    return EditProfileState(
      profileStatus:  profileStatus  ?? this.profileStatus,
      passwordStatus: passwordStatus ?? this.passwordStatus,
      profileError:  clearProfileError  ? null : (profileError  ?? this.profileError),
      passwordError: clearPasswordError ? null : (passwordError ?? this.passwordError),
    );
  }
}

// =============================================================================
// Controller
// =============================================================================

final editProfileControllerProvider =
    StateNotifierProvider<EditProfileController, EditProfileState>((ref) {
  final repo    = ref.read(editProfileRepositoryProvider);
  return EditProfileController(repo, ref);
});

class EditProfileController extends StateNotifier<EditProfileState> {
  final EditProfileRepository _repository;
  final Ref _ref;

  EditProfileController(this._repository, this._ref)
      : super(const EditProfileState());

  // ---------------------------------------------------------------------------
  // Update Profile (name, email, phone)
  // ---------------------------------------------------------------------------
  Future<bool> saveProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(
      profileStatus: EditProfileStatus.saving,
      clearProfileError: true,
    );
    try {
      await _repository.updateProfile(
        fullName: fullName,
        email: email,
        phone: phone,
      );
      state = state.copyWith(profileStatus: EditProfileStatus.success);
      // Invalidate session so UI refreshes with new data
      _ref.invalidate(sessionDataProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        profileStatus: EditProfileStatus.error,
        profileError: e.toString().replaceAll('AppFailure: ', ''),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Change Password
  // ---------------------------------------------------------------------------
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(
      passwordStatus: PasswordStatus.saving,
      clearPasswordError: true,
    );
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(passwordStatus: PasswordStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        passwordStatus: PasswordStatus.error,
        passwordError: e.toString().replaceAll('AppFailure: ', ''),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------
  void reset() {
    state = const EditProfileState();
  }
}
