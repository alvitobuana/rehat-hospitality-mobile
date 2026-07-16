import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/storage/session_manager.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../data/maintenance_repository.dart';

class CompressedPhoto {
  final File file;
  final int originalSize;
  final int compressedSize;

  CompressedPhoto({
    required this.file,
    required this.originalSize,
    required this.compressedSize,
  });
}

class MaintenanceReportScreen extends ConsumerStatefulWidget {
  const MaintenanceReportScreen({super.key});

  @override
  ConsumerState<MaintenanceReportScreen> createState() => _MaintenanceReportScreenState();
}

class _MaintenanceReportScreenState extends ConsumerState<MaintenanceReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Form Fields
  String _locationType = 'ROOM'; // 'ROOM' or 'COMMON_AREA'
  int? _selectedRoomId;
  String? _selectedCommonArea;
  final _customLocationController = TextEditingController();
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  final List<CompressedPhoto> _selectedPhotos = [];

  // State flags
  bool _isLoadingRooms = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _rooms = [];
  String? _roomErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoomsForHotel();
    });
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomsForHotel() async {
    final session = await ref.read(sessionDataProvider.future);
    final hotelId = session.hotelId;
    if (hotelId == null || hotelId.isEmpty) return;

    setState(() {
      _isLoadingRooms = true;
      _roomErrorMessage = null;
    });

    try {
      final repo = ref.read(maintenanceRepositoryProvider);
      final roomsList = await repo.getRooms(hotelId);
      setState(() {
        _rooms = roomsList;
        _isLoadingRooms = false;
      });
    } catch (e) {
      setState(() {
        _roomErrorMessage = 'Gagal memuat kamar: $e';
        _isLoadingRooms = false;
      });
    }
  }

  // Image compression
  Future<File> _compressImage(File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      CompressFormat format = (ext == 'png') ? CompressFormat.png : CompressFormat.jpeg;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_maint_$timestamp.$ext';

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 83, // JPEG Quality 80-85%
        minWidth: 1920,
        minHeight: 1920,
        format: format,
        keepExif: true,
      );

      if (compressedXFile != null) {
        final compressed = File(compressedXFile.path);
        final originalSize = await imageFile.length();
        final compressedSize = await compressed.length();
        if (compressedSize < originalSize) {
          return compressed;
        }
      }
    } catch (_) {}
    return imageFile;
  }

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimum 3 foto diperbolehkan.')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) return;

    setState(() {
      _isSubmitting = true; // Temporary lock UI during compression
    });

    try {
      final originalFile = File(image.path);
      final originalSize = await originalFile.length();
      final compressedFile = await _compressImage(originalFile);
      final compressedSize = await compressedFile.length();

      // Client side safety validation
      if (compressedSize > 3 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran foto hasil kompresi masih melebihi 3MB. Silakan ambil foto ulang.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedPhotos.add(CompressedPhoto(
          file: compressedFile,
          originalSize: originalSize,
          compressedSize: compressedSize,
        ));
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap sertakan minimal 1 foto bukti kerusakan.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await ref.read(sessionDataProvider.future);
      final hotelId = session.hotelId;
      if (hotelId == null || hotelId.isEmpty) {
        throw Exception('Hotel assignment tidak ditemukan.');
      }

      final repo = ref.read(maintenanceRepositoryProvider);
      final success = await repo.submitReport(
        hotelId: hotelId,
        locationType: _locationType,
        roomId: _locationType == 'ROOM' ? _selectedRoomId : null,
        commonArea: _locationType == 'COMMON_AREA' ? _selectedCommonArea : null,
        customLocation: _locationType == 'COMMON_AREA' &&
                (_selectedCommonArea == 'Lainnya' || _selectedCommonArea == 'Lainnya (Isi Lokasi)')
            ? _customLocationController.text.trim()
            : null,
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        photos: _selectedPhotos.map((p) => p.file).toList(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan kerusakan berhasil terkirim ke Admin.'),
              backgroundColor: Colors.green,
            ),
          );
          // Reset form state
          setState(() {
            _selectedRoomId = null;
            _selectedCommonArea = null;
            _selectedCategory = null;
            _customLocationController.clear();
            _descriptionController.clear();
            _selectedPhotos.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDataProvider);

    // List of common areas
    final commonAreas = [
      'Lobby',
      'Koridor',
      'Lift',
      'Tangga',
      'Parkiran',
      'Restoran',
      'Kolam Renang',
      'Laundry',
      'Gudang',
      'Toilet Umum',
      'Mushola',
      'Lainnya (Isi Lokasi)'
    ];

    // List of categories
    final categories = [
      'AC',
      'TV',
      'Lampu',
      'Furniture',
      'Kamar Mandi',
      'Kelistrikan',
      'Plumbing',
      'Internet / WiFi',
      'Pintu',
      'Jendela',
      'Kebersihan',
      'Lainnya'
    ];

    return AppPage(
      title: 'Lapor Kerusakan Fasilitas',
      useSafeArea: true,
      scrollable: true,
      padding: EdgeInsets.only(
        left: AppInsets.s20,
        right: AppInsets.s20,
        top: AppInsets.s20,
        bottom: AppInsets.s20 + AppInsets.bottomSafe(context),
      ),
      child: sessionAsync.when(
        data: (session) => Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hotel Name (Read Only)
              const Text(
                'HOTEL / PROPERTI',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.hotel_rounded, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        session.hotelName ?? 'Rehat Properti',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Lokasi Kerusakan Selection
              const Text(
                'JENIS LOKASI',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Kamar')),
                      selected: _locationType == 'ROOM',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _locationType = 'ROOM';
                            _selectedCommonArea = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Area Umum')),
                      selected: _locationType == 'COMMON_AREA',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _locationType = 'COMMON_AREA';
                            _selectedRoomId = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Conditional Room/Common Area selection
              if (_locationType == 'ROOM') ...[
                const Text(
                  'NOMOR KAMAR *',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                if (_isLoadingRooms)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                else if (_roomErrorMessage != null)
                  Text(
                    _roomErrorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  )
                else
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Pilih Nomor Kamar'),
                    value: _selectedRoomId,
                    items: _rooms.map((room) {
                      return DropdownMenuItem<int>(
                        value: room['id'] as int,
                        child: Text('Kamar ${room['room_number']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRoomId = val;
                      });
                    },
                    validator: (val) {
                      if (_locationType == 'ROOM' && val == null) {
                        return 'Harap pilih nomor kamar.';
                      }
                      return null;
                    },
                  ),
              ] else ...[
                const Text(
                  'LOKASI AREA UMUM *',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: const Text('Pilih Area Umum'),
                  value: _selectedCommonArea,
                  items: commonAreas.map((area) {
                    return DropdownMenuItem<String>(
                      value: area,
                      child: Text(area),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCommonArea = val;
                    });
                  },
                  validator: (val) {
                    if (_locationType == 'COMMON_AREA' && (val == null || val.isEmpty)) {
                      return 'Harap pilih lokasi area umum.';
                    }
                    return null;
                  },
                ),
                if (_selectedCommonArea == 'Lainnya (Isi Lokasi)' || _selectedCommonArea == 'Lainnya') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'LOKASI DETAIL *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _customLocationController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Koridor belakang lantai 2',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) {
                      if (_locationType == 'COMMON_AREA' &&
                          (_selectedCommonArea == 'Lainnya' || _selectedCommonArea == 'Lainnya (Isi Lokasi)') &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Lokasi detail wajib diisi.';
                      }
                      return null;
                    },
                  ),
                ],
              ],
              const SizedBox(height: 16),

              // 4. Kategori Kerusakan
              const Text(
                'KATEGORI KERUSAKAN *',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Pilih Kategori Kerusakan'),
                value: _selectedCategory,
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Harap pilih kategori kerusakan.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. Deskripsi
              const Text(
                'DESKRIPSI KERUSAKAN *',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tulis deskripsi detail mengenai kerusakan...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Deskripsi kerusakan wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 6. Photo Upload Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOTO BUKTI KERUSAKAN (${_selectedPhotos.length}/3) *',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  if (_selectedPhotos.length < 3)
                    TextButton.icon(
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: const Text('Ambil Foto', style: TextStyle(fontSize: 12)),
                      onPressed: _isSubmitting ? null : _pickImage,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_selectedPhotos.isEmpty)
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha(40)),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada foto. Ambil minimal 1 foto.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.52,
                  ),
                  itemCount: _selectedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = _selectedPhotos[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Image Preview with delete overlay
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  photo.file,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 2. Beautiful original -> compressed comparison details
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.withAlpha(25)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Original',
                                style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(photo.originalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                                style: const TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_downward, size: 8, color: Colors.blue),
                              const Text(
                                'Compressed',
                                style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(photo.compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                                style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_downward, size: 8, color: Colors.blue),
                              const Text(
                                'Upload',
                                style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 24),

              // 7. Submit Button
              AppPrimaryButton(
                text: 'Kirim Laporan',
                onPressed: _isSubmitting ? null : _submitForm,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal membaca sesi: $err')),
      ),
    );
  }
}
