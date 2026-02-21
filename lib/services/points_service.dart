import '../config/constants.dart';
import '../utils/tier_calculator.dart';

class PointsService {
  static int calculateDailyPoints(int completedTasks) {
    return completedTasks * AppConstants.pointsPerTask;
  }

  static String calculateTier(int totalPoints) {
    return TierCalculator.getTier(totalPoints);
  }

  static int getStreakBonus(int streakDays) {
    if (streakDays >= 30) return 10;
    if (streakDays >= 14) return 5;
    if (streakDays >= 7) return 3;
    if (streakDays >= 3) return 1;
    return 0;
  }
}
