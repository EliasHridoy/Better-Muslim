import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import 'dua_page_screen.dart';

class PrayerTrackerScreen extends StatelessWidget {
  const PrayerTrackerScreen({super.key});

  void _onPrayerTap(BuildContext context, TaskModel prayer, TaskProvider provider) {
    final wasCompleted = provider.isTaskCompletedToday(prayer.id);
    provider.togglePrayer(prayer.id);

    // Navigate to dua page when marking Fajr or Isha as complete
    if (!wasCompleted) {
      final title = prayer.title.toLowerCase();
      if (title == 'fajr' || title == 'isha') {
        Navigator.push<int>(
          context,
          MaterialPageRoute(
            builder: (_) => DuaPageScreen(
              prayerName: prayer.title,
              onPointsEarned: () {},
            ),
          ),
        ).then((points) {
          if (points != null && points > 0 && context.mounted) {
            provider.addBonusPoints(points);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🌟 +$points bonus Sawab earned from duas!'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prayers = taskProvider.prayerTasks;
    final completedCount =
        prayers.where((p) => taskProvider.isTaskCompletedToday(p.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddPrayerDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Progress Header ────────────────────────
            _buildProgressHeader(context, completedCount, prayers.length, isDark),
            const SizedBox(height: 24),

            // ─── Prayer list ────────────────────────────
            Text('Daily Prayers', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...prayers.map((prayer) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPrayerTile(context, prayer, taskProvider, isDark),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(
      BuildContext context, int completed, int total, bool isDark) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: isDark ? Colors.white10 : AppColors.secondary.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completed/$total',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Prayers',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            completed == total && total > 0
                ? 'All prayers completed! MashaAllah 🌟'
                : 'Keep going, you\'re doing great!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTile(
      BuildContext context, TaskModel prayer, TaskProvider provider, bool isDark) {
    final completed = provider.isTaskCompletedToday(prayer.id);

    return GestureDetector(
      onTap: () => _onPrayerTap(context, prayer, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.accent.withValues(alpha: 0.12)
              : isDark
                  ? AppColors.darkCard
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? AppColors.accent
                : isDark
                    ? Colors.white10
                    : AppColors.secondary.withValues(alpha: 0.3),
            width: completed ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                completed ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(completed),
                color: completed ? AppColors.accent : AppColors.muted,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                prayer.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          completed ? TextDecoration.lineThrough : null,
                      color: completed ? AppColors.muted : null,
                    ),
              ),
            ),
            if (completed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+1 Sawab',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPrayerDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Prayer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Prayer name (e.g. Tahajjud)',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<TaskProvider>()
                    .addTask(controller.text.trim(), TaskCategory.prayer);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
