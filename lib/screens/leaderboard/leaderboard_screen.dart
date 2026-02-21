import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/tier_calculator.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh leaderboard from cloud on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFreshLeaderboard();
    });
  }

  void _fetchFreshLeaderboard() {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final friendsProvider = context.read<FriendsProvider>();

    friendsProvider.fetchLeaderboard(
      authProvider.firebaseUser?.uid,
      taskProvider.totalPoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final friendsProvider = context.watch<FriendsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final entries = friendsProvider.cachedLeaderboard.isNotEmpty
        ? friendsProvider.cachedLeaderboard
        : friendsProvider.getLeaderboard(taskProvider.totalPoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          // Refresh button to manually fetch fresh data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFreshLeaderboard,
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (friendsProvider.isLeaderboardStale)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: AppColors.secondary.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Offline: Showing cached leaderboard',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (friendsProvider.isLeaderboardLoading)
            const LinearProgressIndicator(),

          // Leaderboard content
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Add friends to see the leaderboard!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ─── Top 3 Podium ───────────────────────
                        if (entries.length >= 3)
                          _buildPodium(context, entries, isDark),
                        const SizedBox(height: 24),

                        // ─── Full list ──────────────────────────
                        ...entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildLeaderboardTile(
                                  context, entry, isDark),
                            )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List entries, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (entries.length > 1) _buildPodiumItem(context, entries[1], 2, isDark),
        const SizedBox(width: 8),
        // 1st place
        _buildPodiumItem(context, entries[0], 1, isDark),
        const SizedBox(width: 8),
        // 3rd place
        if (entries.length > 2) _buildPodiumItem(context, entries[2], 3, isDark),
      ],
    );
  }

  Widget _buildPodiumItem(
      BuildContext context, dynamic entry, int position, bool isDark) {
    final tierColor = TierCalculator.getTierColor(entry.tier);
    final heights = {1: 140.0, 2: 110.0, 3: 90.0};
    final sizes = {1: 56.0, 2: 44.0, 3: 40.0};
    final crowns = {1: '👑', 2: '🥈', 3: '🥉'};

    return Column(
      children: [
        Text(crowns[position]!, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: (sizes[position]! / 2),
          backgroundColor: tierColor.withValues(alpha: 0.2),
          child: Text(
            entry.name[0].toUpperCase(),
            style: TextStyle(
              color: tierColor,
              fontWeight: FontWeight.w700,
              fontSize: sizes[position]! * 0.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.points} pts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: heights[position],
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tierColor.withValues(alpha: 0.3),
                tierColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(
      BuildContext context, dynamic entry, bool isDark) {
    final tierColor = TierCalculator.getTierColor(entry.tier);
    final isYou = entry.userId == 'local' || entry.name == 'You';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isYou
            ? AppColors.accent.withValues(alpha: 0.1)
            : isDark
                ? AppColors.darkCard
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isYou
              ? AppColors.accent.withValues(alpha: 0.3)
              : isDark
                  ? Colors.white10
                  : AppColors.secondary.withValues(alpha: 0.3),
          width: isYou ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: entry.rank <= 3 ? AppColors.accent : AppColors.muted,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: tierColor.withValues(alpha: 0.15),
            child: Text(
              entry.name[0].toUpperCase(),
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isYou ? 'You' : entry.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(TierCalculator.getTierIcon(entry.tier),
                        color: tierColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      entry.tier,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${entry.points}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
          ),
        ],
      ),
    );
  }
}
