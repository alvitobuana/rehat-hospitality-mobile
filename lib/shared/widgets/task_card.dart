import 'package:flutter/material.dart';
import '../../features/task/data/task_model.dart';
import 'app_card.dart';
import 'status_badge.dart';

/// Card flat modular untuk menampilkan rangkuman tugas kebersihan kamar.
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kamar ${task.roomNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              StatusBadge.fromStatusString(task.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Lantai ${task.floor}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.cleaning_services_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                task.cleaningType,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F3F4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text(
                    'Prioritas:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
