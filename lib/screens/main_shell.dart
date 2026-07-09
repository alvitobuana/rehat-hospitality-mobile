import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import 'login_screen.dart';

// Import Screens
import 'staff_dashboard.dart';
import 'assigned_rooms.dart';
import 'lost_found_staff.dart';
import 'profile_screen.dart';

import 'validation_page.dart';
import 'project_list.dart';
import 'lost_found_leader.dart';

import 'manager_dashboard.dart';
import 'report_summary.dart';
import 'team_members.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final MockState _state = MockState();

  @override
  void initState() {
    super.initState();
    // Add listener to rebuild shell when state updates
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

  // Helper to log out
  void _doLogout() {
    _state.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _state.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    // Determine tabs based on role
    List<Widget> screens = [];
    List<NavigationDestination> destinations = [];
    String title = 'Rehat HK';

    if (user.role == UserRole.staff) {
      title = 'Staff Area';
      screens = [
        const StaffDashboardScreen(),
        const AssignedRoomsScreen(),
        const LostFoundStaffScreen(),
        const ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.clean_hands_outlined),
          selectedIcon: Icon(Icons.clean_hands),
          label: 'Kamar',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Lost & Found',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else if (user.role == UserRole.leader) {
      title = 'Leader Area';
      screens = [
        const ValidationPageScreen(),
        const ProjectListScreen(),
        const LostFoundLeaderScreen(),
        const ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check),
          label: 'Validasi',
        ),
        NavigationDestination(
          icon: Icon(Icons.construction_outlined),
          selectedIcon: Icon(Icons.construction),
          label: 'Project',
        ),
        NavigationDestination(
          icon: Icon(Icons.manage_search_outlined),
          selectedIcon: Icon(Icons.manage_search),
          label: 'L&F',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else if (user.role == UserRole.manager) {
      title = 'Manager Area';
      screens = [
        const ManagerDashboardScreen(),
        const ReportSummaryScreen(),
        const TeamMembersScreen(),
        const ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(Icons.assessment),
          label: 'Laporan',
        ),
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Tim',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }

    // Safety fallback for index out of bounds when switching roles
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'RH',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(
              'Unit: ${user.hotelUnit}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2), fontFamily: 'IBM Plex Mono', fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.roleString,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9AA3B2), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined, size: 20, color: Color(0xFFEF4444)),
                onPressed: _doLogout,
                tooltip: 'Keluar',
              ),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}
