import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_times_provider.dart';
import '../../services/quran_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/tier_calculator.dart';
import '../prayer/prayer_tracker_screen.dart';
import '../tasbih/tasbih_counter_screen.dart';
import '../durudh/durudh_counter_screen.dart';
import '../charity/charity_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  QuranVerse? _verse;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    final verse = await QuranService.getVerseOfTheDay();
    if (mounted) setState(() => _verse = verse);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final prayerTimesProvider = context.watch<PrayerTimesProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Greeting ────────────────────────────
              _buildGreetingHeader(context, theme),
              const SizedBox(height: 20),

              // ─── Next Prayer Countdown ────────────────
              _buildNextPrayerCard(context, prayerTimesProvider, isDark),
              const SizedBox(height: 16),

              // ─── Daily Quran Verse ────────────────────
              if (_verse != null) ...[
                _buildQuranVerseCard(context, _verse!, isDark),
                const SizedBox(height: 20),
              ],

              // ─── Sawab Points Card ───────────────────
              _buildSawabCard(context, taskProvider, isDark),
              const SizedBox(height: 20),

              // ─── Daily Progress ──────────────────────
              _buildDailyProgress(context, taskProvider, isDark),
              const SizedBox(height: 20),

              // ─── Today's Ibadat ─────────────────────────
              Row(
                children: [
                  Text('Today\'s Ibadat', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildIbadatGrid(context, taskProvider, isDark),
              const SizedBox(height: 24),

              // ─── Weekly Overview ─────────────────────
              Text('This Week', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildWeekOverview(context, taskProvider, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Next Prayer Countdown Card ─────────────────────────
  Widget _buildNextPrayerCard(
      BuildContext context, PrayerTimesProvider provider, bool isDark) {
    final next = provider.nextPrayer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [(isDark ? AppColors.darkSurface : AppColors.lightSurface), AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkSurface : AppColors.muted).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: provider.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    next?.icon ?? Icons.mosque_rounded,
                    color: isDark ? Colors.white : AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Prayer',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.darkText.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        next?.name ?? 'Loading...',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkText,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      next?.formatted ?? '--:--',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'in ${provider.timeUntilNextFormatted}',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.darkText.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ─── Daily Quran Verse Card ─────────────────────────────
  Widget _buildQuranVerseCard(
      BuildContext context, QuranVerse verse, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Verse of the Day',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            verse.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'serif',
                  height: 1.8,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '"${verse.translation}"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.muted : AppColors.muted,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${verse.reference}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }


  Widget _buildGreetingHeader(BuildContext context, ThemeData theme) {
    final authProvider = context.watch<AuthProvider>();
    final name = authProvider.isLoggedIn ? authProvider.displayName : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateHelpers.getGreeting(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name != null
                    ? 'Assalamu Alaikum, $name ☪'
                    : 'Assalamu Alaikum ☪',
                style: theme.textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: AppColors.accent, size: 28),
        ),
      ],
    );
  }

  Widget _buildSawabCard(
      BuildContext context, TaskProvider provider, bool isDark) {
    final tier = TierCalculator.getTier(provider.totalPoints);
    final tierColor = TierCalculator.getTierColor(tier);
    final progress = TierCalculator.getTierProgress(provider.totalPoints);
    final nextTier = TierCalculator.getNextTierPoints(provider.totalPoints);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.9),
            AppColors.accent.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sawab Points',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TierCalculator.getTierIcon(tier),
                        color: tierColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      tier,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.totalPoints}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation(Colors.black54),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.totalPoints >= 2000
                ? 'Max tier reached! 🏆'
                : '${nextTier - provider.totalPoints} points to next tier',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress(
      BuildContext context, TaskProvider provider, bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          context,
          icon: Icons.local_fire_department,
          iconColor: AppColors.accent,
          label: 'Streak',
          value: '${provider.streak} days',
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          icon: Icons.check_circle,
          iconColor: AppColors.accent,
          label: 'Today',
          value: '${provider.todayCompletedCount}/${provider.todayTotalTasks}',
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          icon: Icons.people,
          iconColor: AppColors.accent,
          label: 'Friends',
          value: '${context.read<FriendsProvider>().friends.length}',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? null
              : Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIbadatGrid(
      BuildContext context, TaskProvider provider, bool isDark) {
    // Get values from provider
    final prayerCompleted = provider.prayerTasks
        .where((t) => provider.isTaskCompletedToday(t.id))
        .length;
    final prayerTotal = provider.prayerTasks.length;

    int totalTasbih = 0;
    for (var task in provider.tasbihTasks) {
      totalTasbih += provider.getTasbihCountToday(task.id);
    }

    double totalSadaka = 0;
    final todayStr = DateHelpers.dateKey(DateTime.now());
    for (var entry in provider.allCharityEntries) {
      if (DateHelpers.dateKey(entry.date) == todayStr) {
        totalSadaka += entry.amount;
      }
    }

    final duroodCount = provider.durudhCountToday;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _buildIbadatCard(
            context,
            isDark: isDark,
            icon: Icons.mosque,
            iconBgColor: AppColors.accent,
            iconColor: AppColors.accent,
            title: 'PRAYER',
            valueWidget: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$prayerCompleted', style: _valueStyle(isDark)),
                Text(' / $prayerTotal',
                    style: _valueStyle(isDark).copyWith(
                        color: AppColors.muted, fontSize: 24)),
              ],
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('+120 xp',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrayerTrackerScreen())),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _buildIbadatCard(
            context,
            isDark: isDark,
            icon: Icons.favorite,
            iconBgColor: AppColors.accent,
            iconColor: AppColors.accent,
            title: 'TASBIH',
            valueWidget: Text('$totalTasbih', style: _valueStyle(isDark)),
            footerText: 'Dhikr for heart purity',
            footerColor: AppColors.muted,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TasbihCounterScreen())),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _buildIbadatCard(
            context,
            isDark: isDark,
            icon: Icons.auto_awesome,
            iconBgColor: AppColors.accent,
            iconColor: AppColors.accent,
            title: 'DUROOD',
            valueWidget: Text('$duroodCount', style: _valueStyle(isDark)),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DurudhCounterScreen())),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _buildIbadatCard(
            context,
            isDark: isDark,
            icon: Icons.volunteer_activism,
            iconBgColor: AppColors.accent,
            iconColor: AppColors.accent,
            title: 'SADAKA',
            valueWidget: Text(
                totalSadaka > 0 ? totalSadaka.toStringAsFixed(0) : '0',
                style: _valueStyle(isDark)),
            footerText: 'Donated today',
            footerColor: AppColors.muted,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CharityTrackerScreen())),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: _buildIbadatCard(
            context,
            isDark: isDark,
            icon: Icons.nightlight_round,
            iconBgColor: AppColors.accent,
            iconColor: AppColors.accent,
            title: 'SIAM',
            valueWidget: Text(
              provider.isFastingToday ? '✓' : '—',
              style: _valueStyle(isDark).copyWith(
                color: provider.isFastingToday
                    ? AppColors.accent
                    : AppColors.muted,
              ),
            ),
            footerText: provider.isFastingToday ? 'Fasting today' : 'Tap to mark',
            footerColor: AppColors.muted,
            onTap: () => provider.toggleFasting(),
          ),
        ),
      ],
    );
  }

  TextStyle _valueStyle(bool isDark) {
    return TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: isDark ? Colors.white : AppColors.darkText,
    );
  }

  Widget _buildIbadatCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required Widget valueWidget,
    Widget? badgeWidget,
    String? footerText,
    Color? footerColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(color: Colors.white10)
              : Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badgeWidget != null) badgeWidget,
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            valueWidget,
            if (footerText != null) ...[
              const SizedBox(height: 8),
              Text(
                footerText,
                style: TextStyle(
                  color: footerColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              const SizedBox(height: 19),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekOverview(
      BuildContext context, TaskProvider provider, bool isDark) {
    final weekDays = DateHelpers.getWeekDays();
    final completions = provider.getWeeklyCompletions();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final isToday = DateHelpers.isToday(weekDays[i]);
          final count = completions[i];
          final maxCount = provider.todayTotalTasks;
          final fillRatio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: count > 0
                      ? AppColors.accent.withValues(alpha: 0.15 + fillRatio * 0.85)
                      : isDark
                          ? Colors.white10
                          : AppColors.secondary.withValues(alpha: 0.1),
                  border: isToday
                      ? Border.all(color: AppColors.accent, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    DateHelpers.formatDayNumber(weekDays[i]),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: count > 0
                          ? Colors.black87
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateHelpers.formatDay(weekDays[i]),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
