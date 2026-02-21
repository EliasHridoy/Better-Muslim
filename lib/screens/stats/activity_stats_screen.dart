import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../../utils/tier_calculator.dart';

class ActivityStatsScreen extends StatefulWidget {
  const ActivityStatsScreen({super.key});

  @override
  State<ActivityStatsScreen> createState() => _ActivityStatsScreenState();
}

class _ActivityStatsScreenState extends State<ActivityStatsScreen> {
  bool _showMonthly = false;
  TaskCategory? _selectedCategory; // null = All

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weeklyData = taskProvider.getWeeklyCompletions(category: _selectedCategory);
    final monthlyData = taskProvider.getMonthlyCompletions(category: _selectedCategory);
    final maxTasks = _selectedCategory == null
        ? taskProvider.todayTotalTasks
        : _selectedCategory == TaskCategory.prayer
            ? taskProvider.prayerTasks.length
            : taskProvider.tasbihTasks.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Stats')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Summary cards ─────────────────────────
            _buildSummaryRow(context, taskProvider, isDark),
            const SizedBox(height: 24),

            // ─── Chart with toggle ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showMonthly ? 'Monthly Activity' : 'Weekly Activity',
                  style: theme.textTheme.titleLarge,
                ),
                _buildToggle(isDark),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Category filter chips ──────────────────
            _buildCategoryChips(isDark),
            const SizedBox(height: 16),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showMonthly
                  ? _buildMonthlyChart(context, monthlyData, maxTasks, isDark)
                  : _buildWeeklyChart(context, weeklyData, maxTasks, isDark),
            ),
            const SizedBox(height: 24),

            // ─── Tier Progress ─────────────────────────
            Text('Tier Progress', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildTierProgress(context, taskProvider, isDark),
            const SizedBox(height: 24),

            // ─── Category breakdown ────────────────────
            Text('Today\'s Breakdown', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildCategoryBreakdown(context, taskProvider, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Category Filter Chips ──────────────────────────────
  Widget _buildCategoryChips(bool isDark) {
    final items = <({String label, TaskCategory? value, IconData icon})>[
      (label: 'All', value: null, icon: Icons.grid_view_rounded),
      (label: 'Prayer', value: TaskCategory.prayer, icon: Icons.mosque_rounded),
      (label: 'Tasbih', value: TaskCategory.tasbih, icon: Icons.touch_app_rounded),
    ];

    return Row(
      children: items.map((item) {
        final isActive = _selectedCategory == item.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = item.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : isDark
                        ? Colors.white10
                        : AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? AppColors.accent
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon,
                      size: 16,
                      color: isActive ? AppColors.accent : AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? AppColors.accent : AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Week', !_showMonthly, isDark),
          _toggleBtn('Month', _showMonthly, isDark),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _showMonthly = label == 'Month'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, TaskProvider provider, bool isDark) {
    return Row(
      children: [
        _buildSummaryCard(
          context,
          title: 'Total Sawab',
          value: '${provider.totalPoints}',
          icon: Icons.diamond,
          color: AppColors.accent,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          context,
          title: 'Streak',
          value: '${provider.streak}d',
          icon: Icons.local_fire_department,
          color: AppColors.secondary,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          context,
          title: 'Tasbih',
          value: '${provider.totalTasbihCountToday}',
          icon: Icons.touch_app_rounded,
          color: AppColors.muted,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          context,
          title: 'Today',
          value:
              '${(provider.todayProgress * 100).toInt()}%',
          icon: Icons.pie_chart,
          color: AppColors.darkText,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          context,
          title: 'Siam',
          value: '${provider.totalFastingDays}',
          icon: Icons.nightlight_round,
          color: AppColors.muted,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? null
              : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 2),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
      BuildContext context, List<int> data, int maxTasks, bool isDark) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxTasks > 0 ? maxTasks.toDouble() : 9) + 1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[group.x.toInt()]} tasks',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekDays[value.toInt()],
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final isToday = i == DateTime.now().weekday - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].toDouble(),
                  color: isToday ? AppColors.accent : AppColors.accent.withValues(alpha: 0.4),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── Monthly Line Chart (last 30 days) ──────────────────
  Widget _buildMonthlyChart(
      BuildContext context, List<int> data, int maxTasks, bool isDark) {
    final now = DateTime.now();

    return Container(
      key: const ValueKey('monthly'),
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: LineChart(
        LineChartData(
          maxY: (maxTasks > 0 ? maxTasks.toDouble() : 9) + 1,
          minY: 0,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final date = now.subtract(Duration(days: 29 - spot.x.toInt()));
                return LineTooltipItem(
                  '${date.day}/${date.month}: ${spot.y.toInt()} tasks',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  final date = now.subtract(
                      Duration(days: 29 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(30, (i) =>
                  FlSpot(i.toDouble(), data[i].toDouble())),
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierProgress(
      BuildContext context, TaskProvider provider, bool isDark) {
    final tier = TierCalculator.getTier(provider.totalPoints);
    final progress = TierCalculator.getTierProgress(provider.totalPoints);
    final tierColor = TierCalculator.getTierColor(tier);

    final tiers = ['Bronze', 'Silver', 'Gold', 'Platinum'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(TierCalculator.getTierIcon(tier),
                      color: tierColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    tier,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              Text(
                '${provider.totalPoints} pts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isDark ? Colors.white10 : AppColors.secondary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(tierColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiers.map((t) {
              final isActive = t == tier;
              return Text(
                t,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? TierCalculator.getTierColor(t)
                      : AppColors.muted,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, TaskProvider provider, bool isDark) {
    final prayersDone =
        provider.prayerTasks.where((p) => provider.isTaskCompletedToday(p.id)).length;
    final tasbihCount = provider.totalTasbihCountToday;
    final durudhDone = provider.durudhCountToday;

    return Column(
      children: [
        _buildBreakdownTile(
          context,
          icon: Icons.mosque,
          label: 'Prayers',
          completed: prayersDone,
          total: provider.prayerTasks.length,
          color: AppColors.darkText,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildBreakdownTile(
          context,
          icon: Icons.touch_app,
          label: 'Tasbih',
          completed: tasbihCount,
          total: 0, // Show raw count, no denominator
          color: AppColors.muted,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildBreakdownTile(
          context,
          icon: Icons.auto_awesome,
          label: 'Durudh',
          completed: durudhDone,
          total: 0, // No specific daily max limit for Durood
          color: AppColors.secondary,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildBreakdownTile(
          context,
          icon: Icons.nightlight_round,
          label: 'Siam (Fasting)',
          completed: provider.isFastingToday ? 1 : 0,
          total: 1,
          color: AppColors.muted,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBreakdownTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int completed,
    required int total,
    required Color color,
    required bool isDark,
  }) {
    final hasTotal = total > 0;
    final progress = hasTotal ? (completed / total).clamp(0.0, 1.0) : (completed > 0 ? 1.0 : 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? Colors.white10
                        : AppColors.secondary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            hasTotal ? '$completed/$total' : '$completed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
