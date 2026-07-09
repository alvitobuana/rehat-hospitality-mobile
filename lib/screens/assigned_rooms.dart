import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import 'room_checklist.dart';

class AssignedRoomsScreen extends StatefulWidget {
  const AssignedRoomsScreen({Key? key}) : super(key: key);

  @override
  State<AssignedRoomsScreen> createState() => _AssignedRoomsScreenState();
}

class _AssignedRoomsScreenState extends State<AssignedRoomsScreen> {
  final MockState _state = MockState();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _state.currentUser!;

    // Filter assigned rooms (only those that are pending cleaning and assigned to this unit)
    // We can assume Vacant Dirty or Check Out rooms are dirty and need cleaning.
    // In our mock database, we have rooms like 101 (Vacant Dirty, Pending), 104 (Suite, Occupied, Pending)
    final assignedRooms = _state.rooms
        .where((r) => r.hotelUnit == user.hotelUnit && (r.verifiedStatus == 'Pending' || r.verifiedStatus == 'Not Verified'))
        .toList();

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
                  '🛏️ Kamar Ditugaskan',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daftar kamar yang memerlukan pembersihan di unit ${user.hotelUnit}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (assignedRooms.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.done_all_outlined, size: 56, color: Color(0xFF22C55E)),
                    SizedBox(height: 12),
                    Text(
                      'Semua Kamar Bersih!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tidak ada tugas pembersihan kamar tersisa hari ini.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                    )
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignedRooms.length,
                itemBuilder: (context, index) {
                  final room = assignedRooms[index];
                  final timeRange = room.startTime.isNotEmpty && room.endTime.isNotEmpty
                      ? '${room.startTime} - ${room.endTime}'
                      : 'Belum Mulai';

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
                      // Navigate to Room Checklist screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomChecklistScreen(roomNumber: room.roomNumber),
                        ),
                      );
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
