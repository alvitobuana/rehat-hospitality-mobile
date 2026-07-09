import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';

class RoomChecklistScreen extends StatefulWidget {
  final String roomNumber;

  const RoomChecklistScreen({Key? key, required this.roomNumber}) : super(key: key);

  @override
  State<RoomChecklistScreen> createState() => _RoomChecklistScreenState();
}

class _RoomChecklistScreenState extends State<RoomChecklistScreen> {
  final MockState _state = MockState();
  final TextEditingController _defectCtrl = TextEditingController();
  
  bool _hasPhoto = false;
  String _startTime = '';
  String _endTime = '';
  String _selectedStatus = 'Vacant Clean';

  final List<String> _statuses = ['Occupied', 'Vacant Clean', 'Vacant Dirty', 'Out of Order', 'Check Out'];

  @override
  void initState() {
    super.initState();
    _startTime = DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(minutes: 30)));
    _endTime = DateFormat('HH:mm').format(DateTime.now());
    
    // Set initial values from state if room exists
    final room = _state.rooms.firstWhere((r) => r.roomNumber == widget.roomNumber);
    _defectCtrl.text = room.defectNote;
    _selectedStatus = room.status == 'Vacant Dirty' ? 'Vacant Clean' : room.status; // Default to clean after checklist
  }

  @override
  void dispose() {
    _defectCtrl.dispose();
    super.dispose();
  }

  void _takeMockPhoto() {
    setState(() {
      _isLoadingPhoto = true;
    });
    
    // Simulate camera taking photo
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _hasPhoto = true;
        _isLoadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diambil (Dummy)!'), backgroundColor: Colors.green),
      );
    });
  }

  bool _isLoadingPhoto = false;

  void _submitChecklist() {
    // Check if checklist is complete
    final room = _state.rooms.firstWhere((r) => r.roomNumber == widget.roomNumber);
    final allChecked = room.checklist.every((item) => item.isChecked);
    
    if (!allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap centang semua item checklist sebelum submit!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Submit cleaning log
    _state.submitRoomChecklist(
      widget.roomNumber,
      _defectCtrl.text.trim(),
      _startTime,
      _endTime,
      photoPath: _hasPhoto ? 'assets/images/dummy_room.jpg' : null,
    );

    // Navigate to Success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessScreen(roomNumber: widget.roomNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = _state.rooms.firstWhere((r) => r.roomNumber == widget.roomNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist Kamar ${widget.roomNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Header Card
            Card(
              color: theme.primaryColor.withOpacity(0.06),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Kamar',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text('• Tipe Kamar: ${room.type}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('• Tipe Kerja: ${room.workType}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('• Waktu Kerja: $_startTime - $_endTime', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Checklist Section
            Text(
              'Item Pembersihan',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: room.checklist.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE4E8F0)),
                itemBuilder: (context, index) {
                  final item = room.checklist[index];
                  return CheckboxListTile(
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        color: item.isChecked ? const Color(0xFF9AA3B2) : const Color(0xFF1A2B4A),
                      ),
                    ),
                    value: item.isChecked,
                    activeColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (bool? value) {
                      setState(() {
                        _state.toggleChecklistItem(widget.roomNumber, item.id);
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Camera / Photo Upload section
            Text(
              'Foto Hasil Pekerjaan',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E8F0)),
              ),
              child: Column(
                children: [
                  if (_isLoadingPhoto)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_hasPhoto)
                    Column(
                      children: [
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFEEF3FB),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=600&auto=format&fit=crop'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _takeMockPhoto,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Ambil Ulang Foto'),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _takeMockPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E8F0), style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 36, color: Color(0xFF9AA3B2)),
                            SizedBox(height: 8),
                            Text(
                              'Klik untuk Ambil Foto Kamar',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Defect / Issue Form
            CustomTextField(
              label: 'Temuan Kerusakan / Defect',
              hintText: 'Tulis jika ada barang rusak atau defect kamar...',
              controller: _defectCtrl,
            ),
            const SizedBox(height: 16),

            // Status Kamar Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STATUS KAMAR SETELAH DIBERSIHKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
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
                      value: _selectedStatus,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              label: 'Submit Checklist',
              onPressed: _submitChecklist,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── SUCCESS SCREEN ───
class SuccessScreen extends StatelessWidget {
  final String roomNumber;

  const SuccessScreen({Key? key, required this.roomNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Success Animation/Icon
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Laporan Terkirim!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2B4A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Checklist pembersihan Kamar $roomNumber berhasil disimpan dan diajukan ke Leader untuk divalidasi.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A6478),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Kembali ke Dashboard',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
