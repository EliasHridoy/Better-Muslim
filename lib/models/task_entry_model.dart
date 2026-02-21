class TaskEntry {
  final String id;
  final String taskId;
  final DateTime date;
  final bool completed;
  final int count; // For tasbih counting
  final DateTime lastModified;

  TaskEntry({
    required this.id,
    required this.taskId,
    required this.date,
    this.completed = false,
    this.count = 0,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  TaskEntry copyWith({
    String? id,
    String? taskId,
    DateTime? date,
    bool? completed,
    int? count,
    DateTime? lastModified,
  }) {
    return TaskEntry(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      count: count ?? this.count,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'date': date.toIso8601String(),
      'completed': completed,
      'count': count,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory TaskEntry.fromMap(Map<String, dynamic> map) {
    return TaskEntry(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      completed: map['completed'] ?? false,
      count: map['count'] ?? 0,
      lastModified: DateTime.tryParse(map['lastModified'] ?? '') ?? DateTime.now(),
    );
  }
}
