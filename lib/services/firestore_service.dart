import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/task_entry_model.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../models/charity_entry_model.dart';
import '../models/achievement_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User ──────────────────────────────────────────────

  Future<void> createUser(String uid, UserModel user) async {
    await _db.collection('users').doc(uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUserPoints(String uid, int totalPoints, String tier) async {
    await _db.collection('users').doc(uid).set({
      'totalPoints': totalPoints,
      'tier': tier,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> updateUserPreferences(String uid, Map<String, dynamic> prefs) async {
    await _db.collection('users').doc(uid).set(prefs, SetOptions(merge: true));
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromMap(query.docs.first.data());
  }

  // ─── Tasks ─────────────────────────────────────────────

  Future<void> saveTasks(String uid, List<TaskModel> tasks) async {
    final batch = _db.batch();
    final col = _db.collection('users').doc(uid).collection('tasks');

    for (final task in tasks) {
      batch.set(col.doc(task.id), task.toMap());
    }
    await batch.commit();
  }

  Future<List<TaskModel>> getTasks(String uid) async {
    final snap =
        await _db.collection('users').doc(uid).collection('tasks').get();
    return snap.docs.map((d) => TaskModel.fromMap(d.data())).toList();
  }

  // ─── Entries ───────────────────────────────────────────

  Future<void> saveEntries(
      String uid, String dateKey, List<TaskEntry> entries) async {
    final data = entries.map((e) => e.toMap()).toList();
    await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(dateKey)
        .set({'items': data});
  }

  Future<List<TaskEntry>> getEntries(String uid, String dateKey) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(dateKey)
        .get();

    if (!doc.exists || doc.data() == null) return [];
    final items = doc.data()!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => TaskEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── Charity Entries ───────────────────────────────────

  Future<void> saveCharityEntries(
      String uid, List<CharityEntry> entries) async {
    final data = entries.map((e) => e.toMap()).toList();
    await _db
        .collection('users')
        .doc(uid)
        .collection('charityEntries')
        .doc('all')
        .set({'items': data});
  }

  Future<List<CharityEntry>> getCharityEntries(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('charityEntries')
        .doc('all')
        .get();

    if (!doc.exists || doc.data() == null) return [];
    final items = doc.data()!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CharityEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── Durudh Counts ─────────────────────────────────────

  Future<void> saveDurudhCount(
      String uid, String dateKey, int count) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('durudh')
        .doc(dateKey)
        .set({'count': count});
  }

  Future<int> getDurudhCount(String uid, String dateKey) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('durudh')
        .doc(dateKey)
        .get();

    if (!doc.exists || doc.data() == null) return 0;
    return doc.data()!['count'] ?? 0;
  }

  // ─── Fasting (Siam) ───────────────────────────────────

  Future<void> saveFasting(
      String uid, String dateKey, bool isFasting) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('fasting')
        .doc(dateKey)
        .set({'isFasting': isFasting});
  }

  Future<bool> getFasting(String uid, String dateKey) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('fasting')
        .doc(dateKey)
        .get();

    if (!doc.exists || doc.data() == null) return false;
    return doc.data()!['isFasting'] ?? false;
  }

  // ─── Achievements ───────────────────────────────────────

  Future<void> saveUserAchievements(
      String uid, List<UserAchievement> achievements) async {
    final data = achievements.map((a) => a.toMap()).toList();
    await _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc('all')
        .set({'items': data});
  }

  Future<List<UserAchievement>> getUserAchievements(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc('all')
        .get();

    if (!doc.exists || doc.data() == null) return [];
    final items = doc.data()!['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => UserAchievement.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── Friend Requests ──────────────────────────────────

  Future<void> sendFriendRequest(FriendRequest request) async {
    await _db.collection('friendRequests').doc(request.id).set(request.toMap());
  }

  Stream<List<FriendRequest>> getPendingRequests(String userId) {
    return _db
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromMap(d.data())).toList());
  }

  Stream<List<FriendRequest>> getSentRequests(String userId) {
    return _db
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromMap(d.data())).toList());
  }

  Future<void> updateRequestStatus(
      String requestId, FriendRequestStatus status) async {
    await _db
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': status.name});
  }

  Future<void> deleteFriendRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).delete();
  }

  // ─── Friends ───────────────────────────────────────────

  Future<void> addFriend(String uid, String friendUid) async {
    // Add to both users' friend lists
    await _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(friendUid)
        .set({'addedAt': FieldValue.serverTimestamp()});

    await _db
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(uid)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  Future<List<UserModel>> getFriends(String uid) async {
    final friendSnap =
        await _db.collection('users').doc(uid).collection('friends').get();

    final friends = <UserModel>[];
    for (final doc in friendSnap.docs) {
      final user = await getUser(doc.id);
      if (user != null) friends.add(user);
    }
    return friends;
  }

  // ─── Leaderboard (Cloud-First) ─────────────────────────

  /// Fetch all friends + self to build a fresh leaderboard.
  Future<List<UserModel>> getLeaderboardUsers(String uid) async {
    final friends = await getFriends(uid);
    final self = await getUser(uid);
    if (self != null) {
      friends.add(self);
    }
    return friends;
  }
}
