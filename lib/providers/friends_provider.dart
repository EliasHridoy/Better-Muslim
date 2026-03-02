import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../models/leaderboard_entry.dart';
import '../services/firestore_service.dart';

class FriendsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _sentRequests = [];
  bool _isUsingMockData = false;

  // ─── Leaderboard cloud-first state ─────────────────────
  List<LeaderboardEntry> _cachedLeaderboard = [];
  bool _isLeaderboardLoading = false;
  bool _isLeaderboardStale = false;

  // ─── League leaderboard state ─────────────────────────
  final Map<String, List<LeaderboardEntry>> _leagueLeaderboards = {};
  bool _isLeagueLoading = false;

  List<UserModel> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<LeaderboardEntry> get cachedLeaderboard => _cachedLeaderboard;
  bool get isLeaderboardLoading => _isLeaderboardLoading;
  bool get isLeaderboardStale => _isLeaderboardStale;
  Map<String, List<LeaderboardEntry>> get leagueLeaderboards => _leagueLeaderboards;
  bool get isLeagueLoading => _isLeagueLoading;

  FriendsProvider();

  void clear() {
    _friends = [];
    _pendingRequests = [];
    _sentRequests = [];
    _cachedLeaderboard = [];
    _isLeaderboardLoading = false;
    _isLeaderboardStale = false;
    _leagueLeaderboards.clear();
    _isLeagueLoading = false;
    notifyListeners();
  }

  // ─── Initialize with real user (call after auth) ──────
  Future<void> initWithUser(String userId) async {
    try {
      _friends = await _firestoreService.getFriends(userId);
      _isUsingMockData = false;

      // Listen to pending requests (received)
      _firestoreService.getPendingRequests(userId).listen((requests) {
        _pendingRequests = requests;
        notifyListeners();
      });

      // Listen to sent requests
      _firestoreService.getSentRequests(userId).listen((requests) {
        _sentRequests = requests;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      // Fall back to mock data if Firestore not available
      debugPrint('Firestore friends error: $e');
    }
  }



  void acceptRequest(String requestId) async {
    final idx = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) {
      final request = _pendingRequests[idx];

      if (!_isUsingMockData) {
        await _firestoreService.updateRequestStatus(
            requestId, FriendRequestStatus.accepted);
        await _firestoreService.addFriend(
            request.toUserId, request.fromUserId);
      }

      _friends.add(UserModel(
        id: request.fromUserId,
        name: request.fromUserName,
        email:
            '${request.fromUserName.toLowerCase().replaceAll(' ', '.')}@mail.com',
        totalPoints: 50,
        tier: 'Bronze',
      ));
      _pendingRequests.removeAt(idx);
      notifyListeners();
    }
  }

  void rejectRequest(String requestId) async {
    if (!_isUsingMockData) {
      await _firestoreService.updateRequestStatus(
          requestId, FriendRequestStatus.rejected);
    }
    _pendingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  Future<bool> sendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toEmail,
  }) async {
    // Look up user by email
    final targetUser = await _firestoreService.findUserByEmail(toEmail);
    if (targetUser == null) return false;

    // Reject if trying to send to self
    if (targetUser.id == fromUserId) return false;

    // Reject if already friends
    if (_friends.any((f) => f.id == targetUser.id)) return false;

    final request = FriendRequest(
      id: const Uuid().v4(),
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: targetUser.id,
      toUserName: targetUser.name,
    );

    await _firestoreService.sendFriendRequest(request);
    notifyListeners();
    return true;
  }

  Future<bool> sendRequestById({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
  }) async {
    // Reject if trying to send to self
    if (toUserId == fromUserId) return false;

    // Reject if already friends
    if (_friends.any((f) => f.id == toUserId)) return false;

    final targetUser = await _firestoreService.getUser(toUserId);
    if (targetUser == null) return false;

    final request = FriendRequest(
      id: const Uuid().v4(),
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: targetUser.id,
      toUserName: targetUser.name,
    );

    await _firestoreService.sendFriendRequest(request);
    notifyListeners();
    return true;
  }

  void cancelSentRequest(String requestId) async {
    if (!_isUsingMockData) {
      await _firestoreService.deleteFriendRequest(requestId);
    }
    _sentRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════
  // ─── Leaderboard (Cloud-First) ─────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Fetch fresh leaderboard from Firestore.
  /// Always tries the network first; falls back to cached data.
  Future<List<LeaderboardEntry>> fetchLeaderboard(
      String? userId, int myPoints) async {
    _isLeaderboardLoading = true;
    _isLeaderboardStale = false;
    notifyListeners();

    try {
      if (userId != null && !_isUsingMockData) {
        // Cloud-first: fetch fresh friend data from Firestore
        final cloudUsers =
            await _firestoreService.getLeaderboardUsers(userId);

        final allEntries = cloudUsers.map((u) => LeaderboardEntry(
              userId: u.id,
              name: u.id == userId ? 'You' : u.name,
              photoUrl: u.photoUrl,
              points: u.id == userId ? myPoints : u.totalPoints,
              tier: u.tier,
              rank: 0,
            )).toList();

        // Ensure "You" is in the list
        if (!allEntries.any((e) => e.userId == userId)) {
          allEntries.add(LeaderboardEntry(
            userId: userId,
            name: 'You',
            points: myPoints,
            tier: _getTier(myPoints),
            rank: 0,
          ));
        }

        allEntries.sort((a, b) => b.points.compareTo(a.points));

        _cachedLeaderboard = List.generate(allEntries.length, (i) {
          final entry = allEntries[i];
          return LeaderboardEntry(
            userId: entry.userId,
            name: entry.name,
            photoUrl: entry.photoUrl,
            points: entry.points,
            tier: entry.tier,
            rank: i + 1,
          );
        });

        _isLeaderboardLoading = false;
        notifyListeners();
        return _cachedLeaderboard;
      }
    } catch (e) {
      debugPrint('Leaderboard fetch error: $e');
      _isLeaderboardStale = true;
    }

    // Fallback: use local mock/cached data
    _isLeaderboardLoading = false;

    if (_cachedLeaderboard.isEmpty) {
      _cachedLeaderboard = getLeaderboard(myPoints);
    }

    notifyListeners();
    return _cachedLeaderboard;
  }

  /// Build leaderboard from local data (used as fallback).
  List<LeaderboardEntry> getLeaderboard(int myPoints) {
    final allUsers = [
      ..._friends.map((f) => LeaderboardEntry(
            userId: f.id,
            name: f.name,
            photoUrl: f.photoUrl,
            points: f.totalPoints,
            tier: f.tier,
            rank: 0,
          )),
      LeaderboardEntry(
        userId: 'local',
        name: 'You',
        points: myPoints,
        tier: _getTier(myPoints),
        rank: 0,
      ),
    ];

    allUsers.sort((a, b) => b.points.compareTo(a.points));

    return List.generate(allUsers.length, (i) {
      final entry = allUsers[i];
      return LeaderboardEntry(
        userId: entry.userId,
        name: entry.name,
        photoUrl: entry.photoUrl,
        points: entry.points,
        tier: entry.tier,
        rank: i + 1,
      );
    });
  }

  // ═══════════════════════════════════════════════════════
  // ─── User Search ─────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Search users by name or email. Returns matched users from Firestore.
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _firestoreService.searchUsers(query);
    } catch (e) {
      debugPrint('User search error: $e');
      return [];
    }
  }

  /// Check if a user is already a friend.
  bool isFriend(String userId) {
    return _friends.any((f) => f.id == userId);
  }

  /// Check if a friend request is already pending (sent) to this user.
  bool hasPendingRequestTo(String userId) {
    return _sentRequests.any((r) => r.toUserId == userId);
  }

  // ═══════════════════════════════════════════════════════
  // ─── League Leaderboards (Global Top 100 per Tier) ────
  // ═══════════════════════════════════════════════════════

  static const List<String> allLeagues = ['Bronze', 'Silver', 'Gold', 'Platinum'];

  /// Fetch top 100 users for all leagues from Firestore.
  Future<void> fetchAllLeagues(String? userId, int myPoints) async {
    _isLeagueLoading = true;
    notifyListeners();

    final myTier = _getTier(myPoints);

    for (final league in allLeagues) {
      try {
        final users = await _firestoreService.getLeagueUsers(league);

        final entries = users.asMap().entries.map((e) {
          final u = e.value;
          final isYou = u.id == userId;
          return LeaderboardEntry(
            userId: u.id,
            name: isYou ? 'You' : u.name,
            photoUrl: u.photoUrl,
            points: isYou ? myPoints : u.totalPoints,
            tier: u.tier,
            rank: e.key + 1,
          );
        }).toList();

        // If user belongs to this league but isn't in the list, add them
        if (league == myTier && userId != null && !entries.any((e) => e.userId == userId)) {
          entries.add(LeaderboardEntry(
            userId: userId,
            name: 'You',
            points: myPoints,
            tier: myTier,
            rank: entries.length + 1,
          ));
        }

        _leagueLeaderboards[league] = entries;
      } catch (e) {
        debugPrint('League fetch error ($league): $e');
        _leagueLeaderboards[league] ??= [];
      }
    }

    _isLeagueLoading = false;
    notifyListeners();
  }

  /// Get cached league entries for a specific tier.
  List<LeaderboardEntry> getLeagueEntries(String tier) {
    return _leagueLeaderboards[tier] ?? [];
  }

  String _getTier(int points) {
    if (points >= 2000) return 'Platinum';
    if (points >= 500) return 'Gold';
    if (points >= 100) return 'Silver';
    return 'Bronze';
  }
}
