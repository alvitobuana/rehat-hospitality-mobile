import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_insets.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/task_card.dart';
import 'task_list_controller.dart';

class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListAsync = ref.watch(taskListProvider);

    return AppPage(
      title: 'Daftar Tugas',
      useSafeArea: true,
      scrollable: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(taskListControllerProvider.notifier).refreshActiveTasks();
        },
        child: taskListAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return const Center(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: EmptyStateView(
                    title: 'Antrean Tugas Kosong',
                    message: 'Tidak ada tugas pembersihan kamar yang masuk antrean saat ini.',
                    icon: Icons.checklist_rounded,
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: AppInsets.s20,
                right: AppInsets.s20,
                top: AppInsets.s20,
                bottom: AppInsets.s20 + AppInsets.bottomSafe(context),
              ),
              itemCount: tasks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SectionHeader(title: 'Tugas Aktif Lapangan');
                }
                
                final task = tasks[index - 1];
                return TaskCard(
                  task: task,
                  onTap: () {
                    context.push('/task-detail/${task.taskId}');
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppInsets.s24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger(context)),
                  const SizedBox(height: AppInsets.s12),
                  Text(
                    'Gagal memuat antrean tugas:\n$err',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(context),
                  ),
                  const SizedBox(height: AppInsets.s16),
                  AppPrimaryButton(
                    text: 'Coba Lagi',
                    onPressed: () {
                      ref.read(taskListControllerProvider.notifier).loadActiveTasks();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
