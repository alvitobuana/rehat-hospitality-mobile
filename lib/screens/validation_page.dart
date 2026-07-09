import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';

class ValidationPageScreen extends StatefulWidget {
  const ValidationPageScreen({Key? key}) : super(key: key);

  @override
  State<ValidationPageScreen> createState() => _ValidationPageScreenState();
}

class _ValidationPageScreenState extends State<ValidationPageScreen> {
  final MockState _state = MockState();
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

  void _handleApprove(String roomNumber) {
    _state.validateRoom(roomNumber, 'Verified');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kamar $roomNumber disetujui (Verified)!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReject(String roomNumber) {
    _state.validateRoom(roomNumber, 'Not Verified');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kamar $roomNumber ditolak (Not Verified)!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _state.currentUser!;

    // Leader validates all rooms in their unit that are NOT yet verified (Pending or Rejected logs can be re-evaluated)
    // Filter rooms by unit and verified status = 'Pending'
    final pendingRooms = _state.rooms
        .where((r) => r.hotelUnit == user.hotelUnit && r.verifiedStatus == 'Pending')
        .toList();

    final filteredRooms = pendingRooms.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.roomNumber.contains(_searchQuery) || r.staffName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Stats
    final totalPending = pendingRooms.length;
    final totalVerifiedToday = _state.rooms
        .where((r) => r.hotelUnit == user.hotelUnit && r.verifiedStatus == 'Verified')
        .length;

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
                  '✅ Validasi Pekerjaan',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verifikasi dan setujui log pembersihan kamar staff di unit ${user.hotelUnit}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mini statistics overview
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Menunggu Verifikasi',
                    value: totalPending.toString(),
                    icon: Icons.hourglass_top_outlined,
                    iconBgColor: const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFC2410C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Disetujui Hari Ini',
                    value: totalVerifiedToday.toString(),
                    icon: Icons.task_alt_outlined,
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar & Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Menunggu Persetujuan',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari Kamar/Staff...',
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
                )
              ],
            ),
            const SizedBox(height: 12),

            if (filteredRooms.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.done_all_outlined,
                      size: 52,
                      color: const Color(0xFF9AA3B2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada hasil untuk "$_searchQuery"'
                          : 'Tidak ada pekerjaan pending!',
                      style: const TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold),
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
                  final durationStr = room.startTime.isNotEmpty && room.endTime.isNotEmpty
                      ? _calculateDuration(room.startTime, room.endTime)
                      : 'N/A';

                  return ValidationCard(
                    roomNumber: room.roomNumber,
                    roomType: room.type,
                    staffName: room.staffName,
                    workType: room.workType,
                    duration: durationStr,
                    defectNote: room.defectNote,
                    hotelUnit: room.hotelUnit,
                    onApprove: () => _handleApprove(room.roomNumber),
                    onReject: () => _handleReject(room.roomNumber),
                    onTap: () {
                      _showVerificationDetails(room);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _calculateDuration(String start, String end) {
    try {
      final s = start.split(':').map(int.parse).toList();
      final e = end.split(':').map(int.parse).toList();
      final diffMin = (e[0] * 60 + e[1]) - (s[0] * 60 + s[1]);
      if (diffMin < 0) return '0m';
      return '${diffMin}m';
    } catch (_) {
      return 'N/A';
    }
  }

  void _showVerificationDetails(Room room) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Validasi Kamar ${room.roomNumber}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (room.photoPath != null) ...[
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=600&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text('Tipe: ${room.type}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Staff: ${room.staffName}'),
                Text('Waktu Kerja: ${room.startTime} - ${room.endTime}'),
                Text('Status Akhir: ${room.status}'),
                const SizedBox(height: 8),
                const Text('Item Checklist:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...room.checklist.map((item) => Row(
                      children: [
                        Icon(
                          item.isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 16,
                          color: item.isChecked ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(item.name, style: TextStyle(fontSize: 12, color: item.isChecked ? Colors.black : Colors.grey)),
                      ],
                    )),
                if (room.defectNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Defect/Kerusakan: ${room.defectNote}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
}
