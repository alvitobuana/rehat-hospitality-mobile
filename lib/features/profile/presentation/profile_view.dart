import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../core/device/device_info.dart';
import '../../../core/device/device_service.dart';
import '../../../core/storage/session_manager.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';

/// Provider Future untuk memuat metadata device secara async
final profileDeviceInfoProvider = FutureProvider<DeviceInfo>((ref) async {
  final deviceService = ref.read(deviceServiceProvider);
  return await deviceService.getDeviceInfo();
});

/// Provider untuk membaca versi aplikasi secara dinamis
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}+${info.buildNumber}';
});

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(profileDeviceInfoProvider);
    final sessionAsync = ref.watch(sessionDataProvider);
    final theme = Theme.of(context);

    return AppPage(
      title: 'Profil Saya',
      useSafeArea: true,
      scrollable: true,
      padding: EdgeInsets.only(
        left: AppInsets.s24,
        right: AppInsets.s24,
        top: AppInsets.s24,
        bottom: AppInsets.s24 + AppInsets.bottomSafe(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar & Name Card dinamis
          sessionAsync.when(
            data: (session) {
              final photoPath = session.profilePhoto ?? '';
              final photoUrl = photoPath.isNotEmpty
                  ? '${ProfileRepository.buildPhotoUrl(photoPath)}?t=${photoPath.hashCode}'
                  : '';
              final displayName = session.fullName?.isNotEmpty == true
                  ? session.fullName!
                  : (session.username ?? 'Staf Karyawan');

              return AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primaryColor.withAlpha(80), width: 2),
                      ),
                      child: ClipOval(
                        child: photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultAvatar(theme),
                              )
                            : _defaultAvatar(theme),
                      ),
                    ),
                    const SizedBox(height: AppInsets.s16),
                    Text(
                      displayName,
                      style: AppTypography.title(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (session.fullName?.isNotEmpty == true && session.username != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${session.username}',
                        style: AppTypography.caption(context).copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.level ?? 'Housekeeping Staff',
                        style: AppTypography.caption(context).copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppInsets.s16),
                    AppOutlineButton(
                      text: 'EDIT PROFIL',
                      height: 38,
                      onPressed: () {
                        context.push('/edit-profile');
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => AppCard(
              child: const Text('Gagal memuat detail profil', textAlign: TextAlign.center),
            ),
          ),
          
          // Account Details Section
          const SectionHeader(title: 'Informasi Akun'),
          sessionAsync.when(
            data: (session) => AppCard(
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.alternate_email_rounded,
                    label: 'Username',
                    value: session.username ?? '—',
                  ),
                  Divider(height: 20, color: AppColors.divider(context)),
                  _buildDetailRow(
                    context,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: session.email?.isNotEmpty == true ? session.email! : '—',
                  ),
                  Divider(height: 20, color: AppColors.divider(context)),
                  _buildDetailRow(
                    context,
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: session.phone?.isNotEmpty == true ? session.phone! : '—',
                  ),
                  Divider(height: 20, color: AppColors.divider(context)),
                  _buildStatusRow(
                    context,
                    icon: Icons.verified_user_outlined,
                    label: 'Status Akun',
                    status: session.status ?? 'ACTIVE',
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const SizedBox.shrink(),
          ),

          // Work Assignment Section
          const SectionHeader(title: 'Informasi Penugasan'),
          sessionAsync.when(
            data: (session) => AppCard(
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'ID Karyawan',
                    value: session.employeeId?.isNotEmpty == true ? session.employeeId! : '—',
                  ),
                  Divider(height: 20, color: AppColors.divider(context)),
                  _buildDetailRow(
                    context,
                    icon: Icons.business_outlined,
                    label: 'Role / Departemen',
                    value: '${session.role?.toUpperCase() ?? 'STAFF'} / ${session.level ?? 'Housekeeping'}',
                  ),
                  Divider(height: 20, color: AppColors.divider(context)),
                  _buildDetailRow(
                    context,
                    icon: Icons.hotel_rounded,
                    label: 'Hotel Penugasan',
                    value: session.hotelName?.isNotEmpty == true ? session.hotelName! : 'Rehat Hospitality',
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
                  data: (session) => _buildDetailRow(
                    context,
                    icon: Icons.vpn_key_outlined,
                    label: 'ID Ikat Perangkat',
                    value: session.deviceId ?? 'Belum terikat',
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                ),
                Divider(height: 20, color: AppColors.divider(context)),
                deviceAsync.when(
                  data: (info) => Column(
                    children: [
                      _buildDetailRow(
                        context,
                        icon: Icons.phone_android_rounded,
                        label: 'Model Perangkat',
                        value: info.deviceModel,
                      ),
                      Divider(height: 20, color: AppColors.divider(context)),
                      _buildDetailRow(
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
                Divider(height: 20, color: AppColors.divider(context)),
                ref.watch(appVersionProvider).when(
                  data: (version) => _buildDetailRow(
                    context,
                    icon: Icons.info_outline,
                    label: 'Versi Aplikasi',
                    value: version,
                  ),
                  loading: () => _buildDetailRow(
                    context,
                    icon: Icons.info_outline,
                    label: 'Versi Aplikasi',
                    value: 'Memuat...',
                  ),
                  error: (_, __) => _buildDetailRow(
                    context,
                    icon: Icons.info_outline,
                    label: 'Versi Aplikasi',
                    value: 'v1.0.0',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppInsets.s24),
          
          // Logout Button
          AppDangerButton(
            text: 'KELUAR AKUN (LOG OUT)',
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 18),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(ThemeData theme) {
    return Container(
      color: theme.primaryColor.withAlpha(30),
      child: Icon(Icons.person, size: 44, color: theme.primaryColor),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption(context).copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String status,
  }) {
    final statusColor = status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'APPROVED'
        ? Colors.green.shade700
        : status.toUpperCase() == 'PENDING'
            ? Colors.orange.shade700
            : Colors.red.shade700;

    final statusBgColor = status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'APPROVED'
        ? Colors.green.shade50
        : status.toUpperCase() == 'PENDING'
            ? Colors.orange.shade50
            : Colors.red.shade50;

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption(context).copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withAlpha(100), width: 0.5),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
