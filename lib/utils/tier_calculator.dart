import '../config/constants.dart';
import '../config/theme.dart';
import 'package:flutter/material.dart';

class TierCalculator {
  static String getTier(int points) {
    if (points >= AppConstants.platinumMin) return 'Platinum';
    if (points >= AppConstants.goldMin) return 'Gold';
    if (points >= AppConstants.silverMin) return 'Silver';
    return 'Bronze';
  }

  static Color getTierColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return AppColors.platinum;
      case 'Gold':
        return AppColors.gold;
      case 'Silver':
        return AppColors.silver;
      default:
        return AppColors.bronze;
    }
  }

  static IconData getTierIcon(String tier) {
    switch (tier) {
      case 'Platinum':
        return Icons.diamond;
      case 'Gold':
        return Icons.star;
      case 'Silver':
        return Icons.workspace_premium;
      default:
        return Icons.military_tech;
    }
  }

  static int getNextTierPoints(int currentPoints) {
    if (currentPoints < AppConstants.silverMin) return AppConstants.silverMin;
    if (currentPoints < AppConstants.goldMin) return AppConstants.goldMin;
    if (currentPoints < AppConstants.platinumMin) return AppConstants.platinumMin;
    return currentPoints; // Already at max
  }

  static double getTierProgress(int points) {
    final int current;
    final int next;
    if (points < AppConstants.silverMin) {
      current = AppConstants.bronzeMin;
      next = AppConstants.silverMin;
    } else if (points < AppConstants.goldMin) {
      current = AppConstants.silverMin;
      next = AppConstants.goldMin;
    } else if (points < AppConstants.platinumMin) {
      current = AppConstants.goldMin;
      next = AppConstants.platinumMin;
    } else {
      return 1.0;
    }
    return (points - current) / (next - current);
  }
}
