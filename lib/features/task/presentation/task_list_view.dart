import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/task_card.dart';
import 'task_list_controller.dart';

class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListAsync = ref.watch(taskListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
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
              padding: const EdgeInsets.all(20.0),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat antrean tugas:\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(taskListControllerProvider.notifier).loadActiveTasks();
                    },
                    child: const Text('Coba Lagi'),
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
