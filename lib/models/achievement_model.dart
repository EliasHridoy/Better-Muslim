import 'dart:convert';

enum AchievementCategory { tasbih, prayer, durood, charity }

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final int targetCount;
  final int rewardPoints;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    required this.rewardPoints,
  });
}

class UserAchievement {
  final String achievementId;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  UserAchievement({
    required this.achievementId,
    required this.isUnlocked,
    this.unlockedAt,
  });

  UserAchievement copyWith({
    String? achievementId,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return UserAchievement(
      achievementId: achievementId ?? this.achievementId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievementId'] ?? '',
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.tryParse(map['unlockedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserAchievement.fromJson(String source) =>
      UserAchievement.fromMap(json.decode(source));
}
