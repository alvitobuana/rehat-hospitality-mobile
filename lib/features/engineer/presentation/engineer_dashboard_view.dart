import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../shared/widgets/app_page.dart';
import '../data/engineer_repository.dart';
import 'widgets/sla_countdown_widget.dart';



// ── View: Pool laporan (NEW) yang bisa diklaim Engineer ───────────────────────

class EngineerDashboardView extends ConsumerWidget {
  const EngineerDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(engineerReportsProvider);

    return AppPage(
      title: 'Laporan Kerusakan',
      useSafeArea: true,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(engineerReportsProvider),
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            message: err is AppFailure ? err.message : err.toString(),
            onRetry: () => ref.invalidate(engineerReportsProvider),
          ),
          data: (reports) {
            // Tampilkan semua laporan NEW atau OPEN yang bisa diklaim engineer
            final newReports = reports.where((r) => 
                r['status'] == 'NEW' || r['status'] == 'OPEN'
            ).toList();
            if (newReports.isEmpty) {
              return _EmptyView(message: 'Tidak ada laporan kerusakan baru.\nSemua beres!');
            }
            return ListView.separated(
              padding: EdgeInsets.all(AppInsets.s16),
              itemCount: newReports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final report = newReports[index];
                return _ReportCard(
                  report: report,
                  onTap: () => context.push('/engineer-task/${report['id']}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Card per laporan ──────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (report['status'] as String?) ?? 'NEW';
    final category = (report['category'] as String?) ?? '-';
    final hotelName = (report['hotel_name'] as String?) ?? '-';
    final priority = (report['priority'] as String?) ?? 'MEDIUM';
    final createdAt = (report['created_at'] as String?) ?? '';
    final reporterName = (report['reporter_name'] as String?) ?? '-';

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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      locationStr,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.hotel_outlined, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hotelName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: priority),
                  const SizedBox(width: 8),
                  SlaCountdownWidget(
                    status: status,
                    claimDeadline: report['claim_deadline'] as String?,
                    completionDeadline: report['completion_deadline'] as String?,
                    createdAt: createdAt,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pelapor: $reporterName',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    _formatDate(createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Status Badge (public — shared with engineer_my_tasks_view) ──────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'NEW'         => ('Baru', Colors.blue),
      'CLAIMED'     => ('Diklaim', Colors.orange),
      'IN_PROGRESS' => ('Dikerjakan', Colors.amber[700]!),
      'COMPLETED'   => ('Selesai', Colors.green),
      'VERIFIED'    => ('Terverifikasi', Colors.teal),
      'ARCHIVED'    => ('Diarsip', Colors.grey),
      _             => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Priority Badge (public — shared with engineer_my_tasks_view) ─────────────

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      'URGENT' => ('Urgent', Colors.red),
      'HIGH'   => ('Tinggi', Colors.orange),
      'MEDIUM' => ('Sedang', Colors.blue),
      'LOW'    => ('Rendah', Colors.grey),
      _        => (priority, Colors.grey),
    };
    return Text(
      '● $label',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
