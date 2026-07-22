import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/exceptions/app_failure.dart';
import '../data/engineer_repository.dart';

// ── View: Work Order Dashboard & Pool Laporan ────────────────────────────────

class EngineerDashboardView extends ConsumerWidget {
  const EngineerDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(engineerReportsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(engineerReportsProvider),
      child: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err is AppFailure ? err.message : err.toString(),
          onRetry: () => ref.invalidate(engineerReportsProvider),
        ),
        data: (reports) {
          // 1. Temukan Active Work (tugas yang diklaim/dikerjakan engineer ini)
          final activeTask = reports.firstWhere(
            (r) =>
                (r['is_mine'] == true || r['is_mine'] == 1) &&
                (r['status'] == 'CLAIMED' || r['status'] == 'IN_PROGRESS'),
            orElse: () => <String, dynamic>{},
          );

          final hasActiveTask = activeTask.isNotEmpty;

          // 2. Filter Laporan Masuk (Pool Terbuka: NEW/OPEN & belum diklaim saya)
          final openReports = reports.where((r) {
            final s = (r['status'] as String?) ?? '';
            final isMine = r['is_mine'] == true || r['is_mine'] == 1;
            return (s == 'NEW' || s == 'OPEN') && !isMine;
          }).toList();

          // Priority Weight Map untuk mengurutkan Severity secara presisi
          int getPriorityRank(String? p) {
            switch (p?.toUpperCase()) {
              case 'URGENT':
                return 4;
              case 'HIGH':
                return 3;
              case 'MEDIUM':
                return 2;
              case 'LOW':
                return 1;
              default:
                return 0;
            }
          }

          openReports.sort((a, b) {
            final rankA = getPriorityRank(a['priority'] as String?);
            final rankB = getPriorityRank(b['priority'] as String?);
            if (rankA != rankB) {
              return rankB.compareTo(rankA); // Severity tertinggi di atas
            }
            final dateA = a['created_at'] as String? ?? '';
            final dateB = b['created_at'] as String? ?? '';
            return dateB.compareTo(dateA); // Terbaru di atas
          });

          if (!hasActiveTask && openReports.isEmpty) {
            return const _EmptyView(
              message: 'Tidak ada laporan kerusakan terbuka.\nSemua pekerjaan selesai!',
            );
          }

          return ListView(
            padding: EdgeInsets.all(AppInsets.s16),
            children: [
              // ── 1. ACTIVE WORK (Pinned Hero Card Always On Top) ──
              if (hasActiveTask) ...[
                _ActiveWorkHeroCard(
                  report: activeTask,
                  onTap: () => context.push('/engineer-task/${activeTask['id']}'),
                ),
                const SizedBox(height: 20),
              ],

              // ── 2. OPEN TASKS SECTION HEADER ──
              Row(
                children: [
                  const Icon(Icons.list_alt_rounded, size: 20, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Text(
                    'LAPORAN MASUK (PRIORITAS SEVERITY)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey.shade400,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── 3. OPEN TASKS LIST ──
              if (openReports.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tidak ada laporan baru di antrean.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...openReports.map((report) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReportCard(
                      report: report,
                      onTap: () => context.push('/engineer-task/${report['id']}'),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ── Hero Active Work Card (Pinned Top) ───────────────────────────────────────

class _ActiveWorkHeroCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ActiveWorkHeroCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (report['status'] as String?) ?? 'CLAIMED';
    final category = (report['category'] as String?) ?? '-';
    final hotelName = (report['hotel_name'] as String?) ?? '-';
    final priority = (report['priority'] as String?) ?? 'MEDIUM';
    final description = (report['description'] as String?) ?? '';

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

    final isDoingWork = status == 'IN_PROGRESS';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2430),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDoingWork ? Colors.amber.shade600 : const Color(0xFF4CAF50),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDoingWork ? Colors.amber : Colors.green).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Top Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDoingWork
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDoingWork ? Icons.build_circle : Icons.engineering_outlined,
                                size: 16,
                                color: isDoingWork ? Colors.amber : Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDoingWork ? 'SEDANG DIKERJAKAN' : 'DIKLAIM (SIAP MULAI)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDoingWork ? Colors.amber : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    PriorityBadge(priority: priority),
                  ],
                ),
                const SizedBox(height: 12),

                // Title & Location
                Text(
                  category,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      '$locationStr • $hotelName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white54),
                  ),
                ],
                const SizedBox(height: 14),

                // Hero Button Action
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(
                      isDoingWork ? Icons.arrow_forward : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isDoingWork ? 'Buka & Perbarui Progres' : 'Mulai Pekerjaan Ini',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDoingWork ? Colors.amber.shade700 : const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Card Laporan Masuk (Pool) ──────────────────────────────────────────────────

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
                  PriorityBadge(priority: priority),
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
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
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

// ── Status Badge ───────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'NEW' || 'OPEN' => ('OPEN', Colors.blue),
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

// ── Priority Badge (Bold Severity Badge) ──────────────────────────────────────

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority.toUpperCase()) {
      'URGENT' => ('URGENT', Colors.redAccent),
      'HIGH'   => ('TINGGI', Colors.orange),
      'MEDIUM' => ('SEDANG', Colors.amber.shade700),
      'LOW'    => ('RENDAH', Colors.blue),
      _        => (priority, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
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
