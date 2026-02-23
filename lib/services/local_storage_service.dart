import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';
import '../models/task_model.dart';
import '../models/task_entry_model.dart';
import '../models/user_model.dart';
import '../models/charity_entry_model.dart';

class LocalStorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.tasksBox);
    await Hive.openBox(AppConstants.entriesBox);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.charityEntriesBox);
    await Hive.openBox(AppConstants.syncBox);
  }

  // ─── User ──────────────────────────────────────────────
  static Box get _userBox => Hive.box(AppConstants.userBox);

  static Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', jsonEncode(user.toMap()));
  }

  static UserModel? getUser() {
    final data = _userBox.get('current_user');
    if (data == null) return null;
    return UserModel.fromMap(jsonDecode(data));
  }

  // ─── Tasks ─────────────────────────────────────────────
  static Box get _tasksBox => Hive.box(AppConstants.tasksBox);

  static Future<void> saveTasks(List<TaskModel> tasks) async {
    final maps = tasks.map((t) => jsonEncode(t.toMap())).toList();
    await _tasksBox.put('tasks', maps);
    markDirty('tasks');
  }

  static List<TaskModel> getTasks() {
    final data = _tasksBox.get('tasks');
    if (data == null) return [];
    return (data as List)
        .map((e) => TaskModel.fromMap(jsonDecode(e)))
        .toList();
  }

  // ─── Entries ───────────────────────────────────────────
  static Box get _entriesBox => Hive.box(AppConstants.entriesBox);

  static Future<void> saveEntries(
      String dateKey, List<TaskEntry> entries) async {
    final maps = entries.map((e) => jsonEncode(e.toMap())).toList();
    await _entriesBox.put(dateKey, maps);
    markDirty('entries_$dateKey');
  }

  static List<TaskEntry> getEntries(String dateKey) {
    final data = _entriesBox.get(dateKey);
    if (data == null) return [];
    return (data as List)
        .map((e) => TaskEntry.fromMap(jsonDecode(e)))
        .toList();
  }

  /// Returns all date keys that have stored entries.
  static List<String> getAllEntryDateKeys() {
    return _entriesBox.keys.cast<String>().toList();
  }

  // ─── Charity Entries ───────────────────────────────────
  static Box get _charityBox => Hive.box(AppConstants.charityEntriesBox);

  static Future<void> saveCharityEntries(List<CharityEntry> entries) async {
    final maps = entries.map((e) => e.toJson()).toList();
    await _charityBox.put('all_charities', maps);
    markDirty('charity');
  }

  static List<CharityEntry> getCharityEntries() {
    final data = _charityBox.get('all_charities');
    if (data == null) return [];
    return (data as List)
        .map((e) => CharityEntry.fromJson(e as String))
        .toList();
  }

  // ─── Settings ──────────────────────────────────────────
  static Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  static Future<void> setDarkMode(bool value) async {
    await _settingsBox.put('dark_mode', value);
  }

  static bool getDarkMode() {
    return _settingsBox.get('dark_mode', defaultValue: false);
  }

  static Future<void> setTotalPoints(int points) async {
    await _settingsBox.put('total_points', points);
    markDirty('points');
  }

  static int getTotalPoints() {
    return _settingsBox.get('total_points', defaultValue: 0);
  }

  // ─── Durudh Counts ──────────────────────────────────────
  static Future<void> setDurudhCount(String dateKey, int count) async {
    await _settingsBox.put('durudh_$dateKey', count);
    markDirty('durudh_$dateKey');
  }

  static int getDurudhCount(String dateKey) {
    return _settingsBox.get('durudh_$dateKey', defaultValue: 0);
  }

  // ─── Fasting (Siam) ─────────────────────────────────────
  static Future<void> setFasting(String dateKey, bool isFasting) async {
    await _settingsBox.put('fasting_$dateKey', isFasting);
    markDirty('fasting_$dateKey');
  }

  static bool isFasting(String dateKey) {
    return _settingsBox.get('fasting_$dateKey', defaultValue: false);
  }

  /// Returns all date keys where fasting was marked.
  static List<String> getAllFastingDateKeys() {
    return _settingsBox.keys
        .cast<String>()
        .where((k) => k.startsWith('fasting_') && _settingsBox.get(k) == true)
        .map((k) => k.replaceFirst('fasting_', ''))
        .toList();
  }

  // ─── Onboarding ────────────────────────────────────────
  static bool isOnboardingComplete() {
    return _settingsBox.get('onboarding_complete', defaultValue: false);
  }

  static Future<void> setOnboardingComplete(bool value) async {
    await _settingsBox.put('onboarding_complete', value);
  }

  // ═══════════════════════════════════════════════════════
  // ─── Sync Tracking (Dirty Flags) ──────────────────────
  // ═══════════════════════════════════════════════════════
  static Box get _syncBox => Hive.box(AppConstants.syncBox);

  /// Mark a data key as needing sync to Firestore.
  static void markDirty(String key) {
    _syncBox.put('dirty_$key', true);
  }

  /// Check if a data key needs syncing.
  static bool isDirty(String key) {
    return _syncBox.get('dirty_$key', defaultValue: false);
  }

  /// Clear the dirty flag after successful sync.
  static void clearDirty(String key) {
    _syncBox.put('dirty_$key', false);
  }

  /// Get all keys that are currently dirty (need syncing).
  static List<String> getDirtyKeys() {
    return _syncBox.keys
        .cast<String>()
        .where((k) => k.startsWith('dirty_') && _syncBox.get(k) == true)
        .map((k) => k.replaceFirst('dirty_', ''))
        .toList();
  }

  /// Store the last successful full sync timestamp.
  static Future<void> setLastSyncTime(DateTime time) async {
    await _syncBox.put('last_sync_time', time.toIso8601String());
  }

  /// Get the last successful full sync timestamp.
  static DateTime? getLastSyncTime() {
    final data = _syncBox.get('last_sync_time');
    if (data == null) return null;
    return DateTime.tryParse(data);
  }
}
