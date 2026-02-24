import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement_model.dart';
import '../../providers/task_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AchievementCategory> _categories = [
    AchievementCategory.tasbih,
    AchievementCategory.prayer,
    AchievementCategory.durood,
    AchievementCategory.charity,
  ];

  String _categoryName(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.tasbih:
        return 'Tasbih';
      case AchievementCategory.prayer:
        return 'Prayer';
      case AchievementCategory.durood:
        return 'Durood';
      case AchievementCategory.charity:
        return 'Charity';
    }
  }

  IconData _categoryIcon(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.tasbih:
        return Icons.fingerprint;
      case AchievementCategory.prayer:
        return Icons.mosque;
      case AchievementCategory.durood:
        return Icons.favorite;
      case AchievementCategory.charity:
        return Icons.volunteer_activism;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: isDark ? Colors.white54 : AppColors.muted,
          tabs: _categories.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_categoryIcon(cat), size: 16),
                  const SizedBox(width: 8),
                  Text(_categoryName(cat)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Total Swab Points Header
            _buildPointsHeader(context, isDark),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((cat) {
                  return _buildCategoryList(context, cat, isDark);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHeader(BuildContext context, bool isDark) {
    final totalPoints = context.watch<TaskProvider>().totalPoints;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL SWAB EARNED',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                '$totalPoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
      BuildContext context, AchievementCategory cat, bool isDark) {
    final provider = context.watch<AchievementProvider>();
    final achievements = provider.getAchievementsByCategory(cat);

    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'No achievements yet.',
          style: TextStyle(color: isDark ? Colors.white54 : AppColors.muted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final ach = achievements[index];
        final isUnlocked = provider.isUnlocked(ach.id);
        return _buildAchievementCard(ach, isUnlocked, isDark);
      },
    );
  }

  Widget _buildAchievementCard(
      AchievementModel ach, bool isUnlocked, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark ? const Color(0xFF2B2E33) : Colors.white)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? AppColors.accent.withValues(alpha: 0.5)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppColors.accent.withValues(alpha: 0.15)
                : (isDark ? Colors.white10 : Colors.black12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUnlocked ? Icons.verified_rounded : Icons.lock_rounded,
            color: isUnlocked
                ? AppColors.accent
                : (isDark ? Colors.white38 : Colors.black38),
            size: 24,
          ),
        ),
        title: Text(
          ach.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isUnlocked
                ? (isDark ? Colors.white : AppColors.darkText)
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            ach.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : AppColors.muted,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppColors.accent
                : (isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.diamond_rounded,
                color: isUnlocked ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${ach.rewardPoints}',
                style: TextStyle(
                  color: isUnlocked ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
