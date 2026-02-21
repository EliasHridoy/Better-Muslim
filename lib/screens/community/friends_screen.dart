import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/friends_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/tier_calculator.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Pending requests ──────────────────────
            if (provider.pendingRequests.isNotEmpty) ...[
              Text('Friend Requests', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...provider.pendingRequests.map((request) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildRequestTile(context, request, provider, isDark),
                  )),
              const SizedBox(height: 20),
            ],

            // ─── Friends list ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Friends (${provider.friends.length})',
                    style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.friends.isEmpty)
              _buildEmptyState(context, isDark)
            else
              ...provider.friends.map((friend) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildFriendTile(context, friend, isDark),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    dynamic request,
    FriendsProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: Text(
              request.fromUserName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUserName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Wants to connect',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => provider.rejectRequest(request.id),
            icon: const Icon(Icons.close, color: AppColors.muted, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : AppColors.lightBackground,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => provider.acceptRequest(request.id),
            icon: const Icon(Icons.check, color: Colors.black, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, dynamic friend, bool isDark) {
    final tierColor = TierCalculator.getTierColor(friend.tier);

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
          CircleAvatar(
            radius: 22,
            backgroundColor: tierColor.withValues(alpha: 0.15),
            child: Text(
              friend.name[0].toUpperCase(),
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(TierCalculator.getTierIcon(friend.tier),
                        color: tierColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${friend.tier} • ${friend.totalPoints} pts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${friend.totalPoints}',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: AppColors.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No friends yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect with friends to compete on the leaderboard!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter email address',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final authProvider = context.read<AuthProvider>();
                final sent = await context
                    .read<FriendsProvider>()
                    .sendRequest(
                      fromUserId: authProvider.firebaseUser?.uid ?? 'local',
                      fromUserName: authProvider.displayName,
                      toEmail: controller.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sent
                          ? 'Friend request sent!'
                          : 'User not found. Check the email.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
