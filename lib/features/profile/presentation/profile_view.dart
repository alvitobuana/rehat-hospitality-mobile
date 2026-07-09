import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/device/device_info.dart';
import '../../../core/device/device_service.dart';
import '../../../core/storage/session_manager.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/presentation/auth_controller.dart';

/// Provider Future untuk memuat metadata device secara async
final profileDeviceInfoProvider = FutureProvider<DeviceInfo>((ref) async {
  final deviceService = ref.read(deviceServiceProvider);
  return await deviceService.getDeviceInfo();
});

/// BUG 4 FIX: Provider untuk membaca versi aplikasi secara dinamis
/// menggunakan package_info_plus, menggantikan string hardcoded 'v0.5.2'.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}+${info.buildNumber}';
});

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  String _getHotelName(String? username, String? level) {
    if (username == 'hk_dago' || level == 'Housekeeping') {
      return 'Dago Sky';
    }
    return 'Rehat Hospitality';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(profileDeviceInfoProvider);
    final sessionAsync = ref.watch(sessionDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar & Name Card dinamis
            sessionAsync.when(
              data: (session) => AppCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.primaryColor.withAlpha(30),
                      child: Icon(Icons.person, size: 48, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      session.username ?? 'Staf Karyawan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.level ?? 'Housekeeping Staff',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AppCard(
                child: const Text('Gagal memuat detail profil', textAlign: TextAlign.center),
              ),
            ),
            
            // Hotel Information
            const SectionHeader(title: 'Lokasi Penugasan'),
            sessionAsync.when(
              data: (session) => AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.hotel_rounded, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hotel Properti',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _getHotelName(session.username, session.level),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const SizedBox.shrink(),
            ),
            
            // Device Information (Device Binding parameters)
            const SectionHeader(title: 'Metadata Keamanan'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sessionAsync.when(
                    data: (session) => _buildMetaRow(
                      context,
                      icon: Icons.vpn_key_outlined,
                      label: 'ID Ikat Perangkat',
                      value: session.deviceId ?? 'Belum terikat',
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (err, _) => const SizedBox.shrink(),
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F3F4)),
                  deviceAsync.when(
                    data: (info) => Column(
                      children: [
                        _buildMetaRow(
                          context,
                          icon: Icons.phone_android_rounded,
                          label: 'Model Perangkat',
                          value: info.deviceModel,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F3F4)),
                        _buildMetaRow(
                          context,
                          icon: Icons.settings_applications_outlined,
                          label: 'Versi OS',
                          value: info.osVersion,
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => const Text(
                      'Gagal memuat detail spesifikasi OS perangkat.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F3F4)),
                  // BUG 4 FIX: Versi aplikasi dinamis dari package_info_plus
                  ref.watch(appVersionProvider).when(
                    data: (version) => _buildMetaRow(
                      context,
                      icon: Icons.info_outline,
                      label: 'Versi Aplikasi',
                      value: version,
                    ),
                    loading: () => _buildMetaRow(
                      context,
                      icon: Icons.info_outline,
                      label: 'Versi Aplikasi',
                      value: 'Memuat...',
                    ),
                    error: (_, __) => _buildMetaRow(
                      context,
                      icon: Icons.info_outline,
                      label: 'Versi Aplikasi',
                      value: 'v1.0.0',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Logout Button
            CustomButton(
              text: 'KELUAR AKUN (LOG OUT)',
              backgroundColor: Colors.grey[800],
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 18),
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
