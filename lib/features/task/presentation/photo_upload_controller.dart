import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/photo_upload_repository.dart';

// =============================================================================
// Upload State Machine
// =============================================================================

/// Enum status upload foto
enum UploadStatus { idle, picking, uploading, success, error }

/// State untuk proses upload foto
class PhotoUploadState {
  final UploadStatus status;

  /// Progres upload: 0.0 – 1.0 (null saat tidak ada progress)
  final double? uploadProgress;

  /// Path foto lokal yang dipilih user
  final String? localImagePath;

  /// URL / path foto dari server (tersedia setelah sukses)
  final String? remotePhotoPath;

  /// Pesan error jika status == error
  final String? errorMessage;

  const PhotoUploadState({
    this.status = UploadStatus.idle,
    this.uploadProgress,
    this.localImagePath,
    this.remotePhotoPath,
    this.errorMessage,
  });

  bool get isIdle => status == UploadStatus.idle;
  bool get isPicking => status == UploadStatus.picking;
  bool get isUploading => status == UploadStatus.uploading;
  bool get isSuccess => status == UploadStatus.success;
  bool get isError => status == UploadStatus.error;
  bool get isBusy => isPicking || isUploading;

  PhotoUploadState copyWith({
    UploadStatus? status,
    double? uploadProgress,
    String? localImagePath,
    String? remotePhotoPath,
    String? errorMessage,
  }) {
    return PhotoUploadState(
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      localImagePath: localImagePath ?? this.localImagePath,
      remotePhotoPath: remotePhotoPath ?? this.remotePhotoPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Reset ke state idle bersih
  PhotoUploadState reset() {
    return const PhotoUploadState(status: UploadStatus.idle);
  }
}

// =============================================================================
// Controller
// =============================================================================

class PhotoUploadController extends StateNotifier<PhotoUploadState> {
  final PhotoUploadRepository _repository;

  PhotoUploadController(this._repository) : super(const PhotoUploadState());

  /// Dipanggil dari UI saat user memilih foto dari picker (langkah 1)
  void onImagePicked(File imageFile) {
    state = PhotoUploadState(
      status: UploadStatus.idle,
      localImagePath: imageFile.path,
    );
  }

  /// Dipanggil dari UI saat kamera/galeri sedang dibuka (langkah 0)
  void onPickingStarted() {
    state = state.copyWith(status: UploadStatus.picking);
  }

  /// Dipanggil dari UI saat pemilihan foto dibatalkan
  void onPickingCancelled() {
    state = state.copyWith(status: UploadStatus.idle);
  }

  /// Mengunggah foto ke backend.
  ///
  /// Alur:
  /// 1. Validasi ada foto yang dipilih.
  /// 2. Set state ke [UploadStatus.uploading].
  /// 3. Kirim POST multipart ke backend dengan progress callback.
  /// 4. Sukses → set state ke [UploadStatus.success] dengan remotePhotoPath.
  /// 5. Gagal → set state ke [UploadStatus.error] dengan pesan error.
  Future<void> uploadPhoto({required int taskId}) async {
    final localPath = state.localImagePath;
    if (localPath == null || localPath.isEmpty) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Belum ada foto yang dipilih.',
      );
      return;
    }

    // Guard: cegah double upload
    if (state.isUploading) return;

    state = PhotoUploadState(
      status: UploadStatus.uploading,
      localImagePath: localPath,
      uploadProgress: 0.0,
    );

    try {
      final result = await _repository.uploadPhoto(
        taskId: taskId,
        imageFile: File(localPath),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            state = state.copyWith(
              status: UploadStatus.uploading,
              uploadProgress: progress,
            );
          }
        },
      );

      state = PhotoUploadState(
        status: UploadStatus.success,
        localImagePath: localPath,
        remotePhotoPath: result.photoPath,
        uploadProgress: 1.0,
      );
    } catch (e) {
      state = PhotoUploadState(
        status: UploadStatus.error,
        localImagePath: localPath,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Reset ke state idle untuk mengulang proses dari awal
  void reset() {
    state = state.reset();
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Provider family berdasarkan taskId agar setiap task memiliki state upload sendiri
final photoUploadControllerProvider = StateNotifierProvider.family<
    PhotoUploadController, PhotoUploadState, int>((ref, taskId) {
  final repository = ref.watch(photoUploadRepositoryProvider);
  return PhotoUploadController(repository);
});

/// Pintasan alias reaktif untuk mendapatkan PhotoUploadState berdasarkan taskId
final photoUploadProvider =
    Provider.family<PhotoUploadState, int>((ref, taskId) {
  return ref.watch(photoUploadControllerProvider(taskId));
});
