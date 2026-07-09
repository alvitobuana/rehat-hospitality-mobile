import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart'; // untuk openAppSettings
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/section_header.dart';
import 'photo_upload_controller.dart';
import 'task_detail_controller.dart';

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

  @override
  void initState() {
    super.initState();
    // Cek camera permission dulu, baru buka kamera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestCameraPermission();
    });
  }

  // ---------------------------------------------------------------------------
  // Camera Permission Flow
  // ---------------------------------------------------------------------------

  /// Mengelola alur izin kamera sebelum membuka kamera.
  ///
  /// Flow:
  /// 1. Jika granted → langsung buka kamera
  /// 2. Jika belum diminta → tampilkan rationale → minta permission
  /// 3. Jika denied → tampilkan dialog "Coba Lagi"
  /// 4. Jika permanently denied → tampilkan dialog "Buka Pengaturan"
  Future<void> _checkAndRequestCameraPermission() async {
    if (!mounted) return;

    // image_picker menangani permission sendiri, namun kita tampilkan
    // rationale dialog terlebih dahulu untuk UX yang lebih baik.
    // Deteksi status dengan mencoba pick image dan menangkap hasilnya.
    final bool? shouldProceed = await _showCameraRationaleDialog();
    if (shouldProceed == true && mounted) {
      await _openCamera();
    } else if (mounted) {
      // User membatalkan dari dialog rationale
      ref
          .read(photoUploadControllerProvider(widget.taskId).notifier)
          .onPickingCancelled();
    }
  }

  /// Menampilkan dialog penjelasan sebelum meminta permission kamera.
  /// Mengembalikan true jika user setuju untuk melanjutkan.
  Future<bool?> _showCameraRationaleDialog() async {
    if (!mounted) return null;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(
            Icons.camera_alt_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          title: const Text(
            'Izin Kamera Diperlukan',
            textAlign: TextAlign.center,
          ),
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

  /// Menampilkan dialog ketika camera permission ditolak permanen.
  Future<void> _showCameraPermanentlyDeniedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(
            Icons.no_photography_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          title: const Text(
            'Kamera Tidak Bisa Diakses',
            textAlign: TextAlign.center,
          ),
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
                // Menggunakan geolocator openAppSettings karena sudah tersedia
                await Geolocator.openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan dialog ketika camera permission ditolak (masih bisa coba lagi).
  Future<void> _showCameraDeniedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.camera_alt_outlined,
          size: 48,
          color: Colors.orange,
        ),
        title: const Text(
          'Izin Kamera Ditolak',
          textAlign: TextAlign.center,
        ),
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

  Future<void> _openCamera() async {
    if (!mounted) return;
    ref.read(photoUploadControllerProvider(widget.taskId).notifier).onPickingStarted();

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 85, // ~85% kualitas: cukup untuk bukti kerja, hemat bandwidth
      );

      if (!mounted) return;

      if (photo != null) {
        ref
            .read(photoUploadControllerProvider(widget.taskId).notifier)
            .onImagePicked(File(photo.path));
      } else {
        // User membatalkan pemilihan foto
        ref
            .read(photoUploadControllerProvider(widget.taskId).notifier)
            .onPickingCancelled();
      }
    } catch (e) {
      if (!mounted) return;
      // Deteksi apakah error disebabkan permission yang ditolak
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('permanently') || errStr.contains('denied_forever')) {
        ref.read(photoUploadControllerProvider(widget.taskId).notifier).onPickingCancelled();
        await _showCameraPermanentlyDeniedDialog();
      } else if (errStr.contains('denied') || errStr.contains('permission')) {
        ref.read(photoUploadControllerProvider(widget.taskId).notifier).onPickingCancelled();
        await _showCameraDeniedDialog();
      } else {
        ref.read(photoUploadControllerProvider(widget.taskId).notifier).onPickingCancelled();
        _showError('Gagal membuka kamera: $e');
      }
    }
  }

  Future<void> _openGallery() async {
    if (!mounted) return;
    ref.read(photoUploadControllerProvider(widget.taskId).notifier).onPickingStarted();

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (photo != null) {
        ref
            .read(photoUploadControllerProvider(widget.taskId).notifier)
            .onImagePicked(File(photo.path));
      } else {
        ref
            .read(photoUploadControllerProvider(widget.taskId).notifier)
            .onPickingCancelled();
      }
    } catch (e) {
      if (!mounted) return;
      ref
          .read(photoUploadControllerProvider(widget.taskId).notifier)
          .onPickingCancelled();
      _showError('Gagal membuka galeri: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  Future<void> _onSubmitPressed() async {
    final uploadState = ref.read(photoUploadProvider(widget.taskId));

    if (uploadState.localImagePath == null) {
      _showError('Foto bukti wajib diambil sebelum menyimpan.');
      return;
    }

    if (uploadState.isBusy) return;

    await ref
        .read(photoUploadControllerProvider(widget.taskId).notifier)
        .uploadPhoto(taskId: widget.taskId);

    // Setelah upload selesai, cek state terbaru
    final resultState = ref.read(photoUploadProvider(widget.taskId));
    if (!mounted) return;

    if (resultState.isSuccess) {
      _showSuccess('✓ Foto bukti berhasil diunggah!');

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
    }
    // Error sudah ditampilkan oleh listener di build()
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(photoUploadProvider(widget.taskId));

    // Listen untuk error — tampilkan SnackBar secara otomatis
    ref.listen<PhotoUploadState>(
      photoUploadProvider(widget.taskId),
      (previous, next) {
        if (next.isError && next.errorMessage != null) {
          _showError(next.errorMessage!);
        }
      },
    );

    final localPath = uploadState.localImagePath;
    final hasPhoto = localPath != null && localPath.isNotEmpty;
    final isBusy = uploadState.isBusy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Bukti Penyelesaian'),
        actions: [
          // Tombol reset hanya tampil jika ada foto dan tidak sedang upload
          if (hasPhoto && !isBusy)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Ambil ulang foto',
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
            // Preview Box
            // ----------------------------------------------------------------
            const SectionHeader(title: 'Preview Foto Bukti'),
            AppCard(
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDADCE0)),
                ),
                alignment: Alignment.center,
                child: _buildPreview(uploadState, hasPhoto, localPath),
              ),
            ),

            // ----------------------------------------------------------------
            // Upload Progress Bar (tampil hanya saat uploading)
            // ----------------------------------------------------------------
            if (uploadState.isUploading) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mengunggah foto...',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          '${((uploadState.uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: uploadState.uploadProgress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ],

            // ----------------------------------------------------------------
            // Info sukses (remote path)
            // ----------------------------------------------------------------
            if (uploadState.isSuccess && uploadState.remotePhotoPath != null) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tersimpan di server: ${uploadState.remotePhotoPath}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // Tombol aksi ambil foto
            // ----------------------------------------------------------------
            if (!isBusy && !uploadState.isSuccess) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Kamera'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ----------------------------------------------------------------
            // Tombol utama Submit
            // ----------------------------------------------------------------
            CustomButton(
              text: uploadState.isSuccess
                  ? '✓ FOTO BERHASIL DIUNGGAH'
                  : isBusy
                      ? 'Mengunggah...'
                      : 'SIMPAN & SELESAIKAN TUGAS',
              backgroundColor: uploadState.isSuccess
                  ? Colors.grey
                  : isBusy
                      ? Colors.blueGrey
                      : Colors.green.shade700,
              icon: uploadState.isSuccess
                  ? const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18)
                  : !isBusy && hasPhoto
                      ? const Icon(Icons.upload_rounded,
                          color: Colors.white, size: 18)
                      : null,
              isLoading: uploadState.isUploading,
              onPressed: (isBusy || uploadState.isSuccess || !hasPhoto)
                  ? null
                  : _onSubmitPressed,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview Widget
  // ---------------------------------------------------------------------------

  Widget _buildPreview(
    PhotoUploadState uploadState,
    bool hasPhoto,
    String? localPath,
  ) {
    // Sedang memilih foto
    if (uploadState.isPicking) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Membuka kamera...', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    // Foto sudah dipilih atau sedang diupload
    if (hasPhoto && localPath != null) {
      final file = File(localPath);
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              file,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
          // Overlay blur saat uploading
          if (uploadState.isUploading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mengunggah...',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          // Badge sukses
          if (uploadState.isSuccess)
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(180),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Foto Berhasil Diunggah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // Default: belum ada foto
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        const Text(
          'Belum ada foto.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _openCamera,
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: const Text('Buka Kamera'),
        ),
      ],
    );
  }
}
