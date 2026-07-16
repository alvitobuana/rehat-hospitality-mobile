class ChecklistItem {
  final int id;
  final String itemName;
  final bool isChecked;

  ChecklistItem({
    required this.id,
    required this.itemName,
    required this.isChecked,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final checkedVal = json['is_checked'];
    bool checked = false;
    if (checkedVal is bool) {
      checked = checkedVal;
    } else if (checkedVal is int) {
      checked = checkedVal == 1;
    } else if (checkedVal is String) {
      checked = checkedVal == '1' || checkedVal.toLowerCase() == 'true';
    }
    return ChecklistItem(
      id: json['id'] as int? ?? 0,
      itemName: json['item_name'] as String? ?? '',
      isChecked: checked,
    );
  }

  /// Menghasilkan salinan baru ChecklistItem dengan nilai yang diperbarui
  ChecklistItem copyWith({bool? isChecked}) {
    return ChecklistItem(
      id: id,
      itemName: itemName,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'is_checked': isChecked,
    };
  }
}

class TaskDetail {
  final int taskId;
  final String room;
  final String description;
  final String status;
  final String assignedStaff;
  final String createdAt;
  final List<ChecklistItem> checklist;
  final int photoCount;
  final List<String> photos;

  TaskDetail({
    required this.taskId,
    required this.room,
    required this.description,
    required this.status,
    required this.assignedStaff,
    required this.createdAt,
    required this.checklist,
    this.photoCount = 0,
    this.photos = const [],
  });

  // ---------------------------------------------------------------------------
  // Sprint 7.1: Checklist Progress Getters
  // ---------------------------------------------------------------------------

  /// Jumlah item checklist yang telah dicentang
  int get checklistDoneCount => checklist.where((item) => item.isChecked).length;

  /// Total item checklist
  int get checklistTotalCount => checklist.length;

  /// true jika semua item checklist sudah dicentang ATAU tidak ada item checklist
  bool get isChecklistComplete =>
      checklist.isEmpty || checklistDoneCount == checklist.length;

  // ---------------------------------------------------------------------------

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    final list = json['checklist'] as List? ?? [];
    final photosList = json['photos'] as List? ?? [];
    return TaskDetail(
      taskId: json['task_id'] as int? ?? 0,
      room: json['room'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      assignedStaff: json['assigned_staff'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      checklist: list.map((item) => ChecklistItem.fromJson(item)).toList(),
      photoCount: json['photo_count'] as int? ?? 0,
      photos: photosList.map((p) => (p['photo_path'] ?? '') as String).where((path) => path.isNotEmpty).toList(),
    );
  }

  /// Menghasilkan salinan baru TaskDetail dengan nilai yang diperbarui
  TaskDetail copyWith({
    String? status,
    List<ChecklistItem>? checklist,
    int? photoCount,
    List<String>? photos,
  }) {
    return TaskDetail(
      taskId: taskId,
      room: room,
      description: description,
      status: status ?? this.status,
      assignedStaff: assignedStaff,
      createdAt: createdAt,
      checklist: checklist ?? this.checklist,
      photoCount: photoCount ?? this.photoCount,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'room': room,
      'description': description,
      'status': status,
      'assigned_staff': assignedStaff,
      'created_at': createdAt,
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'photo_count': photoCount,
      'photos': photos,
    };
  }
}
