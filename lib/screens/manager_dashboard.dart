import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import '../theme/app_theme.dart';


class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final MockState _state = MockState();
  String _selectedHotelFilter = 'Semua';

  final List<String> _hotels = [
    'Semua', 'Dago Sky', 'Patradisa Iskat', 'Paskal Pelangi', 'Graha Sartika',
    'Hotel 10 Buah Batu', 'Abadi Tasikmalaya', 'Wahidin', 'Ottenville Boutique',
    'Siliwangi GH', 'Kurnia', 'Sabang', 'Gania'
  ];

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

    // Filter data based on selected hotel unit
    final filteredRooms = _state.rooms.where((r) {
      if (_selectedHotelFilter == 'Semua') return true;
      return r.hotelUnit == _selectedHotelFilter;
    }).toList();

    final filteredProjects = _state.projects.where((p) {
      if (_selectedHotelFilter == 'Semua') return true;
      return p.hotelUnit == _selectedHotelFilter;
    }).toList();

    final filteredLF = _state.lostFoundItems.where((lf) {
      if (_selectedHotelFilter == 'Semua') return true;
      return lf.hotelUnit == _selectedHotelFilter;
    }).toList();

    // Stats calculations
    final totalRooms = filteredRooms.length;
    final completedCount = filteredRooms.where((r) => r.verifiedStatus == 'Verified').length;
    final pendingCount = filteredRooms.where((r) => r.verifiedStatus == 'Pending').length;
    final activeProjects = filteredProjects.where((p) => p.status == 'Sedang Berlangsung').length;
    final totalLFStored = filteredLF.where((lf) => lf.status == 'Disimpan').length;
    final totalDefects = filteredRooms.where((r) => r.defectNote.isNotEmpty).length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title and Hotel Filter Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Manager Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ringkasan operasional seluruh unit hotel',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                    ),
                  ],
                ),
                // Dropdown Hotel Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHotelFilter,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6478)),
                      onChanged: (val) {
                        setState(() {
                          _selectedHotelFilter = val!;
                        });
                      },
                      items: _hotels.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Statistics Grid (6 Cards)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  title: 'Total Log Kamar',
                  value: totalRooms.toString(),
                  icon: Icons.meeting_room_outlined,
                  iconBgColor: const Color(0xFFEEF3FB),
                  iconColor: AppTheme.primaryColor,
                ),
                StatCard(
                  title: 'Kamar Selesai',
                  value: completedCount.toString(),
                  icon: Icons.check_circle_outline,
                  iconBgColor: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF15803D),
                ),
                StatCard(
                  title: 'Kamar Pending',
                  value: pendingCount.toString(),
                  icon: Icons.hourglass_top_outlined,
                  iconBgColor: const Color(0xFFFEF9C3),
                  iconColor: const Color(0xFF92400E),
                ),
                StatCard(
                  title: 'Project Aktif',
                  value: activeProjects.toString(),
                  icon: Icons.construction_outlined,
                  iconBgColor: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
                ),
                StatCard(
                  title: 'Lost & Found Simpan',
                  value: totalLFStored.toString(),
                  icon: Icons.inventory_2_outlined,
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF0E9F7E),
                ),
                StatCard(
                  title: 'Kamar Defect',
                  value: totalDefects.toString(),
                  icon: Icons.warning_amber_outlined,
                  iconBgColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFB91C1C),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Room Logs Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 Log Kamar Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredRooms.isEmpty)
              _emptyStateWidget('Belum ada log pekerjaan kamar.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRooms.length > 3 ? 3 : filteredRooms.length,
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
                    onTap: () {},
                  );
                },
              ),
            const SizedBox(height: 24),

            // Active Projects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🔧 Project Aktif',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredProjects.isEmpty)
              _emptyStateWidget('Tidak ada project aktif.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProjects.length > 2 ? 2 : filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  final dateText = '${project.startDate} s/d ${project.endDate}';
                  return ProjectCard(
                    name: project.name,
                    area: project.area,
                    category: project.category,
                    status: project.status,
                    priority: project.priority,
                    progress: project.progress,
                    pic: project.pic,
                    cost: project.cost,
                    dateText: dateText,
                    onTap: () {},
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyStateWidget(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF9AA3B2)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
