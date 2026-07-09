/// Model representasi satu entri riwayat tugas housekeeping yang telah selesai
/// Sesuai response backend: GET /Housekeeping/api_get_history.php
class HistoryItem {
  final int taskId;
  final String roomNumber;
  final String cleaningType;

  /// Timestamp penyelesaian dari backend (format: "YYYY-MM-DD HH:mm:ss")
  final String completedAt;

  HistoryItem({
    required this.taskId,
    required this.roomNumber,
    required this.cleaningType,
    required this.completedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      taskId: json['task_id'] as int? ?? 0,
      roomNumber: json['room_number'] as String? ?? '',
      cleaningType: json['cleaning_type'] as String? ?? '',
      completedAt: json['completed_at'] as String? ?? '',
    );
  }

  /// Format tanggal singkat untuk tampilan di card
  /// Input: "2026-07-09 14:30:00" → Output: "09 Jul 2026, 14:30"
  String get formattedDate {
    try {
      final dt = DateTime.parse(completedAt);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final d = dt.day.toString().padLeft(2, '0');
      final m = months[dt.month - 1];
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d $m $y, $h:$min';
    } catch (_) {
      return completedAt;
    }
  }
}
