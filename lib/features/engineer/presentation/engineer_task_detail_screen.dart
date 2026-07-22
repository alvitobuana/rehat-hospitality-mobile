import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/exceptions/app_failure.dart';
import '../../../core/utils/env_config.dart';
import '../data/engineer_repository.dart';


// ── Provider: fetch detail satu laporan ───────────────────────────────────────
final engineerReportDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, reportId) {
  return ref.read(engineerRepositoryProvider).fetchReportDetail(reportId);
});

// ── Main Screen ───────────────────────────────────────────────────────────────

class EngineerTaskDetailScreen extends ConsumerStatefulWidget {
  final int reportId;
  const EngineerTaskDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<EngineerTaskDetailScreen> createState() => _EngineerTaskDetailScreenState();
}

class _EngineerTaskDetailScreenState extends ConsumerState<EngineerTaskDetailScreen> {
  bool _isActionLoading = false;

  Future<void> _claim() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(engineerRepositoryProvider).claimReport(widget.reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil diklaim!'), backgroundColor: Colors.green),
        );
        // Invalidate both the detail and list providers
        ref.invalidate(engineerReportDetailProvider(widget.reportId));
        // Also invalidate the dashboard list
        ref.invalidate(engineerRepositoryProvider);
      }
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _updateProgress(String newStatus) async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(engineerRepositoryProvider).updateProgress(widget.reportId, newStatus);
      if (mounted) {
        final label = newStatus == 'IN_PROGRESS' ? 'Perbaikan dimulai!' : 'Laporan ditandai selesai!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(label), backgroundColor: Colors.green),
        );
        ref.invalidate(engineerReportDetailProvider(widget.reportId));
      }
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _uploadRepairPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (photo == null) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(engineerRepositoryProvider).uploadRepairPhoto(widget.reportId, photo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto bukti perbaikan berhasil diupload!'), backgroundColor: Colors.green),
        );
        ref.invalidate(engineerReportDetailProvider(widget.reportId));
      }
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(engineerReportDetailProvider(widget.reportId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(err is AppFailure ? err.message : err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(engineerReportDetailProvider(widget.reportId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (report) => _buildDetail(context, report),
    );
  }

  Widget _buildDetail(BuildContext context, Map<String, dynamic> report) {
    final theme = Theme.of(context);
    final status = (report['status'] as String?) ?? 'NEW';
    final category = (report['category'] as String?) ?? '-';
    final description = (report['description'] as String?) ?? '-';
    final priority = (report['priority'] as String?) ?? 'MEDIUM';
    final hotelName = (report['hotel_name'] as String?) ?? '-';
    final reporterName = (report['reporter_name'] as String?) ?? '-';
    final createdAt = (report['created_at'] as String?) ?? '';
    final photos = (report['photos'] as List?) ?? [];
    final repairPhotos = (report['repair_photos'] as List?) ?? [];
    final logs = (report['logs'] as List?) ?? [];
    final assignment = report['assignment'] as Map<String, dynamic>?;

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

    final baseUrl = EnvConfig.baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppInsets.s16).copyWith(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _SectionHeader('Informasi Laporan'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppInsets.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusChip(status),
                        _PriorityChip(priority),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(Icons.build, 'Kategori', category),
                    _InfoRow(Icons.location_on_outlined, 'Lokasi', locationStr),
                    _InfoRow(Icons.hotel_outlined, 'Hotel', hotelName),
                    _InfoRow(Icons.person_outlined, 'Pelapor', reporterName),
                    _InfoRow(Icons.access_time, 'Dilaporkan', _formatDate(createdAt)),
                    if (assignment != null)
                      _InfoRow(Icons.engineering_outlined, 'Engineer', assignment['engineer_name'] ?? '-'),
                    const SizedBox(height: 8),
                    const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Foto Kerusakan ──────────────────────────────────────────────
            if (photos.isNotEmpty) ...[
              _SectionHeader('Foto Kerusakan'),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final photoPath = (photos[i]['photo_path'] as String?) ?? '';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '$baseUrl/$photoPath',
                        width: 200,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Foto Bukti Perbaikan ────────────────────────────────────────
            _SectionHeader('Foto Bukti Perbaikan'),
            if (repairPhotos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada foto bukti perbaikan.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: repairPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final photoPath = (repairPhotos[i]['photo_path'] as String?) ?? '';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '$baseUrl/$photoPath',
                        width: 200,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // ── Audit Log ───────────────────────────────────────────────────
            if (logs.isNotEmpty) ...[
              _SectionHeader('Timeline Perbaikan'),
              _AuditTimeline(logs: logs),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),

      // ── Action Buttons (berubah berdasarkan status) ────────────────────────
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppInsets.s16,
          8,
          AppInsets.s16,
          AppInsets.s16 + MediaQuery.of(context).padding.bottom,
        ),
        child: _buildActionButtons(status),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (_isActionLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      ));
    }

    return switch (status) {
      'NEW' || 'OPEN' => FilledButton.icon(
          onPressed: _claim,
          icon: const Icon(Icons.engineering),
          label: const Text('Klaim Laporan Ini'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      'CLAIMED' => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _uploadRepairPhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Upload Foto Bukti'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _updateProgress('IN_PROGRESS'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai Perbaikan'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      'IN_PROGRESS' => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _uploadRepairPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Tambah Foto Bukti'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showCompleteConfirmation(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Tandai Selesai'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      'COMPLETED' => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Perbaikan selesai — menunggu verifikasi admin', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _showCompleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Selesai'),
        content: const Text(
          'Apakah Anda yakin perbaikan sudah selesai?\n\n'
          'Laporan akan dikirimkan ke Admin untuk verifikasi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateProgress('COMPLETED');
    }
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

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
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip(this.priority);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      'URGENT' => ('🔴 Urgent', Colors.red),
      'HIGH'   => ('🟠 Tinggi', Colors.orange),
      'MEDIUM' => ('🟡 Sedang', Colors.amber),
      'LOW'    => ('🟢 Rendah', Colors.green),
      _        => (priority, Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _AuditTimeline extends StatelessWidget {
  final List logs;
  const _AuditTimeline({required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: logs.asMap().entries.map((entry) {
        final i = entry.key;
        final log = entry.value as Map<String, dynamic>;
        final action = (log['action'] as String?) ?? '';
        final actorName = (log['actor_name'] as String?) ?? '-';
        final notes = (log['notes'] as String?) ?? '';
        final createdAt = (log['created_at'] as String?) ?? '';
        final isLast = i == logs.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _actionColor(action),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: theme.colorScheme.outlineVariant),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_actionLabel(action), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Oleh: $actorName', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      if (notes.isNotEmpty)
                        Text(notes, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      Text(_formatDate(createdAt), style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _actionColor(String action) => switch (action) {
    'CREATED'     => Colors.blue,
    'CLAIMED'     => Colors.orange,
    'IN_PROGRESS' => Colors.amber,
    'COMPLETED'   => Colors.green,
    'VERIFIED'    => Colors.teal,
    'ARCHIVED'    => Colors.grey,
    _             => Colors.grey,
  };

  String _actionLabel(String action) => switch (action) {
    'CREATED'     => '📋 Laporan dibuat',
    'CLAIMED'     => '🔧 Diklaim Engineer',
    'IN_PROGRESS' => '⚙️ Perbaikan dimulai',
    'COMPLETED'   => '✅ Perbaikan selesai',
    'VERIFIED'    => '✔️ Diverifikasi Admin',
    'ARCHIVED'    => '🗄️ Diarsipkan',
    _             => action,
  };

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
