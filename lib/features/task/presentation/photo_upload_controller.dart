import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/photo_upload_repository.dart';

// =============================================================================
// Upload State Machine — Sprint 7.1 Multi-Photo
// =============================================================================

/// Enum status upload foto (per-foto)
enum UploadStatus { idle, picking, uploading, success, error }

/// State untuk satu slot foto (satu dari max 3)
class PhotoSlotState {
  final UploadStatus status;
  final String? localImagePath;
  final String? remotePhotoPath;
  final double? uploadProgress;
  final String? errorMessage;

  const PhotoSlotState({
    this.status = UploadStatus.idle,
    this.localImagePath,
    this.remotePhotoPath,
    this.uploadProgress,
    this.errorMessage,
  });

  bool get hasPhoto => localImagePath != null && localImagePath!.isNotEmpty;
  bool get isUploading => status == UploadStatus.uploading;
  bool get isSuccess => status == UploadStatus.success;
  bool get isError => status == UploadStatus.error;

  PhotoSlotState copyWith({
    UploadStatus? status,
    String? localImagePath,
    String? remotePhotoPath,
    double? uploadProgress,
    String? errorMessage,
    bool clearLocalPath = false,
  }) {
    return PhotoSlotState(
      status: status ?? this.status,
      localImagePath: clearLocalPath ? null : (localImagePath ?? this.localImagePath),
      remotePhotoPath: remotePhotoPath ?? this.remotePhotoPath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  PhotoSlotState reset() => const PhotoSlotState();
}

/// State keseluruhan multi-photo upload
class MultiPhotoUploadState {
  /// Daftar slot foto — maksimum [PhotoUploadRepository.maxPhotosPerTask]
  final List<PhotoSlotState> slots;

  /// Index slot yang sedang aktif upload, null jika tidak ada
  final int? uploadingSlotIndex;

  /// Pesan error global (jika ada kegagalan fatal)
  final String? globalError;

  const MultiPhotoUploadState({
    this.slots = const [],
    this.uploadingSlotIndex,
    this.globalError,
  });

  /// Jumlah slot foto yang sudah diisi (ada localImagePath)
  int get photoCount => slots.where((s) => s.hasPhoto).length;

  /// Jumlah foto yang sudah berhasil diupload ke server
  int get uploadedCount => slots.where((s) => s.isSuccess).length;

  /// true jika semua slot yang terisi sudah berhasil diupload
  bool get allUploaded => photoCount > 0 && uploadedCount == photoCount;

  /// true jika ada yang sedang diupload
  bool get isUploading => uploadingSlotIndex != null;

  /// true jika minimal 1 foto dipilih
  bool get hasAnyPhoto => photoCount > 0;

  /// true jika masih bisa tambah foto (belum mencapai batas)
  bool get canAddMore => photoCount < PhotoUploadRepository.maxPhotosPerTask;

  MultiPhotoUploadState copyWith({
    List<PhotoSlotState>? slots,
    int? uploadingSlotIndex,
    String? globalError,
    bool clearUploadingSlot = false,
    bool clearGlobalError = false,
  }) {
    return MultiPhotoUploadState(
      slots: slots ?? this.slots,
      uploadingSlotIndex: clearUploadingSlot ? null : (uploadingSlotIndex ?? this.uploadingSlotIndex),
      globalError: clearGlobalError ? null : (globalError ?? this.globalError),
    );
  }

  MultiPhotoUploadState reset() => const MultiPhotoUploadState();
}

// =============================================================================
// Controller
// =============================================================================

class PhotoUploadController extends StateNotifier<MultiPhotoUploadState> {
  final PhotoUploadRepository _repository;

  PhotoUploadController(this._repository) : super(const MultiPhotoUploadState());

  // ---------------------------------------------------------------------------
  // Photo Management
  // ---------------------------------------------------------------------------

  /// Menambahkan foto baru ke slot berikutnya yang kosong.
  /// Diabaikan jika sudah mencapai batas [PhotoUploadRepository.maxPhotosPerTask].
  void addImage(File imageFile) {
    if (!state.canAddMore) return;

    final newSlots = List<PhotoSlotState>.from(state.slots)
      ..add(PhotoSlotState(
        status: UploadStatus.idle,
        localImagePath: imageFile.path,
      ));

    state = state.copyWith(slots: newSlots, clearGlobalError: true);
  }

  /// Menghapus foto pada slot [index].
  void removeImage(int index) {
    if (index < 0 || index >= state.slots.length) return;

    final newSlots = List<PhotoSlotState>.from(state.slots)..removeAt(index);
    state = state.copyWith(slots: newSlots, clearGlobalError: true);
  }

  /// Mengganti foto pada slot [index] dengan foto baru.
  void replaceImage(int index, File imageFile) {
    if (index < 0 || index >= state.slots.length) return;

    final newSlots = List<PhotoSlotState>.from(state.slots);
    newSlots[index] = PhotoSlotState(
      status: UploadStatus.idle,
      localImagePath: imageFile.path,
    );
    state = state.copyWith(slots: newSlots, clearGlobalError: true);
  }

  /// Dipanggil dari UI saat kamera/galeri sedang dibuka
  void onPickingStarted() {
    // Tidak mengubah slot, hanya sinyal UI
  }

  /// Dipanggil dari UI saat pemilihan foto dibatalkan
  void onPickingCancelled() {
    // Tidak ada state yang perlu diubah
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  /// Mengunggah semua foto yang ada ke backend secara sekuensial.
  ///
  /// Setiap foto diunggah satu per satu. Jika salah satu gagal,
  /// proses dilanjutkan ke foto berikutnya (tidak abort).
  ///
  /// Mengembalikan true jika semua foto berhasil diunggah.
  Future<bool> uploadAllPhotos({required int taskId}) async {
    if (!state.hasAnyPhoto) return false;
    if (state.isUploading) return false;

    bool allSuccess = true;

    for (int i = 0; i < state.slots.length; i++) {
      final slot = state.slots[i];

      // Skip slot yang sudah diupload sebelumnya
      if (slot.isSuccess) continue;
      // Skip slot yang tidak memiliki foto
      if (!slot.hasPhoto) continue;

      // Set state uploading untuk slot ini
      final uploadingSlots = List<PhotoSlotState>.from(state.slots);
      uploadingSlots[i] = slot.copyWith(
        status: UploadStatus.uploading,
        uploadProgress: 0.0,
      );
      state = state.copyWith(
        slots: uploadingSlots,
        uploadingSlotIndex: i,
        clearGlobalError: true,
      );

      try {
        final result = await _repository.uploadPhoto(
          taskId: taskId,
          imageFile: File(slot.localImagePath!),
          photoIndex: i + 1, // photoIndex adalah 1-based
          onSendProgress: (sent, total) {
            if (total > 0) {
              final currentSlots = List<PhotoSlotState>.from(state.slots);
              currentSlots[i] = currentSlots[i].copyWith(
                status: UploadStatus.uploading,
                uploadProgress: sent / total,
              );
              state = state.copyWith(slots: currentSlots);
            }
          },
        );

        // Sukses — update slot
        final successSlots = List<PhotoSlotState>.from(state.slots);
        successSlots[i] = slot.copyWith(
          status: UploadStatus.success,
          remotePhotoPath: result.photoPath,
          uploadProgress: 1.0,
        );
        state = state.copyWith(
          slots: successSlots,
          clearUploadingSlot: true,
        );
      } catch (e) {
        // Gagal — tandai slot error, lanjut ke foto berikutnya
        allSuccess = false;
        final errorSlots = List<PhotoSlotState>.from(state.slots);
        errorSlots[i] = slot.copyWith(
          status: UploadStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
        state = state.copyWith(
          slots: errorSlots,
          clearUploadingSlot: true,
        );
      }
    }

    return allSuccess;
  }

  /// Reset semua slot ke kondisi awal (idle)
  void reset() {
    state = state.reset();
  }
}

// =============================================================================
// Providers
// =============================================================================

/// Provider family berdasarkan taskId agar setiap task memiliki state upload sendiri
final photoUploadControllerProvider = StateNotifierProvider.family<
    PhotoUploadController, MultiPhotoUploadState, int>((ref, taskId) {
  final repository = ref.watch(photoUploadRepositoryProvider);
  return PhotoUploadController(repository);
});

/// Pintasan alias reaktif untuk mendapatkan MultiPhotoUploadState berdasarkan taskId
final photoUploadProvider =
    Provider.family<MultiPhotoUploadState, int>((ref, taskId) {
  return ref.watch(photoUploadControllerProvider(taskId));
});

// ---------------------------------------------------------------------------
// Backward-compat: alias untuk kode lama yang masih menggunakan PhotoUploadState
// ---------------------------------------------------------------------------

/// @deprecated Gunakan [MultiPhotoUploadState] dan [photoUploadProvider].
/// Disediakan agar kode lama tidak break sebelum dimigrasi penuh.
typedef PhotoUploadState = MultiPhotoUploadState;
