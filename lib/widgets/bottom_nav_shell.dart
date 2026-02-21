import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/stats/activity_stats_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/community/friends_screen.dart';
import '../screens/profile/profile_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex = 0;
  bool _synced = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ActivityStatsScreen(),
    LeaderboardScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'HOME'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'STATS'),
    _NavItem(icon: Icons.military_tech, label: 'LEADER'),
    _NavItem(icon: Icons.people_rounded, label: 'COMMUNITY'),
    _NavItem(icon: Icons.account_circle, label: 'ME'),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for auth changes and sync providers after build completes
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isLoggedIn && !_synced) {
      _synced = true;
      final uid = authProvider.firebaseUser!.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TaskProvider>().connectUser(uid);
        context.read<FriendsProvider>().initWithUser(uid);
        context.read<ThemeProvider>().connectUser(uid);
      });
    } else if (!authProvider.isLoggedIn && _synced) {
      _synced = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TaskProvider>().disconnectUser();
        context.read<ThemeProvider>().disconnectUser();
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final isSelected = index == _currentIndex;
                final item = _navItems[index];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected ? AppColors.accent : AppColors.muted,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? AppColors.accent : AppColors.muted,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
