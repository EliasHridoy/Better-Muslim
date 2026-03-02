import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_times_provider.dart';
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
  // Colors from the Stitch design to match precisely
  static const Color stitchPrimary = Color(0xFF13ECC8);
  static const Color stitchBgDark = Color(0xFF10221F);
  static const Color stitchBgLight = Color(0xFFF5F6F7);
  static const Color stitchCardDark = Color(0xFF2D343F);
  static const Color stitchPrayerCardBg = Color(0xFF7B7F85);
  static const Color stitchPrayerCardText = Color(0xFFF5F6F7);

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final prayerTimesProvider = context.watch<PrayerTimesProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? stitchBgDark : stitchBgLight;
    final textColor = isDark ? Colors.white : const Color(0xFF2B2E33);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Banner ────────────────────────────
            _buildTopBanner(context, taskProvider, authProvider, isDark, bgColor, textColor),

            // ─── Main Content Area (Overlapping the banner slightly) ────────────────
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Sawab Goal Card
                    _buildSawabGoalCard(context, taskProvider, isDark),
                    const SizedBox(height: 24),

                    // Prayer Times Grid
                    _buildPrayerGrid(context, prayerTimesProvider, isDark),
                    const SizedBox(height: 32),

                    // Today's Ibadat Header
                    _buildIbadatHeader(context, isDark, textColor),
                    const SizedBox(height: 16),

                    // Today's Ibadat Grid & Siam Card
                    _buildIbadatGrid(context, taskProvider, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(
      BuildContext context, TaskProvider taskProvider, AuthProvider authProvider, bool isDark, Color bgColor, Color textColor) {
    final name = authProvider.isLoggedIn ? authProvider.displayName ?? 'Muslim' : 'Muslim';

    return Stack(
      children: [
        // Banner Image
        Container(
          width: double.infinity,
          height: 320,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/banner.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                bgColor.withValues(alpha: 0.6),
                bgColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Profile Content
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? stitchCardDark : Colors.white,
                  border: Border.all(
                    color: isDark ? stitchBgDark : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 56,
                  color: isDark ? Colors.white70 : Colors.black26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              Text(
                '${taskProvider.totalPoints} Sawab Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSawabGoalCard(
      BuildContext context, TaskProvider provider, bool isDark) {
    // Let's assume the goal is the next tier points, or a fixed amount if max tier
    final target = TierCalculator.getNextTierPoints(provider.totalPoints);
    final current = provider.totalPoints;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // slate-800
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Text(
                'Sawab Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A), // slate-900
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stitchPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: stitchPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), // slate-700 / slate-100
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: stitchPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), // slate-400 / slate-500
                ),
              ),
              Text(
                '$current / $target',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerGrid(
      BuildContext context, PrayerTimesProvider provider, bool isDark) {
    if (provider.isLoading || provider.prayerTimes.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Filter to standard 5 prayers + highlight current
    final standardPrayers = provider.prayerTimes.where((p) {
      final n = p.name.toLowerCase();
      return n == 'fajr' || n == 'dhuhr' || n == 'asr' || n == 'maghrib' || n == 'isha';
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: standardPrayers.map((prayer) {
        final isCurrent = provider.currentPrayer?.name == prayer.name;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isCurrent ? stitchPrimary : stitchPrayerCardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  prayer.name.toUpperCase(),
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFF10221F) : stitchPrayerCardText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prayer.formatted,
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFF10221F).withValues(alpha: 0.9) : stitchPrayerCardText.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIbadatHeader(BuildContext context, bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today\'s Ibadat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), // slate-700 / slate-200
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'DAILY GOALS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), // slate-300 / slate-600
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIbadatGrid(
      BuildContext context, TaskProvider provider, bool isDark) {
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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildIbadatCard(
                isDark: isDark,
                bgColor: isDark ? const Color(0xFF475569) : const Color(0xFF64748B), // slate-600 / slate-500
                icon: Icons.water_drop,
                title: 'PRAYER',
                valueStr: '$prayerCompleted/$prayerTotal',
                subtitle: 'Sawab Earned',
                isLightText: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrayerTrackerScreen())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildIbadatCard(
                isDark: isDark,
                bgColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1), // slate-400 / slate-300
                icon: Icons.favorite,
                title: 'TASBIH',
                subtitleDesc: 'Dhikr for heart purity',
                valueStr: '$totalTasbih',
                subtitle: 'Recitations',
                isLightText: false,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TasbihCounterScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildIbadatCard(
                isDark: isDark,
                bgColor: isDark ? const Color(0xFF475569) : const Color(0xFF64748B),
                icon: Icons.psychology,
                title: 'DUROOD',
                valueStr: '$duroodCount',
                subtitle: 'Total',
                isLightText: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DurudhCounterScreen())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildIbadatCard(
                isDark: isDark,
                bgColor: isDark ? const Color(0xFF475569) : const Color(0xFF64748B),
                icon: Icons.volunteer_activism,
                title: 'SADAKA',
                valueStr: totalSadaka > 0 ? totalSadaka.toStringAsFixed(0) : '0',
                subtitle: 'Sadaka Donated',
                isLightText: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CharityTrackerScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Siam Card
        _buildSiamCard(context, provider, isDark),
      ],
    );
  }

  Widget _buildIbadatCard({
    required bool isDark,
    required Color bgColor,
    required IconData icon,
    required String title,
    String? subtitleDesc,
    required String valueStr,
    required String subtitle,
    required bool isLightText,
    required VoidCallback onTap,
  }) {
    final mainColor = isLightText ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isLightText ? Colors.white70 : const Color(0xFF334155);
    final iconBgColor = isLightText ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 176, // h-44 in tailwind
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Icon
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(96),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24),
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 32,
                      color: isLightText ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: mutedColor,
                      ),
                    ),
                    if (subtitleDesc != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitleDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isLightText ? Colors.white60 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valueStr,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: mainColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiamCard(BuildContext context, TaskProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF475569) : const Color(0xFF64748B), // slate-600 / slate-500
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.nights_stay,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SIAM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Log your fast for today',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: provider.isFastingToday,
            onChanged: (val) => provider.toggleFasting(),
            activeColor: Colors.white,
            activeTrackColor: stitchPrimary,
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.black26,
          ),
        ],
      ),
    );
  }
}
