import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/history_item.dart';
import 'history_controller.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        automaticallyImplyLeading: false,
      ),
      body: historyAsync.when(
        // ----------------------------------------------------------------
        // Loading State
        // ----------------------------------------------------------------
        loading: () => const Center(child: CircularProgressIndicator()),

        // ----------------------------------------------------------------
        // Error State
        // ----------------------------------------------------------------
        error: (err, _) {
          final isSession = err.toString().contains('SESSION_EXPIRED') ||
              err.toString().contains('Sesi berakhir');
          return Center(
            child: ErrorStateView(
              title: isSession ? 'Sesi Berakhir' : 'Gagal Memuat Riwayat',
              message: isSession
                  ? 'Silakan masuk kembali ke aplikasi.'
                  : err.toString(),
              icon: isSession
                  ? Icons.lock_outline_rounded
                  : Icons.wifi_off_rounded,
              onRetryPressed: () {
                ref.read(historyControllerProvider.notifier).loadHistory();
              },
            ),
          );
        },

        // ----------------------------------------------------------------
        // Data State
        // ----------------------------------------------------------------
        data: (List<HistoryItem> history) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(historyControllerProvider.notifier).refreshHistory();
            },
            child: history.isEmpty
                // ---- Empty State ----
                ? ListView(
                    // Diperlukan agar RefreshIndicator bekerja meski kosong
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      EmptyStateView(
                        title: 'Riwayat Masih Kosong',
                        message:
                            'Anda belum menyelesaikan tugas kamar apa pun.\nSelesaikan tugas untuk melihat riwayat di sini.',
                        icon: Icons.history_rounded,
                      ),
                    ],
                  )
                // ---- List State ----
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    itemCount: history.length + 1,
                    itemBuilder: (context, index) {
                      // Header
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SectionHeader(
                            title: 'Tugas Selesai (${history.length})',
                          ),
                        );
                      }

                      final item = history[index - 1];
                      return _HistoryCard(item: item);
                    },
                  ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// History Card Widget
// =============================================================================

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        // Navigate ke Task Detail untuk melihat detail tugas selesai
        context.push('/task-detail/${item.taskId}');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Foto Placeholder (backend belum mengembalikan photo_path di history) ----
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200, width: 1),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade400,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // ---- Metadata ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris: Nomor Kamar + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kamar ${item.roomNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    StatusBadge.fromStatusString('Completed'),
                  ],
                ),
                const SizedBox(height: 4),

                // Jenis Cleaning
                Text(
                  item.cleaningType,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),

                // Tanggal Selesai
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai: ${item.formattedDate}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---- Chevron ----
          const Icon(Icons.chevron_right_rounded,
              color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
