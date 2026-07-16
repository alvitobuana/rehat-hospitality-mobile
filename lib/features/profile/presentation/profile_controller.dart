import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/storage/session_manager.dart';
import '../data/profile_repository.dart';

// =============================================================================
// Profile State
// =============================================================================

enum ProfilePhotoStatus { idle, picking, uploading, deleting, success, error }

class ProfilePhotoState {
  final ProfilePhotoStatus status;
  final String? errorMessage;
  final String? updatedPhotoPath;

  const ProfilePhotoState({
    this.status = ProfilePhotoStatus.idle,
    this.errorMessage,
    this.updatedPhotoPath,
  });

  ProfilePhotoState copyWith({
    ProfilePhotoStatus? status,
    String? errorMessage,
    String? updatedPhotoPath,
    bool clearError = false,
    bool clearPhoto = false,
  }) {
    return ProfilePhotoState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      updatedPhotoPath: clearPhoto ? null : (updatedPhotoPath ?? this.updatedPhotoPath),
    );
  }
}

// =============================================================================
// Controller
// =============================================================================

final profilePhotoControllerProvider =
    StateNotifierProvider<ProfilePhotoController, ProfilePhotoState>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return ProfilePhotoController(repository, ref);
});

class ProfilePhotoController extends StateNotifier<ProfilePhotoState> {
  final ProfileRepository _repository;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  ProfilePhotoController(this._repository, this._ref)
      : super(const ProfilePhotoState());

  // ---------------------------------------------------------------------------
  // Pick photo from Camera
  // ---------------------------------------------------------------------------
  Future<void> pickFromCamera() async {
    state = state.copyWith(status: ProfilePhotoStatus.picking, clearError: true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked == null) {
        state = state.copyWith(status: ProfilePhotoStatus.idle);
        return;
      }
      await _uploadPhoto(File(picked.path));
    } catch (e) {
      state = state.copyWith(
        status: ProfilePhotoStatus.error,
        errorMessage: 'Gagal membuka kamera: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pick photo from Gallery
  // ---------------------------------------------------------------------------
  Future<void> pickFromGallery() async {
    state = state.copyWith(status: ProfilePhotoStatus.picking, clearError: true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked == null) {
        state = state.copyWith(status: ProfilePhotoStatus.idle);
        return;
      }
      await _uploadPhoto(File(picked.path));
    } catch (e) {
      state = state.copyWith(
        status: ProfilePhotoStatus.error,
        errorMessage: 'Gagal membuka galeri: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------
  Future<void> _uploadPhoto(File file) async {
    state = state.copyWith(status: ProfilePhotoStatus.uploading, clearError: true);
    try {
      final newPath = await _repository.uploadProfilePhoto(file);
      state = state.copyWith(
        status: ProfilePhotoStatus.success,
        updatedPhotoPath: newPath,
        clearError: true,
      );
      // Invalidate session provider to refresh the UI globally
      _ref.invalidate(sessionDataProvider);
    } catch (e) {
      state = state.copyWith(
        status: ProfilePhotoStatus.error,
        errorMessage: e.toString().replaceAll('AppFailure: ', ''),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------
  Future<void> deletePhoto() async {
    state = state.copyWith(status: ProfilePhotoStatus.deleting, clearError: true);
    try {
      await _repository.deleteProfilePhoto();
      state = state.copyWith(
        status: ProfilePhotoStatus.success,
        clearPhoto: true,
        clearError: true,
      );
      // Invalidate session provider to refresh the UI globally
      _ref.invalidate(sessionDataProvider);
    } catch (e) {
      state = state.copyWith(
        status: ProfilePhotoStatus.error,
        errorMessage: e.toString().replaceAll('AppFailure: ', ''),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------
  void resetState() {
    state = const ProfilePhotoState();
  }

  // ---------------------------------------------------------------------------
  // Show photo picker bottom sheet helper
  // ---------------------------------------------------------------------------
  Future<void> showPhotoSourceSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PhotoSourceSheet(controller: this),
    );
  }
}

// =============================================================================
// Bottom Sheet Widgets
// =============================================================================

class _PhotoSourceSheet extends StatelessWidget {
  final ProfilePhotoController controller;
  const _PhotoSourceSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOption(
              context,
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                controller.pickFromCamera();
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.photo_library_rounded,
              label: 'Galeri Foto',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                controller.pickFromGallery();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
