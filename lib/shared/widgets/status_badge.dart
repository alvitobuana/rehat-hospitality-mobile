import 'package:flutter/material.dart';

enum BadgeType { success, warning, danger, info }

/// Lencana status datar (Badge) berlatar belakang semi-transparan untuk
/// merender status pengerjaan kamar (Pending, In Progress, Completed, Dirty).
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  /// Factory helper untuk status dari String (misal dari database)
  factory StatusBadge.fromStatusString(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'completed' || lowerStatus == 'clean' || lowerStatus == 'inspected') {
      return const StatusBadge(label: 'Clean', type: BadgeType.success);
    } else if (lowerStatus == 'in progress' || lowerStatus == 'in_progress') {
      return const StatusBadge(label: 'In Progress', type: BadgeType.info);
    } else if (lowerStatus == 'dirty' || lowerStatus == 'pending') {
      return const StatusBadge(label: 'Dirty', type: BadgeType.danger);
    }
    return StatusBadge(label: status, type: BadgeType.warning);
  }

  @override
  Widget build(BuildContext context) {
    Color labelColor;
    Color bgColor;

    switch (type) {
      case BadgeType.success:
        labelColor = const Color(0xFF137333); // Google dark green
        bgColor = const Color(0xFFE6F4EA);    // Google light green
        break;
      case BadgeType.warning:
        labelColor = const Color(0xFFB06000); // Google dark orange
        bgColor = const Color(0xFFFEF7E0);    // Google light orange
        break;
      case BadgeType.danger:
        labelColor = const Color(0xFFC5221F); // Google dark red
        bgColor = const Color(0xFFFCE8E6);    // Google light red
        break;
      case BadgeType.info:
        labelColor = const Color(0xFF174EA6); // Google dark blue
        bgColor = const Color(0xFFE8F0FE);    // Google light blue
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
