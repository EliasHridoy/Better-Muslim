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
  bool _isUsingMockData = true;

  // ─── Leaderboard cloud-first state ─────────────────────
  List<LeaderboardEntry> _cachedLeaderboard = [];
  bool _isLeaderboardLoading = false;
  bool _isLeaderboardStale = false;

  List<UserModel> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<LeaderboardEntry> get cachedLeaderboard => _cachedLeaderboard;
  bool get isLeaderboardLoading => _isLeaderboardLoading;
  bool get isLeaderboardStale => _isLeaderboardStale;

  FriendsProvider() {
    _loadMockData();
  }

  // ─── Initialize with real user (call after auth) ──────
  Future<void> initWithUser(String userId) async {
    try {
      _friends = await _firestoreService.getFriends(userId);
      _isUsingMockData = false;

      // Listen to pending requests
      _firestoreService.getPendingRequests(userId).listen((requests) {
        _pendingRequests = requests;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      // Fall back to mock data if Firestore not available
      debugPrint('Firestore friends error: $e');
    }
  }

  void _loadMockData() {
    _friends.addAll([
      UserModel(
        id: 'f1',
        name: 'Ahmad Hassan',
        email: 'ahmad@mail.com',
        totalPoints: 245,
        tier: 'Silver',
      ),
      UserModel(
        id: 'f2',
        name: 'Fatima Ali',
        email: 'fatima@mail.com',
        totalPoints: 523,
        tier: 'Gold',
      ),
      UserModel(
        id: 'f3',
        name: 'Omar Khan',
        email: 'omar@mail.com',
        totalPoints: 89,
        tier: 'Bronze',
      ),
      UserModel(
        id: 'f4',
        name: 'Aisha Rahman',
        email: 'aisha@mail.com',
        totalPoints: 2150,
        tier: 'Platinum',
      ),
      UserModel(
        id: 'f5',
        name: 'Yusuf Aziz',
        email: 'yusuf@mail.com',
        totalPoints: 178,
        tier: 'Silver',
      ),
    ]);

    _pendingRequests.addAll([
      FriendRequest(
        id: 'r1',
        fromUserId: 'u10',
        fromUserName: 'Bilal Ahmed',
        toUserId: 'local',
        toUserName: 'You',
      ),
      FriendRequest(
        id: 'r2',
        fromUserId: 'u11',
        fromUserName: 'Maryam Noor',
        toUserId: 'local',
        toUserName: 'You',
      ),
    ]);
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

  String _getTier(int points) {
    if (points >= 2000) return 'Platinum';
    if (points >= 500) return 'Gold';
    if (points >= 100) return 'Silver';
    return 'Bronze';
  }
}
