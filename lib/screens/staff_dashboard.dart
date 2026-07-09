import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final MockState _state = MockState();
  String _selectedWorkTypeFilter = 'Semua';

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

  // Show dialog to add room log manually
  void _showAddLogDialog() {
    final roomCtrl = TextEditingController();
    final defectCtrl = TextEditingController();
    String type = 'Standard';
    String workType = 'Make Up Room';
    String roomStatus = 'Occupied';
    String start = '09:00';
    String end = '09:30';

    final types = ['Standard', 'Superior', 'Deluxe', 'Suite', 'Executive', 'Family', 'Twin'];
    final workTypes = ['Make Up Room', 'General Cleaning'];
    final statuses = ['Occupied', 'Vacant Clean', 'Vacant Dirty', 'Out of Order', 'Check Out'];

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
                          'Tambah Log Kamar',
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
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'No. Kamar',
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
                              const Text('TIPE KAMAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
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
                                    value: type,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => type = val!),
                                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                              const Text('TIPE PEKERJAAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
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
                                    value: workType,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => workType = val!),
                                    items: workTypes.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
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
                              const Text('STATUS KAMAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
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
                                    value: roomStatus,
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A2B4A), fontWeight: FontWeight.bold),
                                    onChanged: (val) => setModalState(() => roomStatus = val!),
                                    items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
                              const Text('JAM MULAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                                  );
                                  if (time != null) {
                                    setModalState(() => start = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
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
                                      Text(start, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                                      const Icon(Icons.access_time, size: 20, color: Color(0xFF9AA3B2)),
                                    ],
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
                              const Text('JAM SELESAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9AA3B2))),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(hour: 9, minute: 30),
                                  );
                                  if (time != null) {
                                    setModalState(() => end = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
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
                                      Text(end, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                                      const Icon(Icons.access_time, size: 20, color: Color(0xFF9AA3B2)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Catatan Defect / Temuan',
                      hintText: 'Kerusakan atau barang tertinggal...',
                      controller: defectCtrl,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Simpan Log',
                      onPressed: () {
                        if (roomCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No. Kamar wajib diisi!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        _state.addRoomLog(
                          roomCtrl.text.trim(),
                          type,
                          workType,
                          roomStatus,
                          start,
                          end,
                          defectCtrl.text.trim(),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Log Kamar berhasil disimpan!'), backgroundColor: Colors.green),
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

    // Filter staff rooms
    final staffRooms = _state.rooms
        .where((r) => r.staffName == user.name && r.hotelUnit == user.hotelUnit)
        .toList();

    final filteredRooms = staffRooms.where((r) {
      if (_selectedWorkTypeFilter == 'Semua') return true;
      return r.workType == _selectedWorkTypeFilter;
    }).toList();

    // Stats calculations
    final completedCount = staffRooms.where((r) => r.verifiedStatus == 'Verified').length;
    final pendingCount = staffRooms.where((r) => r.verifiedStatus == 'Pending').length;
    final defectCount = staffRooms.where((r) => r.defectNote.isNotEmpty).length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Title header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Log Pekerjaan',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Catat kamar yang telah dibersihkan hari ini',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddLogDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log Baru'),
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

            // Statistics Grid (3 Cards)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Verified',
                    value: completedCount.toString(),
                    icon: Icons.check_circle_outline,
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value: pendingCount.toString(),
                    icon: Icons.hourglass_empty,
                    iconBgColor: const Color(0xFFFEF9C3),
                    iconColor: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Defects',
                    value: defectCount.toString(),
                    icon: Icons.error_outline,
                    iconBgColor: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Hari Ini',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                // Dropdown Filter work type
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
                      value: _selectedWorkTypeFilter,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                      onChanged: (val) {
                        setState(() {
                          _selectedWorkTypeFilter = val!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 'Semua', child: Text('Semua Tipe')),
                        DropdownMenuItem(value: 'Make Up Room', child: Text('Make Up')),
                        DropdownMenuItem(value: 'General Cleaning', child: Text('GC')),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),

            // Room logs list
            if (filteredRooms.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF9AA3B2)),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada log untuk filter ini.',
                      style: TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  final timeRange = room.startTime.isNotEmpty && room.endTime.isNotEmpty
                      ? '${room.startTime} - ${room.endTime}'
                      : '';
                  return RoomCard(
                    roomNumber: room.roomNumber,
                    roomType: room.type,
                    workType: room.workType,
                    status: room.status,
                    verifiedStatus: room.verifiedStatus,
                    staffName: room.staffName,
                    timeText: timeRange,
                    defectNote: room.defectNote,
                    onTap: () {
                      // Navigate to details if needed
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
