import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/photo_upload_repository.dart';
import 'photo_upload_controller.dart';
import 'task_detail_controller.dart';
import '../../attendance/presentation/attendance_controller.dart';

class TakePhotoScreen extends ConsumerStatefulWidget {
  /// Menerima taskId sebagai integer untuk kompatibilitas dengan backend
  final int taskId;

  const TakePhotoScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TakePhotoScreen> createState() => _TakePhotoScreenState();
}

class _TakePhotoScreenState extends ConsumerState<TakePhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Langsung buka dialog rationale → kamera untuk foto pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestCameraPermission();
    });
  }

  // ---------------------------------------------------------------------------
  // Camera Permission Flow
  // ---------------------------------------------------------------------------

  Future<void> _checkAndRequestCameraPermission() async {
    if (!mounted) return;
    final bool? shouldProceed = await _showCameraRationaleDialog();
    if (shouldProceed == true && mounted) {
      await _openCamera();
    }
  }

  Future<bool?> _showCameraRationaleDialog() async {
    if (!mounted) return null;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(Icons.camera_alt_rounded, size: 48, color: theme.colorScheme.primary),
          title: const Text('Izin Kamera Diperlukan', textAlign: TextAlign.center),
          content: const Text(
            'Aplikasi membutuhkan akses kamera untuk mengambil foto bukti penyelesaian tugas. '
            'Foto ini akan dikirim ke server sebagai verifikasi pekerjaan Anda.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Izinkan Kamera'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCameraPermanentlyDeniedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(Icons.no_photography_rounded, size: 48, color: theme.colorScheme.error),
          title: const Text('Kamera Tidak Bisa Diakses', textAlign: TextAlign.center),
          content: const Text(
            'Izin kamera telah ditolak secara permanen. Buka pengaturan aplikasi '
            'untuk mengaktifkan izin kamera secara manual.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Geolocator.openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCameraDeniedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.orange),
        title: const Text('Izin Kamera Ditolak', textAlign: TextAlign.center),
        content: const Text(
          'Izin kamera diperlukan untuk mengambil foto bukti kerja. '
          'Silakan coba lagi dan berikan izin kamera.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _openCamera();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo Picking
  // ---------------------------------------------------------------------------

  /// Membuka kamera dan menambahkan foto ke slot berikutnya
  Future<void> _openCamera({int? replaceIndex}) async {
    if (!mounted) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 90, // Kompresi awal via image_picker; flutter_image_compress menangani selebihnya
      );

      if (!mounted) return;

      if (photo != null) {
        final file = File(photo.path);
        if (replaceIndex != null) {
          ref
              .read(photoUploadControllerProvider(widget.taskId).notifier)
              .replaceImage(replaceIndex, file);
        } else {
          ref
              .read(photoUploadControllerProvider(widget.taskId).notifier)
              .addImage(file);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('permanently') || errStr.contains('denied_forever')) {
        await _showCameraPermanentlyDeniedDialog();
      } else if (errStr.contains('denied') || errStr.contains('permission')) {
        await _showCameraDeniedDialog();
      } else {
        _showError('Gagal membuka kamera: $e');
      }
    }
  }

  /// Membuka galeri dan menambahkan foto ke slot berikutnya
  Future<void> _openGallery({int? replaceIndex}) async {
    if (!mounted) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 90,
      );

      if (!mounted) return;

      if (photo != null) {
        final file = File(photo.path);
        if (replaceIndex != null) {
          ref
              .read(photoUploadControllerProvider(widget.taskId).notifier)
              .replaceImage(replaceIndex, file);
        } else {
          ref
              .read(photoUploadControllerProvider(widget.taskId).notifier)
              .addImage(file);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal membuka galeri: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  Future<void> _onSubmitPressed() async {
    final attendanceState = ref.read(attendanceControllerProvider);
    final isAttendanceActive = attendanceState.status == AttendanceStatus.checkedIn;
    
    if (!isAttendanceActive) {
      _showError('Akses ditolak. Sesi absensi Anda tidak aktif. Silakan Check-In terlebih dahulu.');
      return;
    }

    final uploadState = ref.read(photoUploadProvider(widget.taskId));

    if (!uploadState.hasAnyPhoto) {
      _showError('Minimal 1 foto bukti wajib diambil sebelum menyimpan.');
      return;
    }

    if (uploadState.isUploading) return;

    final allSuccess = await ref
        .read(photoUploadControllerProvider(widget.taskId).notifier)
        .uploadAllPhotos(taskId: widget.taskId);

    if (!mounted) return;

    if (allSuccess) {
      _showSuccess('✓ Semua foto bukti berhasil diunggah!');

      // Update status tugas menjadi 'Completed'
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .updateStatus('Completed');

      // Refresh task detail agar data sinkron dengan backend
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .refreshTaskDetail();

      if (!mounted) return;
      context.go('/dashboard');
    } else {
      _showError('Beberapa foto gagal diunggah. Cek koneksi dan coba lagi.');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPickSourceSheet({int? replaceIndex}) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _openCamera(replaceIndex: replaceIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _openGallery(replaceIndex: replaceIndex);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(photoUploadProvider(widget.taskId));
    final theme = Theme.of(context);
    final maxPhotos = PhotoUploadRepository.maxPhotosPerTask;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Bukti Penyelesaian'),
        actions: [
          if (uploadState.hasAnyPhoto && !uploadState.isUploading && !uploadState.allUploaded)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset semua foto',
              onPressed: () {
                ref
                    .read(photoUploadControllerProvider(widget.taskId).notifier)
                    .reset();
                _openCamera();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----------------------------------------------------------------
            // Header Info
            // ----------------------------------------------------------------
            const SectionHeader(title: 'Foto Bukti Pekerjaan'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ambil minimal 1 foto, maksimal $maxPhotos foto sebagai bukti penyelesaian.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------------------
            // Multi-Photo Grid
            // ----------------------------------------------------------------
            AppCard(
              child: Column(
                children: [
                  // Progress count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${uploadState.photoCount} dari $maxPhotos foto dipilih',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (uploadState.allUploaded)
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Semua terupload',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grid slot foto
                  Row(
                    children: List.generate(maxPhotos, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index < maxPhotos - 1 ? 8.0 : 0.0),
                          child: _buildPhotoSlot(context, uploadState, index),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------------------
            // Upload Progress Cards (per slot yang sedang upload)
            // ----------------------------------------------------------------
            ...List.generate(uploadState.slots.length, (i) {
              final slot = uploadState.slots[i];
              if (!slot.isUploading) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mengunggah foto ${i + 1}...',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            '${((slot.uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: slot.uploadProgress,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ----------------------------------------------------------------
            // Error cards per slot
            // ----------------------------------------------------------------
            ...List.generate(uploadState.slots.length, (i) {
              final slot = uploadState.slots[i];
              if (!slot.isError || slot.errorMessage == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Foto ${i + 1}: ${slot.errorMessage}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showPickSourceSheet(replaceIndex: i),
                        child: const Text('Ganti', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // Tombol Tambah Foto (tampil jika masih bisa tambah)
            // ----------------------------------------------------------------
            if (uploadState.canAddMore && !uploadState.isUploading && !uploadState.allUploaded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _showPickSourceSheet(),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(
                    uploadState.photoCount == 0
                        ? 'Ambil Foto Pertama'
                        : 'Tambah Foto (${uploadState.photoCount}/$maxPhotos)',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),

            // ----------------------------------------------------------------
            // Tombol Utama Submit
            // ----------------------------------------------------------------
            CustomButton(
              text: uploadState.allUploaded
                  ? '✓ SEMUA FOTO BERHASIL DIUNGGAH'
                  : uploadState.isUploading
                      ? 'Mengunggah...'
                      : 'SIMPAN & SELESAIKAN TUGAS',
              backgroundColor: uploadState.allUploaded
                  ? Colors.grey
                  : uploadState.isUploading
                      ? Colors.blueGrey
                      : Colors.green.shade700,
              icon: uploadState.allUploaded
                  ? const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18)
                  : (!uploadState.isUploading && uploadState.hasAnyPhoto)
                      ? const Icon(Icons.upload_rounded, color: Colors.white, size: 18)
                      : null,
              isLoading: uploadState.isUploading,
              onPressed: (uploadState.isUploading ||
                      uploadState.allUploaded ||
                      !uploadState.hasAnyPhoto)
                  ? null
                  : _onSubmitPressed,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo Slot Widget
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSlot(
    BuildContext context,
    MultiPhotoUploadState uploadState,
    int index,
  ) {
    final theme = Theme.of(context);
    final hasSlot = index < uploadState.slots.length;
    final slot = hasSlot ? uploadState.slots[index] : null;
    final hasPhoto = slot?.hasPhoto ?? false;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: slot?.isError == true
                ? Colors.red.shade400
                : slot?.isSuccess == true
                    ? Colors.green.shade400
                    : const Color(0xFFDADCE0),
            width: slot?.isError == true || slot?.isSuccess == true ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? _buildFilledSlot(context, slot!, index, uploadState)
            : _buildEmptySlot(context, theme, index, uploadState),
      ),
    );
  }

  Widget _buildFilledSlot(
    BuildContext context,
    PhotoSlotState slot,
    int index,
    MultiPhotoUploadState uploadState,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto preview
        Image.file(
          File(slot.localImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: Colors.grey,
          ),
        ),

        // Overlay status
        if (slot.isUploading)
          Container(
            color: Colors.black.withAlpha(130),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 4),
                Text(
                  '${((slot.uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          )
        else if (slot.isSuccess)
          Container(
            color: Colors.green.withAlpha(160),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 32,
            ),
          )
        else if (slot.isError)
          Container(
            color: Colors.red.withAlpha(130),
            child: const Icon(
              Icons.error_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

        // Label nomor foto
        Positioned(
          left: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Tombol hapus / ganti (hanya saat idle / error)
        if (!slot.isUploading && !slot.isSuccess)
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => ref
                  .read(photoUploadControllerProvider(widget.taskId).notifier)
                  .removeImage(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),

        // Tombol ganti (tap pada foto)
        if (!slot.isUploading && !slot.isSuccess)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showPickSourceSheet(replaceIndex: index),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySlot(
    BuildContext context,
    ThemeData theme,
    int index,
    MultiPhotoUploadState uploadState,
  ) {
    final isNextSlot = uploadState.photoCount == index;
    final canAdd = uploadState.canAddMore && isNextSlot;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAdd ? () => _showPickSourceSheet() : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canAdd ? Icons.add_photo_alternate_outlined : Icons.lock_outline_rounded,
              size: 28,
              color: canAdd ? theme.colorScheme.primary : Colors.grey[300],
            ),
            const SizedBox(height: 4),
            Text(
              canAdd ? 'Tambah' : '—',
              style: TextStyle(
                fontSize: 11,
                color: canAdd ? theme.colorScheme.primary : Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
