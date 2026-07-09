import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';

class ReportSummaryScreen extends StatefulWidget {
  const ReportSummaryScreen({Key? key}) : super(key: key);

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MockState _state = MockState();
  String _selectedHotelFilter = 'Semua';
  String _searchQuery = '';

  final List<String> _hotels = [
    'Semua', 'Dago Sky', 'Patradisa Iskat', 'Paskal Pelangi', 'Graha Sartika',
    'Hotel 10 Buah Batu', 'Abadi Tasikmalaya', 'Wahidin', 'Ottenville Boutique',
    'Siliwangi GH', 'Kurnia', 'Sabang', 'Gania'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗂️ Laporan Ringkasan',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Laporan detail log kamar, project, dan lost & found',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                ),
              ],
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari data...',
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
                ),
                const SizedBox(width: 8),
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
          ),
          const SizedBox(height: 12),

          // Tab Bar Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: const Color(0xFF1A2B4A),
              unselectedLabelColor: const Color(0xFF9AA3B2),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Kamar'),
                Tab(text: 'Project'),
                Tab(text: 'Lost & Found'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRoomsTab(),
                _buildProjectsTab(),
                _buildLostFoundTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    final filtered = _state.rooms.where((r) {
      if (_selectedHotelFilter != 'Semua' && r.hotelUnit != _selectedHotelFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return r.roomNumber.contains(query) ||
            r.staffName.toLowerCase().contains(query) ||
            r.status.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return _emptyState('Tidak ada data kamar.');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final room = filtered[index];
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
    );
  }

  Widget _buildProjectsTab() {
    final filtered = _state.projects.where((p) {
      if (_selectedHotelFilter != 'Semua' && p.hotelUnit != _selectedHotelFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.pic.toLowerCase().contains(query) ||
            p.area.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return _emptyState('Tidak ada data project.');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final project = filtered[index];
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
    );
  }

  Widget _buildLostFoundTab() {
    final filtered = _state.lostFoundItems.where((lf) {
      if (_selectedHotelFilter != 'Semua' && lf.hotelUnit != _selectedHotelFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return lf.itemName.toLowerCase().contains(query) ||
            lf.roomNumber.contains(query) ||
            lf.reportedBy.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return _emptyState('Tidak ada data Lost & Found.');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return LostFoundCard(
          itemName: item.itemName,
          roomNumber: item.roomNumber,
          category: item.itemCategory,
          status: item.status,
          reportedBy: item.reportedBy,
          date: item.date,
          onTap: () {},
        );
      },
    );
  }

  Widget _emptyState(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF9AA3B2)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
