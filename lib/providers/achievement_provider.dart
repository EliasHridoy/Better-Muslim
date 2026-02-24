import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../services/local_storage_service.dart';
import '../widgets/achievement_unlocked_dialog.dart';

import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class AchievementProvider with ChangeNotifier {
  List<UserAchievement> _userAchievements = [];

  static const List<AchievementModel> allAchievements = [
    // Tasbih
    AchievementModel(
      id: 'tasbih_33',
      title: 'Tasbih Starter',
      description: 'Count 33 tasbihs in a single session.',
      category: AchievementCategory.tasbih,
      targetCount: 33,
      rewardPoints: 10,
    ),
    AchievementModel(
      id: 'tasbih_66',
      title: 'Tasbih Pro',
      description: 'Count 66 tasbihs in a single session.',
      category: AchievementCategory.tasbih,
      targetCount: 66,
      rewardPoints: 20,
    ),
    AchievementModel(
      id: 'tasbih_99',
      title: 'Tasbih Master',
      description: 'Count 99 tasbihs in a single session.',
      category: AchievementCategory.tasbih,
      targetCount: 99,
      rewardPoints: 50,
    ),
    // Prayer
    AchievementModel(
      id: 'prayer_5',
      title: 'Daily Prayers',
      description: 'Complete 5 mandatory prayers in a day.',
      category: AchievementCategory.prayer,
      targetCount: 5,
      rewardPoints: 25,
    ),
    AchievementModel(
      id: 'prayer_35',
      title: 'Weekly Prayers',
      description: 'Complete 35 prayers (7 days).',
      category: AchievementCategory.prayer,
      targetCount: 35,
      rewardPoints: 100,
    ),
    AchievementModel(
      id: 'prayer_75',
      title: 'Dedicated Worshiper',
      description: 'Complete 75 prayers.',
      category: AchievementCategory.prayer,
      targetCount: 75,
      rewardPoints: 150,
    ),
    AchievementModel(
      id: 'prayer_150',
      title: 'Steadfast Believer',
      description: 'Complete 150 prayers.',
      category: AchievementCategory.prayer,
      targetCount: 150,
      rewardPoints: 300,
    ),
    AchievementModel(
      id: 'prayer_300',
      title: 'Pillar of Faith',
      description: 'Complete 300 prayers.',
      category: AchievementCategory.prayer,
      targetCount: 300,
      rewardPoints: 500,
    ),
    // Durood
    AchievementModel(
      id: 'durood_10',
      title: 'First Blessings',
      description: 'Recite 10 Duroods.',
      category: AchievementCategory.durood,
      targetCount: 10,
      rewardPoints: 10,
    ),
    AchievementModel(
      id: 'durood_25',
      title: 'Consistent Blessings',
      description: 'Recite 25 Duroods.',
      category: AchievementCategory.durood,
      targetCount: 25,
      rewardPoints: 20,
    ),
    AchievementModel(
      id: 'durood_100',
      title: 'Durood Starter',
      description: 'Recite 100 Duroods.',
      category: AchievementCategory.durood,
      targetCount: 100,
      rewardPoints: 50,
    ),
    AchievementModel(
      id: 'durood_300',
      title: 'Durood Devotee',
      description: 'Recite 300 Duroods.',
      category: AchievementCategory.durood,
      targetCount: 300,
      rewardPoints: 100,
    ),
    AchievementModel(
      id: 'durood_500',
      title: 'Durood Master',
      description: 'Recite 500 Duroods.',
      category: AchievementCategory.durood,
      targetCount: 500,
      rewardPoints: 200,
    ),
    // Charity
    AchievementModel(
      id: 'charity_50',
      title: 'First Charity',
      description: 'Donate a total of 50.',
      category: AchievementCategory.charity,
      targetCount: 50,
      rewardPoints: 15,
    ),
    AchievementModel(
      id: 'charity_200',
      title: 'Helpful Hand',
      description: 'Donate a total of 200.',
      category: AchievementCategory.charity,
      targetCount: 200,
      rewardPoints: 30,
    ),
    AchievementModel(
      id: 'charity_500',
      title: 'Generous Giver',
      description: 'Donate a total of 500.',
      category: AchievementCategory.charity,
      targetCount: 500,
      rewardPoints: 75,
    ),
    AchievementModel(
      id: 'charity_1000',
      title: 'Selfless Soul',
      description: 'Donate a total of 1000.',
      category: AchievementCategory.charity,
      targetCount: 1000,
      rewardPoints: 150,
    ),
    AchievementModel(
      id: 'charity_5000',
      title: 'Philanthropist',
      description: 'Donate a total of 5000.',
      category: AchievementCategory.charity,
      targetCount: 5000,
      rewardPoints: 500,
    ),
  ];

  AchievementProvider() {
    _loadLocalData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadLocalData() {
    _userAchievements = LocalStorageService.getUserAchievements();
    notifyListeners();
  }

  // Reload dynamically if synced from cloud
  void reload() {
    _loadLocalData();
  }

  bool isUnlocked(String achievementId) {
    return _userAchievements
        .any((a) => a.achievementId == achievementId && a.isUnlocked);
  }

  UserAchievement? getUserAchievement(String achievementId) {
    return _userAchievements
        .where((a) => a.achievementId == achievementId)
        .firstOrNull;
  }

  List<AchievementModel> getAchievementsByCategory(AchievementCategory cat) {
    return allAchievements.where((a) => a.category == cat).toList();
  }

  /// Check target and unlock if reached.
  /// Returns the points rewarded, or 0 if no achievement was unlocked.
  Future<int> checkAndUnlock(BuildContext context, AchievementCategory category, {int? defaultCount}) async {
    int totalRewardedPoints = 0;
    final taskProvider = context.read<TaskProvider>();

    final relevantAchievements = getAchievementsByCategory(category);
    for (final ach in relevantAchievements) {
      if (isUnlocked(ach.id)) continue;

      int currentCount = defaultCount ?? 0;

      // Override count for complex achievements
      if (category == AchievementCategory.prayer) {
        if (ach.id == 'prayer_5') {
          currentCount = taskProvider.prayerTasks.where((p) => taskProvider.isTaskCompletedToday(p.id)).length;
        } else if (ach.id == 'prayer_35') {
          final weeklyData = taskProvider.getWeeklyCompletions(category: TaskCategory.prayer);
          currentCount = weeklyData.fold(0, (sum, val) => sum + val);
        } else {
          currentCount = taskProvider.totalPrayersCompletedLifetime;
        }
      } else if (category == AchievementCategory.charity) {
        currentCount = taskProvider.totalCharityAmount.toInt();
      } else if (category == AchievementCategory.durood) {
        currentCount = taskProvider.totalDurudhLifetimeCount;
      }

      if (currentCount >= ach.targetCount) {
        totalRewardedPoints += ach.rewardPoints;
        await _unlockAchievement(context, ach);
      }
    }
    return totalRewardedPoints;
  }

  Future<void> _unlockAchievement(BuildContext context, AchievementModel ach) async {
    final entry = UserAchievement(
      achievementId: ach.id,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    _userAchievements.removeWhere((a) => a.achievementId == ach.id);
    _userAchievements.add(entry);

    LocalStorageService.saveUserAchievements(_userAchievements);

    // Show dialog on the root navigator so it survives screen pops
    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => AchievementUnlockedDialog(ach),
    );
    notifyListeners();
  }
}
