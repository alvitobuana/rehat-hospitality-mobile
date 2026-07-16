import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/history_item.dart';
import 'history_controller.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return AppPage(
      title: 'Riwayat Aktivitas',
      useSafeArea: true,
      scrollable: false,
      padding: EdgeInsets.zero, // Padding is managed by ListView for scroll boundaries
      child: historyAsync.when(
        // ----------------------------------------------------------------
        // Loading State
        // ----------------------------------------------------------------
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppInsets.s24),
            child: CircularProgressIndicator(),
          ),
        ),

        // ----------------------------------------------------------------
        // Error State
        // ----------------------------------------------------------------
        error: (err, _) {
          final isSession = err.toString().contains('SESSION_EXPIRED') ||
              err.toString().contains('Sesi berakhir');
          return Center(
            child: AppEmptyState(
              title: isSession ? 'Sesi Berakhir' : 'Gagal Memuat Riwayat',
              message: isSession
                  ? 'Silakan masuk kembali ke aplikasi.'
                  : err.toString(),
              icon: isSession
                  ? Icons.lock_outline_rounded
                  : Icons.wifi_off_rounded,
              actionText: 'Coba Lagi',
              onActionPressed: () {
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      AppEmptyState(
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
                    padding: EdgeInsets.only(
                        left: AppInsets.s20,
                        right: AppInsets.s20,
                        top: AppInsets.s8,
                        bottom: AppInsets.s8 + AppInsets.bottomSafe(context)),
                    itemCount: history.length + 1,
                    itemBuilder: (context, index) {
                      // Header
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppInsets.s8),
                          child: SectionHeader(
                            title: 'Riwayat Tugas (${history.length})',
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
    final isExpired = item.status.toLowerCase() == 'expired';
    final leadingBg = isExpired ? Colors.orange.shade50 : Colors.green.shade50;
    final leadingBorder = isExpired ? Colors.orange.shade200 : Colors.green.shade200;
    final leadingIcon = isExpired ? Icons.info_outline_rounded : Icons.check_circle_rounded;
    final leadingIconColor = isExpired ? Colors.orange.shade400 : Colors.green.shade400;

    return AppCard(
      onTap: () {
        // Navigate ke Task Detail untuk melihat detail tugas selesai
        context.push('/task-detail/${item.taskId}');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Icon Leading dynamic based on status ----
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: leadingBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: leadingBorder, width: 1),
            ),
            child: Icon(
              leadingIcon,
              color: leadingIconColor,
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
                    StatusBadge.fromStatusString(item.status),
                  ],
                ),
                const SizedBox(height: 4),

                // Jenis Cleaning
                Text(
                  item.cleaningType,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),

                // Tanggal Selesai / Kadaluarsa
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? 'Kadaluarsa: ${item.formattedDate}' : 'Selesai: ${item.formattedDate}',
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
