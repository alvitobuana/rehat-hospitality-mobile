import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import '../theme/app_theme.dart';


class LostFoundStaffScreen extends StatefulWidget {
  const LostFoundStaffScreen({Key? key}) : super(key: key);

  @override
  State<LostFoundStaffScreen> createState() => _LostFoundStaffScreenState();
}

class _LostFoundStaffScreenState extends State<LostFoundStaffScreen> {
  final MockState _state = MockState();
  String _selectedStatusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  // Show Bottom Sheet to report Lost & Found
  void _showReportLFDialog() {
    final roomCtrl = TextEditingController();
    final itemCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    String category = 'Elektronik';
    String location = 'Di bawah tempat tidur';
    String condition = 'Baik';
    String valueEst = 'Sedang (Rp 100rb – 1jt)';
    String handover = 'Disimpan di Housekeeping';

    final categories = ['Elektronik', 'Dokumen / ID', 'Pakaian', 'Perhiasan / Aksesori', 'Uang / Dompet', 'Tas / Koper', 'Lainnya'];
    final locations = [
      'Di bawah tempat tidur', 'Di dalam laci', 'Di lemari pakaian',
      'Di kamar mandi', 'Di meja nakas', 'Di sofa / kursi',
      'Di belakang pintu', 'Lainnya'
    ];
    final conditions = ['Baik', 'Rusak sebagian', 'Tidak diketahui'];
    final values = [
      'Rendah (< Rp 100rb)',
      'Sedang (Rp 100rb – 1jt)',
      'Tinggi (> Rp 1jt)',
      'Tidak diketahui'
    ];
    final handovers = [
      'Disimpan di Housekeeping',
      'Diserahkan ke Front Office',
      'Diserahkan ke Leader/Supervisor'
    ];

    bool hasPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lapor Barang Temuan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Mock Photo capture
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FOTO BARANG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            setModalState(() => hasPhoto = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Foto barang ditambahkan!'), backgroundColor: Colors.green),
                            );
                          },
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE4E8F0)),
                            ),
                            child: hasPhoto
                                ? Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            'https://images.unsplash.com/photo-1546868871-7041f2a55e12?q=80&w=400&auto=format&fit=crop',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                            onPressed: () => setModalState(() => hasPhoto = false),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 28, color: Color(0xFF9AA3B2)),
                                      SizedBox(height: 4),
                                      Text('Ambil Foto Barang', style: TextStyle(fontSize: 12, color: Color(0xFF5A6478), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Kamar Ditemukan',
                            hintText: '101, 202...',
                            controller: roomCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LOKASI DI KAMAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: location,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => location = val!),
                                    items: locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KATEGORI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: category,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => category = val!),
                                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Nama Barang',
                            hintText: 'Handphone Samsung, dll.',
                            controller: itemCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KONDISI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: condition,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => condition = val!),
                                    items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ESTIMASI NILAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: valueEst,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => valueEst = val!),
                                    items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DISERAHKAN KE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: handover,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                              onChanged: (val) => setModalState(() => handover = val!),
                              items: handovers.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: 'Deskripsi Detail Barang',
                      hintText: 'Warna, merk, ciri khas barang temuan...',
                      controller: descCtrl,
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Simpan Laporan',
                      onPressed: () {
                        if (roomCtrl.text.isEmpty || itemCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No. Kamar dan Nama Barang wajib diisi!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        _state.addLostFound(
                          roomCtrl.text.trim(),
                          category,
                          itemCtrl.text.trim(),
                          location,
                          descCtrl.text.trim(),
                          condition,
                          valueEst,
                          handover,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Barang Temuan berhasil dilaporkan!'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _state.currentUser!;

    final staffItems = _state.lostFoundItems
        .where((item) => item.reportedBy == user.name && item.hotelUnit == user.hotelUnit)
        .toList();

    final filteredItems = staffItems.where((item) {
      if (_selectedStatusFilter == 'Semua') return true;
      return item.status == _selectedStatusFilter;
    }).toList();

    // Stats calculations
    final storedCount = staffItems.where((item) => item.status == 'Disimpan').length;
    final claimedCount = staffItems.where((item) => item.status == 'Diklaim').length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔍 Lost & Found',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Laporkan barang temuan saat pembersihan kamar',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showReportLFDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Lapor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mini Stats Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Barang Disimpan',
                    value: storedCount.toString(),
                    icon: Icons.inventory_2_outlined,
                    iconBgColor: const Color(0xFFEEF3FB),
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Barang Diklaim',
                    value: claimedCount.toString(),
                    icon: Icons.check_circle_outline,
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Laporan Saya',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                // Dropdown Filter L&F status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                      onChanged: (val) {
                        setState(() {
                          _selectedStatusFilter = val!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
                        DropdownMenuItem(value: 'Disimpan', child: Text('Disimpan')),
                        DropdownMenuItem(value: 'Diklaim', child: Text('Diklaim')),
                        DropdownMenuItem(value: 'Diserahkan ke FO', child: Text('Di FO')),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),

            if (filteredItems.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.inventory_outlined, size: 48, color: Color(0xFF9AA3B2)),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada laporan barang temuan.',
                      style: TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return LostFoundCard(
                    itemName: item.itemName,
                    roomNumber: item.roomNumber,
                    category: item.itemCategory,
                    status: item.status,
                    reportedBy: item.reportedBy,
                    date: item.date,
                    onTap: () {
                      _showLFDetails(item);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLFDetails(LostFoundItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail Barang - ${item.refNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.photoPath != null) ...[
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1546868871-7041f2a55e12?q=80&w=400&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _detailRow('Nama Barang', item.itemName),
                _detailRow('Kategori', item.itemCategory),
                _detailRow('No. Kamar', item.roomNumber),
                _detailRow('Lokasi Detail', item.location),
                _detailRow('Kondisi', item.condition),
                _detailRow('Perkiraan Nilai', item.value),
                _detailRow('Diserahkan Ke', item.handoverTo),
                _detailRow('Deskripsi', item.description),
                _detailRow('Tanggal', item.date),
                _detailRow('Status', item.status),
                if (item.status == 'Diklaim') ...[
                  _detailRow('Diklaim Oleh', item.claimedBy ?? '-'),
                  _detailRow('Tgl Pengambilan', item.claimDate ?? '-'),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            )
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontFamily: 'Plus Jakarta Sans'),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A6478))),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
