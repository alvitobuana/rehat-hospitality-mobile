import 'package:flutter/material.dart';
import '../../features/attendance/presentation/attendance_controller.dart';
import 'app_cards.dart';
import 'app_buttons.dart';
import 'status_badge.dart';

/// Reusable Card untuk merender kontrol Absensi GPS karyawan.
class AttendanceCard extends StatelessWidget {
  final AttendanceStatus status;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const AttendanceCard({
    super.key,
    required this.status,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = status == AttendanceStatus.checkedIn;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Absensi Kehadiran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatusBadge(
                label: isCheckedIn ? 'Aktif' : 'Belum Aktif',
                type: isCheckedIn ? BadgeType.success : BadgeType.danger,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCheckedIn
                ? 'Sesi kerja Anda sedang aktif. Jangan lupa untuk melakukan Check-Out saat jam kerja Anda berakhir.'
                : 'Sesi kerja Anda belum aktif. Mohon lakukan Check-In koordinat GPS untuk mulai menerima tugas.',
            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (!isCheckedIn)
            AppPrimaryButton(
              text: 'CHECK IN (MULAI KERJA)',
              backgroundColor: Colors.green,
              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
              onPressed: onCheckIn,
            )
          else
            AppDangerButton(
              text: 'CHECK OUT (SELESAI KERJA)',
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              onPressed: onCheckOut,
            ),
        ],
      ),
    );
  }
}
