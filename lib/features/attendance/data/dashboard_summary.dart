class DashboardSummary {
  final int pending;
  final int inProgress;
  final int completed;
  final int todayTotal;

  DashboardSummary({
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.todayTotal,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      pending: json['pending'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      todayTotal: json['today_total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending': pending,
      'in_progress': inProgress,
      'completed': completed,
      'today_total': todayTotal,
    };
  }
}
