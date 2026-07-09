import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import '../theme/app_theme.dart';


class LostFoundLeaderScreen extends StatefulWidget {
  const LostFoundLeaderScreen({Key? key}) : super(key: key);

  @override
  State<LostFoundLeaderScreen> createState() => _LostFoundLeaderScreenState();
}

class _LostFoundLeaderScreenState extends State<LostFoundLeaderScreen> {
  final MockState _state = MockState();
  String _selectedStatusFilter = 'Semua';
  String _selectedCategoryFilter = 'Semua';
  String _searchQuery = '';

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

  // Show bottom sheet to update Lost & Found item status
  void _showUpdateLFStatusDialog(LostFoundItem item) {
    String currentStatus = item.status;
    final claimNameCtrl = TextEditingController(text: item.claimedBy ?? '');
    String claimDateStr = item.claimDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    final statuses = ['Disimpan', 'Diklaim', 'Diserahkan ke FO'];

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
                        Text(
                          'Update Status - ${item.refNumber}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    Text('Barang: ${item.itemName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Ditemukan di: Kamar ${item.roomNumber} oleh ${item.reportedBy}'),
                    const SizedBox(height: 16),

                    const Text('STATUS BARANG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
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
                          value: currentStatus,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                          onChanged: (val) => setModalState(() => currentStatus = val!),
                          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (currentStatus == 'Diklaim') ...[
                      CustomTextField(
                        label: 'Nama Pengambil (Klaim)',
                        hintText: 'Nama lengkap pengambil...',
                        controller: claimNameCtrl,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TANGGAL KLAIM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date != null) {
                                setModalState(() => claimDateStr = DateFormat('yyyy-MM-dd').format(date));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE4E8F0), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(claimDateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF9AA3B2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    PrimaryButton(
                      label: 'Simpan Perubahan',
                      onPressed: () {
                        if (currentStatus == 'Diklaim' && claimNameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama pengambil wajib diisi jika barang diklaim!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        _state.updateLFStatus(
                          item.id,
                          currentStatus,
                          claimedBy: currentStatus == 'Diklaim' ? claimNameCtrl.text.trim() : null,
                          claimDate: currentStatus == 'Diklaim' ? claimDateStr : null,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status L&F berhasil diupdate!'), backgroundColor: Colors.green),
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

    final unitItems = _state.lostFoundItems
        .where((item) => item.hotelUnit == user.hotelUnit)
        .toList();

    final filteredItems = unitItems.where((item) {
      // Filter status
      if (_selectedStatusFilter != 'Semua' && item.status != _selectedStatusFilter) {
        return false;
      }
      // Filter category
      if (_selectedCategoryFilter != 'Semua' && item.itemCategory != _selectedCategoryFilter) {
        return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return item.itemName.toLowerCase().contains(query) ||
            item.roomNumber.contains(query) ||
            item.reportedBy.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Stats
    final totalStored = unitItems.where((item) => item.status == 'Disimpan').length;
    final totalClaimed = unitItems.where((item) => item.status == 'Diklaim').length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔍 Kelola Lost & Found',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola dan verifikasi status barang temuan di unit ${user.hotelUnit}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Dalam Penyimpanan',
                    value: totalStored.toString(),
                    icon: Icons.inventory_2_outlined,
                    iconBgColor: const Color(0xFFEEF3FB),
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Telah Diklaim',
                    value: totalClaimed.toString(),
                    icon: Icons.done_all_outlined,
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and Filters
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari barang / kamar / staff...',
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF9AA3B2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE4E8F0)),
                ),
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE4E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                        onChanged: (val) => setState(() => _selectedStatusFilter = val!),
                        items: const [
                          DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
                          DropdownMenuItem(value: 'Disimpan', child: Text('Disimpan')),
                          DropdownMenuItem(value: 'Diklaim', child: Text('Diklaim')),
                          DropdownMenuItem(value: 'Diserahkan ke FO', child: Text('Di FO')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE4E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryFilter,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                        onChanged: (val) => setState(() => _selectedCategoryFilter = val!),
                        items: const [
                          DropdownMenuItem(value: 'Semua', child: Text('Semua Kategori')),
                          DropdownMenuItem(value: 'Elektronik', child: Text('Elektronik')),
                          DropdownMenuItem(value: 'Dokumen / ID', child: Text('Dokumen / ID')),
                          DropdownMenuItem(value: 'Pakaian', child: Text('Pakaian')),
                          DropdownMenuItem(value: 'Perhiasan / Aksesori', child: Text('Aksesori')),
                          DropdownMenuItem(value: 'Uang / Dompet', child: Text('Uang / Dompet')),
                          DropdownMenuItem(value: 'Tas / Koper', child: Text('Tas / Koper')),
                          DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (filteredItems.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.inventory_2_outlined,
                      size: 52,
                      color: const Color(0xFF9AA3B2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada hasil untuk "$_searchQuery"'
                          : 'Tidak ada barang temuan.',
                      style: const TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold),
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
                      _showUpdateLFStatusDialog(item);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
