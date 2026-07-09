import 'package:flutter/material.dart';
import '../services/mock_state.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MockState _state = MockState();
  bool _notificationsEnabled = true;
  bool _darkMode = false;

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

  void _handleLogout() {
    _state.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _state.currentUser!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.primaryColor.withOpacity(0.08),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9AA3B2), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(Icons.security, user.roleString, const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
                        _chip(Icons.hotel_class, user.hotelUnit, const Color(0xFFEEF3FB), theme.primaryColor),
                        _chip(Icons.business, user.department, const Color(0xFFE4E8F0), const Color(0xFF5A6478)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Settings Header
            Text(
              'Pengaturan Aplikasi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Settings Card list
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Notifikasi Push', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                    subtitle: const Text('Dapatkan info update penugasan secara real-time', style: TextStyle(fontSize: 11)),
                    value: _notificationsEnabled,
                    activeColor: theme.primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E8F0)),
                  SwitchListTile(
                    title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                    subtitle: const Text('Ubah tampilan menjadi mode gelap', style: TextStyle(fontSize: 11)),
                    value: _darkMode,
                    activeColor: theme.primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E8F0)),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Color(0xFF5A6478)),
                    title: const Text('Ubah Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ubah Password (Dummy flow)!'), backgroundColor: Colors.blue),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE4E8F0)),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: Color(0xFF5A6478)),
                    title: const Text('Bantuan & Dukungan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2B4A))),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pusat Bantuan Rehat HK!'), backgroundColor: Colors.blue),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}
