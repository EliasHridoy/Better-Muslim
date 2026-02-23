import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/theme.dart';
import '../../providers/friends_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/tier_calculator.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  // 0 for Received, 1 for Sent
  int _selectedRequestTab = 0;

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
            // ─── Requests Section ──────────────────────
            if (provider.pendingRequests.isNotEmpty || provider.sentRequests.isNotEmpty) ...[
              Text('Requests', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              // Segmented Control
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRequestTab = 0),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedRequestTab == 0
                                ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedRequestTab == 0 && !isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Received (${provider.pendingRequests.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedRequestTab == 0 ? FontWeight.w600 : FontWeight.w400,
                              color: _selectedRequestTab == 0
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRequestTab = 1),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedRequestTab == 1
                                ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedRequestTab == 1 && !isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Sent (${provider.sentRequests.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedRequestTab == 1 ? FontWeight.w600 : FontWeight.w400,
                              color: _selectedRequestTab == 1
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedRequestTab == 0 && provider.pendingRequests.isNotEmpty)
                ...provider.pendingRequests.map((request) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestTile(context, request, provider, isDark, isSent: false),
                    )),
              if (_selectedRequestTab == 1 && provider.sentRequests.isNotEmpty)
                ...provider.sentRequests.map((request) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestTile(context, request, provider, isDark, isSent: true),
                    )),

              const SizedBox(height: 24),
            ],

            // ─── Friends list ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Friends',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
    bool isDark, {
    required bool isSent,
  }) {
    final displayName = isSent ? request.toUserName : request.fromUserName;

    // Formatting a simple time string (mocking exact time for now or using request.createdAt if available)
    String timeAgo = '';
    if (request.createdAt != null) {
      final diff = DateTime.now().difference(request.createdAt);
      if (diff.inDays > 1) {
        timeAgo = '${diff.inDays} days ago';
      } else if (diff.inDays == 1) {
        timeAgo = 'yesterday';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      } else {
        timeAgo = 'just now';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3E4148) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            backgroundImage: const AssetImage('assets/images/default_avatar.png'), // Fallback generic
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
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
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSent ? 'Request sent $timeAgo' : 'Received $timeAgo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isSent)
            InkWell(
              onTap: () => provider.cancelSentRequest(request.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.close,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            InkWell(
              onTap: () => provider.rejectRequest(request.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => provider.acceptRequest(request.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, dynamic friend, bool isDark) {
    final tierColor = TierCalculator.getTierColor(friend.tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3E4148) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10), // slightly rounded rectangle like design
                ),
                alignment: Alignment.center,
                child: Text(
                  friend.name[0].toUpperCase(),
                  style: TextStyle(
                    color: tierColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green, // Online indicator
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF3E4148) : Colors.grey.shade100, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  friend.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, color: tierColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${friend.tier.toUpperCase()} TIER',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tierColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${friend.totalPoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Text(
                'SAWAB',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '— OR —',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showMyQrCode(context);
                    },
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('My QR', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _scanQrCode(context);
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan QR', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
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
                          : 'User not found or already friends. Check the email.'),
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

  void _showMyQrCode(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait until you are fully logged in.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My QR Code', textAlign: TextAlign.center),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: 'better_muslim_friend:$userId',
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scanQrCode(BuildContext context) {
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        title: const Text('Scan QR Code', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(
              onDetect: (capture) async {
                if (isProcessing) return;

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null && raw.startsWith('better_muslim_friend:')) {
                    isProcessing = true;
                    final targetId = raw.substring('better_muslim_friend:'.length);

                    if (ctx.mounted) Navigator.pop(ctx);

                    if (context.mounted) {
                      final authProvider = context.read<AuthProvider>();
                      final sent = await context.read<FriendsProvider>().sendRequestById(
                        fromUserId: authProvider.firebaseUser?.uid ?? 'local',
                        fromUserName: authProvider.displayName,
                        toUserId: targetId,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(sent ? 'Friend request sent!' : 'Could not send request.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                    return;
                  }
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
