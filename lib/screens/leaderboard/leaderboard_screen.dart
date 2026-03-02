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

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Inspiring empty messages per league
  static const Map<String, String> _emptyMessages = {
    'Bronze': 'Every journey begins with a single step.\nBe the first to shine in the Bronze league!',
    'Silver': 'The Silver league awaits its first champion.\nKeep earning Sawab to lead the way!',
    'Gold': 'No one has reached the Gold league yet.\nWill you be the trailblazer?',
    'Platinum': 'The Platinum league is waiting for a legend.\nStrive for greatness and claim your throne!',
  };

  static const Map<String, IconData> _emptyIcons = {
    'Bronze': Icons.military_tech,
    'Silver': Icons.workspace_premium,
    'Gold': Icons.star,
    'Platinum': Icons.diamond,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FriendsProvider.allLeagues.length,
      vsync: this,
    );

    // Set initial tab to the user's current league
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      final myTier = TierCalculator.getTier(taskProvider.totalPoints);
      final idx = FriendsProvider.allLeagues.indexOf(myTier);
      if (idx >= 0) {
        _tabController.animateTo(idx);
      }
      _fetchAllLeagues();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchAllLeagues() {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final friendsProvider = context.read<FriendsProvider>();

    friendsProvider.fetchAllLeagues(
      authProvider.firebaseUser?.uid,
      taskProvider.totalPoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myTier = TierCalculator.getTier(taskProvider.totalPoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllLeagues,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.muted,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: FriendsProvider.allLeagues.map((league) {
              final tierColor = TierCalculator.getTierColor(league);
              final isMyLeague = league == myTier;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TierCalculator.getTierIcon(league),
                      size: 14,
                      color: isMyLeague ? tierColor : null,
                    ),
                    const SizedBox(width: 4),
                    Text(league),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Loading indicator
          if (friendsProvider.isLeagueLoading)
            const LinearProgressIndicator(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: FriendsProvider.allLeagues.map((league) {
                final entries = friendsProvider.getLeagueEntries(league);
                if (entries.isEmpty && !friendsProvider.isLeagueLoading) {
                  return _buildEmptyLeague(context, league, isDark);
                }
                return _buildLeagueList(context, league, entries, isDark);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeague(BuildContext context, String league, bool isDark) {
    final tierColor = TierCalculator.getTierColor(league);
    final message = _emptyMessages[league] ?? 'Be the first to join this league!';
    final icon = _emptyIcons[league] ?? Icons.emoji_events;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: tierColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$league League',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tierColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: tierColor),
                  const SizedBox(width: 6),
                  Text(
                    _getPointsRange(league),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPointsRange(String league) {
    switch (league) {
      case 'Bronze':
        return '0 – 99 Sawab';
      case 'Silver':
        return '100 – 499 Sawab';
      case 'Gold':
        return '500 – 1,999 Sawab';
      case 'Platinum':
        return '2,000+ Sawab';
      default:
        return '';
    }
  }

  Widget _buildLeagueList(
    BuildContext context,
    String league,
    List entries,
    bool isDark,
  ) {
    final tierColor = TierCalculator.getTierColor(league);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(TierCalculator.getTierIcon(league),
                    color: tierColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$league League',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entries.length} ${entries.length == 1 ? 'member' : 'members'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tierColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Top 3 podium (if at least 3 entries)
          if (entries.length >= 3) ...[
            _buildPodium(context, entries, isDark, tierColor),
            const SizedBox(height: 16),
          ],

          // Full list
          ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildLeaderboardTile(context, entry, isDark),
              )),
        ],
      ),
    );
  }

  Widget _buildPodium(
      BuildContext context, List entries, bool isDark, Color tierColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (entries.length > 1)
          _buildPodiumItem(context, entries[1], 2, isDark, tierColor),
        const SizedBox(width: 8),
        _buildPodiumItem(context, entries[0], 1, isDark, tierColor),
        const SizedBox(width: 8),
        if (entries.length > 2)
          _buildPodiumItem(context, entries[2], 3, isDark, tierColor),
      ],
    );
  }

  Widget _buildPodiumItem(BuildContext context, dynamic entry, int position,
      bool isDark, Color tierColor) {
    final heights = {1: 130.0, 2: 100.0, 3: 80.0};
    final sizes = {1: 52.0, 2: 42.0, 3: 38.0};
    final crowns = {1: '👑', 2: '🥈', 3: '🥉'};

    return Column(
      children: [
        Text(crowns[position]!, style: const TextStyle(fontSize: 22)),
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
        SizedBox(
          width: 80,
          child: Text(
            entry.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
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
          width: 76,
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
                    color:
                        entry.rank <= 3 ? AppColors.accent : AppColors.muted,
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
                    Flexible(
                      child: Text(
                        isYou ? 'You' : entry.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
