enum TaskCategory { prayer, tasbih, charity, custom }

class TaskModel {
  final String id;
  final String title;
  final TaskCategory category;
  final bool isDefault;
  final String userId;
  final int targetCount; // For tasbih: target count per session

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    this.isDefault = true,
    this.userId = 'local',
    this.targetCount = 33,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    bool? isDefault,
    String? userId,
    int? targetCount,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      targetCount: targetCount ?? this.targetCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'isDefault': isDefault,
      'userId': userId,
      'targetCount': targetCount,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: TaskCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => TaskCategory.custom,
      ),
      isDefault: map['isDefault'] ?? true,
      userId: map['userId'] ?? 'local',
      targetCount: map['targetCount'] ?? 33,
    );
  }
}
