class TaskModel {
  final int taskId;
  final String roomNumber;
  final String floor;
  final String cleaningType;
  final String status;
  final String priority;

  TaskModel({
    required this.taskId,
    required this.roomNumber,
    required this.floor,
    required this.cleaningType,
    required this.status,
    required this.priority,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['task_id'] as int? ?? 0,
      roomNumber: json['room_number'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      cleaningType: json['cleaning_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'room_number': roomNumber,
      'floor': floor,
      'cleaning_type': cleaningType,
      'status': status,
      'priority': priority,
    };
  }
}
