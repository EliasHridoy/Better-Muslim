import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/tier_calculator.dart';
import '../auth/login_screen.dart';
// register_screen.dart removed — passwordless auth uses a unified login screen
import '../stats/activity_stats_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../charity/charity_tracker_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tier = TierCalculator.getTier(taskProvider.totalPoints);
    final tierColor = TierCalculator.getTierColor(tier);
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Profile avatar ────────────────────────
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              child: const Icon(Icons.person, color: AppColors.accent, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.displayName,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            if (isLoggedIn && authProvider.firebaseUser?.email != null) ...[
              Text(
                authProvider.firebaseUser!.email!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TierCalculator.getTierIcon(tier),
                    color: tierColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$tier • ${taskProvider.totalPoints} Sawab',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── Stats row ─────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActivityStatsScreen())),
              child: Row(
                children: [
                  _buildProfileStat(context, 'Streak',
                      '${taskProvider.streak}d', Icons.local_fire_department, isDark),
                  const SizedBox(width: 12),
                  _buildProfileStat(context, 'Total Points',
                      '${taskProvider.totalPoints}', Icons.star, isDark),
                  const SizedBox(width: 12),
                  _buildProfileStat(
                      context, 'Tier', tier, TierCalculator.getTierIcon(tier), isDark),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap for detailed stats',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),

            // ─── Activity & Stats ───────────────────────
            _buildSettingsTile(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'Activity & Stats',
              subtitle: 'Charts, tier progress & breakdown',
              isDark: isDark,
              trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ActivityStatsScreen())),
            ),
            const SizedBox(height: 10),
            _buildSettingsTile(
              context,
              icon: Icons.emoji_events_rounded,
              title: 'Leaderboard',
              subtitle: 'See how you rank among friends',
              isDark: isDark,
              trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
            const SizedBox(height: 10),
            _buildSettingsTile(
              context,
              icon: Icons.volunteer_activism_rounded,
              title: 'Charity Tracker',
              subtitle: 'Log and count your daily charities',
              isDark: isDark,
              trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CharityTrackerScreen())),
            ),
            const SizedBox(height: 10),

            // ─── Settings ──────────────────────────────
            _buildSettingsTile(
              context,
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              isDark: isDark,
              trailing: Switch.adaptive(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeTrackColor: AppColors.accent,
              ),
            ),
            const SizedBox(height: 10),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: 'About',
              isDark: isDark,
              trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: 10),

            // ─── Auth action ───────────────────────────
            if (isLoggedIn)
              _buildSettingsTile(
                context,
                icon: Icons.logout,
                title: 'Sign Out',
                isDark: isDark,
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Signed out successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              )
            else
              _buildSettingsTile(
                context,
                icon: Icons.login,
                title: 'Sign In / Register',
                isDark: isDark,
                subtitle: 'Sync data & connect with friends',
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? null
              : Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isDark
              ? null
              : Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Better Muslim'),
        content: const Text(
          'An Islamic habit tracker to help you maintain daily prayers, '
          'Tasbih, and spiritual growth.\n\n'
          'Version 1.0.0\n\n'
          'Track your Sawab, compete with friends, and become a better Muslim!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
