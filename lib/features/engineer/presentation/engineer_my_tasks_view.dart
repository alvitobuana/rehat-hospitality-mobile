import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/exceptions/app_failure.dart';
import '../data/engineer_repository.dart';
import 'widgets/sla_countdown_widget.dart';
import 'engineer_dashboard_view.dart' show StatusBadge, PriorityBadge;



/// Tab "Tugas Saya" — menampilkan laporan yang sudah diklaim oleh Engineer ini.
/// Difilter dari list response: laporan berstatus CLAIMED / IN_PROGRESS / COMPLETED.
class EngineerMyTasksView extends ConsumerWidget {
  const EngineerMyTasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(engineerReportsProvider);

    // Gunakan widget biasa (bukan AppPage) agar tidak membuat nested Scaffold
    // EngineerShellScreen sudah menyediakan Scaffold + AppBar
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(engineerReportsProvider),
      child: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(err is AppFailure ? err.message : err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(engineerReportsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (reports) {
          final myTasks = reports.where((r) {
            final s = (r['status'] as String?) ?? '';
            return s == 'CLAIMED' || s == 'IN_PROGRESS' || s == 'COMPLETED';
          }).toList();

          if (myTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.engineering_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada tugas yang diklaim.\nKunjungi tab Laporan untuk mulai.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppInsets.s16),
            itemCount: myTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = myTasks[index];
              return _MyTaskCard(
                report: report,
                onTap: () => context.push('/engineer-task/${report['id']}'),
              );
            },
          );
        },
      ),

    );
  }
}

class _MyTaskCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _MyTaskCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (report['status'] as String?) ?? 'CLAIMED';
    final category = (report['category'] as String?) ?? '-';
    final hotelName = (report['hotel_name'] as String?) ?? '-';
    final priority = (report['priority'] as String?) ?? 'MEDIUM';
    final updatedAt = (report['updated_at'] as String?) ?? '';

    String locationStr;
    if (report['location_type'] == 'ROOM') {
      final roomNum = report['room_number'] ?? report['room_id'] ?? '-';
      locationStr = 'Kamar $roomNum';
    } else if (report['common_area'] != null &&
        report['common_area'] != 'Lainnya' &&
        report['common_area'] != 'Lainnya (Isi Lokasi)') {
      locationStr = 'Area Umum — ${report['common_area']}';
    } else {
      locationStr = 'Area Umum — ${report['custom_location'] ?? '-'}';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppInsets.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$locationStr  ·  $hotelName',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PriorityBadge(priority: priority),
                      const SizedBox(width: 8),
                      SlaCountdownWidget(
                        status: status,
                        claimDeadline: report['claim_deadline'] as String?,
                        completionDeadline: report['completion_deadline'] as String?,
                        createdAt: report['created_at'] as String?,
                        compact: true,
                      ),
                    ],
                  ),
                  Text(
                    'Diperbarui: ${_formatDate(updatedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // Progress indicator
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progressValue(status),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _progressValue(String status) => switch (status) {
    'CLAIMED'     => 0.25,
    'IN_PROGRESS' => 0.65,
    'COMPLETED'   => 1.0,
    _             => 0.0,
  };

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
