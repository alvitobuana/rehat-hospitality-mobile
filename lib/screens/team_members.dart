import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({Key? key}) : super(key: key);

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
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

    final filteredUsers = _state.users.where((user) {
      if (_selectedHotelFilter != 'Semua' && user.hotelUnit != _selectedHotelFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.department.toLowerCase().contains(query);
      }
      return true;
    }).toList();

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
                  '👥 Manajemen Tim',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daftar akun karyawan terdaftar di seluruh unit',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search and Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari karyawan...',
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
            const SizedBox(height: 16),

            if (filteredUsers.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 50),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.group_off_outlined, size: 52, color: Color(0xFF9AA3B2)),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada hasil untuk "$_searchQuery"'
                          : 'Tidak ada karyawan terdaftar.',
                      style: const TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final u = filteredUsers[index];

                  Color roleBg;
                  Color roleText;
                  switch (u.role) {
                    case UserRole.manager:
                      roleBg = const Color(0xFFFEE2E2);
                      roleText = const Color(0xFFB91C1C);
                      break;
                    case UserRole.leader:
                      roleBg = const Color(0xFFEDE9FE);
                      roleText = const Color(0xFF7C3AED);
                      break;
                    default:
                      roleBg = const Color(0xFFEEF3FB);
                      roleText = const Color(0xFF2A4E9A);
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.primaryColor.withOpacity(0.08),
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      u.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        u.roleString,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: roleText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  u.email,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B2)),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    _infoBadge(Icons.hotel_class, u.hotelUnit),
                                    _infoBadge(Icons.business, u.department),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9AA3B2)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF5A6478), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
