import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_storage_service.dart';
import 'firestore_service.dart';
import '../utils/date_helpers.dart';
import '../utils/tier_calculator.dart';

/// Background sync service that pushes dirty local data (Hive) to Firestore.
///
/// Design:
/// - All writes go to Hive first (instant), this service syncs to cloud later.
/// - Uses dirty-flag tracking to know what needs syncing.
/// - Listens to connectivity changes and triggers sync when device comes online.
/// - Uses a lock (_isSyncing) to prevent overlapping syncs.
class SyncService {
  final FirestoreService _firestoreService = FirestoreService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  String? _userId;

  /// Start listening for connectivity changes.
  void startListening() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _userId != null) {
        debugPrint('[SyncService] Connectivity restored — triggering sync');
        syncAll(_userId!);
      }
    });
  }

  /// Stop listening for connectivity changes.
  void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Set the current user ID. Call after login.
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Check if the device currently has an internet connection.
  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ═══════════════════════════════════════════════════════
  // ─── Master Sync ──────────────────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Sync all dirty local data to Firestore.
  /// Skips if already syncing or offline or no user.
  Future<void> syncAll(String userId) async {
    if (_isSyncing) {
      debugPrint('[SyncService] Sync already in progress, skipping');
      return;
    }

    if (!await _isOnline()) {
      debugPrint('[SyncService] Offline, skipping sync');
      return;
    }

    _isSyncing = true;
    debugPrint('[SyncService] Starting full sync for user: $userId');

    try {
      final dirtyKeys = LocalStorageService.getDirtyKeys();
      if (dirtyKeys.isEmpty) {
        debugPrint('[SyncService] Nothing to sync, all clean');
        _isSyncing = false;
        return;
      }

      debugPrint('[SyncService] Dirty keys: $dirtyKeys');

      // Sync tasks
      if (dirtyKeys.contains('tasks')) {
        await _syncTasks(userId);
      }

      // Sync entries (daily task completions)
      final entryKeys = dirtyKeys
          .where((k) => k.startsWith('entries_'))
          .map((k) => k.replaceFirst('entries_', ''))
          .toList();
      for (final dateKey in entryKeys) {
        await _syncEntries(userId, dateKey);
      }

      // Sync charity entries
      if (dirtyKeys.contains('charity')) {
        await _syncCharityEntries(userId);
      }

      // Sync achievements
      if (dirtyKeys.contains('achievements')) {
        await _syncAchievements(userId);
      }

      // Sync points
      if (dirtyKeys.contains('points')) {
        await _syncPoints(userId);
      }

      // Sync durudh counts
      final durudhKeys = dirtyKeys
          .where((k) => k.startsWith('durudh_'))
          .toList();
      for (final key in durudhKeys) {
        final dateKey = key.replaceFirst('durudh_', '');
        await _syncDurudhCount(userId, dateKey);
      }

      // Sync fasting data
      final fastingKeys = dirtyKeys
          .where((k) => k.startsWith('fasting_'))
          .toList();
      for (final key in fastingKeys) {
        final dateKey = key.replaceFirst('fasting_', '');
        await _syncFasting(userId, dateKey);
      }

      LocalStorageService.setLastSyncTime(DateTime.now());
      debugPrint('[SyncService] Full sync complete');
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // ─── Individual Sync Methods ──────────────────────────
  // ═══════════════════════════════════════════════════════

  Future<void> _syncTasks(String userId) async {
    try {
      final localTasks = LocalStorageService.getTasks();
      await _firestoreService.saveTasks(userId, localTasks);
      LocalStorageService.clearDirty('tasks');
      debugPrint('[SyncService] Tasks synced (${localTasks.length} tasks)');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync tasks: $e');
    }
  }

  Future<void> _syncEntries(String userId, String dateKey) async {
    try {
      final localEntries = LocalStorageService.getEntries(dateKey);
      await _firestoreService.saveEntries(userId, dateKey, localEntries);
      LocalStorageService.clearDirty('entries_$dateKey');
      debugPrint('[SyncService] Entries synced for $dateKey');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync entries for $dateKey: $e');
    }
  }

  Future<void> _syncCharityEntries(String userId) async {
    try {
      final localEntries = LocalStorageService.getCharityEntries();
      await _firestoreService.saveCharityEntries(userId, localEntries);
      LocalStorageService.clearDirty('charity');
      debugPrint(
          '[SyncService] Charity entries synced (${localEntries.length})');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync charity entries: $e');
    }
  }

  Future<void> _syncAchievements(String userId) async {
    try {
      final localAchievements = LocalStorageService.getUserAchievements();
      await _firestoreService.saveUserAchievements(userId, localAchievements);
      LocalStorageService.clearDirty('achievements');
      debugPrint(
          '[SyncService] Achievements synced (${localAchievements.length})');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync achievements: $e');
    }
  }

  Future<void> _syncPoints(String userId) async {
    try {
      final localPoints = LocalStorageService.getTotalPoints();
      final tier = TierCalculator.getTier(localPoints);
      await _firestoreService.updateUserPoints(userId, localPoints, tier);
      LocalStorageService.clearDirty('points');
      debugPrint('[SyncService] Points synced ($localPoints, tier: $tier)');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync points: $e');
    }
  }

  Future<void> _syncDurudhCount(String userId, String dateKey) async {
    try {
      final count = LocalStorageService.getDurudhCount(dateKey);
      await _firestoreService.saveDurudhCount(userId, dateKey, count);
      LocalStorageService.clearDirty('durudh_$dateKey');
      debugPrint('[SyncService] Durudh synced for $dateKey ($count)');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync durudh for $dateKey: $e');
    }
  }

  Future<void> _syncFasting(String userId, String dateKey) async {
    try {
      final isFasting = LocalStorageService.isFasting(dateKey);
      await _firestoreService.saveFasting(userId, dateKey, isFasting);
      LocalStorageService.clearDirty('fasting_$dateKey');
      debugPrint('[SyncService] Fasting synced for $dateKey ($isFasting)');
    } catch (e) {
      debugPrint('[SyncService] Failed to sync fasting for $dateKey: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // ─── Pull from Cloud (on login) ───────────────────────
  // ═══════════════════════════════════════════════════════

  /// Pull all data from Firestore and merge with local.
  /// Called once when user logs in — cloud data takes priority
  /// only if local has never been synced before.
  Future<void> pullFromCloud(String userId) async {
    if (!await _isOnline()) {
      debugPrint('[SyncService] Offline, skipping cloud pull');
      return;
    }

    try {
      debugPrint('[SyncService] Pulling data from cloud for user: $userId');

      // Pull tasks — only if local is empty (first login)
      final localTasks = LocalStorageService.getTasks();
      if (localTasks.isEmpty) {
        final cloudTasks = await _firestoreService.getTasks(userId);
        if (cloudTasks.isNotEmpty) {
          await LocalStorageService.saveTasks(cloudTasks);
          // Clear the dirty flag since this data came from cloud
          LocalStorageService.clearDirty('tasks');
          debugPrint(
              '[SyncService] Pulled ${cloudTasks.length} tasks from cloud');
        }
      }

      // Pull today's entries
      final todayKey = DateHelpers.dateKey(DateTime.now());
      final localEntries = LocalStorageService.getEntries(todayKey);
      if (localEntries.isEmpty) {
        final cloudEntries =
            await _firestoreService.getEntries(userId, todayKey);
        if (cloudEntries.isNotEmpty) {
          await LocalStorageService.saveEntries(todayKey, cloudEntries);
          LocalStorageService.clearDirty('entries_$todayKey');
          debugPrint(
              '[SyncService] Pulled ${cloudEntries.length} entries from cloud');
        }
      }

      // Pull charity entries
      final localCharity = LocalStorageService.getCharityEntries();
      if (localCharity.isEmpty) {
        final cloudCharity =
            await _firestoreService.getCharityEntries(userId);
        if (cloudCharity.isNotEmpty) {
          await LocalStorageService.saveCharityEntries(cloudCharity);
          LocalStorageService.clearDirty('charity');
          debugPrint(
              '[SyncService] Pulled ${cloudCharity.length} charity entries');
        }
      }

      // Pull achievements
      final localAchievements = LocalStorageService.getUserAchievements();
      if (localAchievements.isEmpty) {
        final cloudAchievements = await _firestoreService.getUserAchievements(userId);
        if (cloudAchievements.isNotEmpty) {
          await LocalStorageService.saveUserAchievements(cloudAchievements);
          LocalStorageService.clearDirty('achievements');
          debugPrint(
              '[SyncService] Pulled ${cloudAchievements.length} achievements');
        }
      }

      // Pull user points and durudh/fasting data
      final userModel = await _firestoreService.getUser(userId);
      if (userModel != null) {
        await LocalStorageService.setTotalPoints(userModel.totalPoints);
        LocalStorageService.clearDirty('points');
        debugPrint('[SyncService] Pulled total points: ${userModel.totalPoints}');
      }

      // Pull today's durudh and fasting
      final todayDurudh = await _firestoreService.getDurudhCount(userId, todayKey);
      if (todayDurudh > 0) {
        await LocalStorageService.setDurudhCount(todayKey, todayDurudh);
        LocalStorageService.clearDirty('durudh_$todayKey');
      }

      final todayFasting = await _firestoreService.getFasting(userId, todayKey);
      if (todayFasting) {
        await LocalStorageService.setFasting(todayKey, todayFasting);
        LocalStorageService.clearDirty('fasting_$todayKey');
      }

      debugPrint('[SyncService] Cloud pull complete');
    } catch (e) {
      debugPrint('[SyncService] Cloud pull error: $e');
    }
  }
}
