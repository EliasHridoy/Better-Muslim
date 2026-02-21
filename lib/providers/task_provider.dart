import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/task_model.dart';
import '../models/task_entry_model.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../models/charity_entry_model.dart';
import '../utils/date_helpers.dart';

class TaskProvider with ChangeNotifier {
  List<TaskModel> _tasks = [];
  final Map<String, List<TaskEntry>> _entriesByDate = {};
  List<CharityEntry> _charityEntries = [];
  bool _isLoading = true;
  String? _userId;
  int _totalPoints = 0;
  int _streak = 0;
  final SyncService _syncService = SyncService();

  // ─── Getters ───────────────────────────────────────────
  bool get isLoading => _isLoading;
  List<TaskModel> get tasks => _tasks;
  int get totalPoints => _totalPoints;
  List<CharityEntry> get allCharityEntries => List.unmodifiable(_charityEntries);
  int get streak => _streak;
  SyncService get syncService => _syncService;

  static const _prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  List<TaskModel> get prayerTasks {
    final prayers =
        _tasks.where((t) => t.category == TaskCategory.prayer).toList();
    prayers.sort((a, b) {
      final ai = _prayerOrder.indexOf(a.title);
      final bi = _prayerOrder.indexOf(b.title);
      // Known prayers sorted by canonical order, custom prayers go to the end
      return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
    });
    return prayers;
  }

  List<TaskModel> get tasbihTasks =>
      _tasks.where((t) => t.category == TaskCategory.tasbih).toList();

  List<TaskModel> get charityTasks =>
      _tasks.where((t) => t.category == TaskCategory.charity).toList();

  /// Total tasbih count across all tasbih tasks today.
  int get totalTasbihCountToday {
    return tasbihTasks.fold<int>(0, (sum, t) => sum + getTasbihCountToday(t.id));
  }

  TaskProvider() {
    _loadLocalData();
    _syncService.startListening();
  }

  @override
  void dispose() {
    _syncService.stopListening();
    super.dispose();
  }

  // ─── Connect to a logged-in user ──────────────────────
  /// On login: pull cloud data if needed, then push local dirty data.
  Future<void> connectUser(String userId) async {
    _userId = userId;
    _syncService.setUserId(userId);

    try {
      // Pull cloud data for first-time login (merges if local is empty)
      await _syncService.pullFromCloud(userId);

      // Reload local data after pull (may have been updated)
      _loadLocalData();

      // Push any dirty local data to cloud
      await _syncService.syncAll(userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting user: $e');
    }
  }

  // ─── Disconnect user — reset to guest state ────────────
  void disconnectUser() {
    _userId = null;
    _syncService.setUserId(null);
    _totalPoints = 0;
    _streak = 0;
    _entriesByDate.clear();
    _tasks = [];
    _initializeDefaultTasks();
    _loadTodayEntries();
    _calculateStreak();
    notifyListeners();
  }

  void _loadLocalData() {
    _tasks = LocalStorageService.getTasks();
    if (_tasks.isEmpty) {
      _initializeDefaultTasks();
    }
    _totalPoints = LocalStorageService.getTotalPoints();
    _charityEntries = LocalStorageService.getCharityEntries();
    _loadTodayEntries();
    _calculateStreak();
    _isLoading = false;
    notifyListeners();
  }

  void _initializeDefaultTasks() {
    const uuid = Uuid();

    for (final prayer in AppConstants.defaultPrayers) {
      _tasks.add(TaskModel(
        id: uuid.v4(),
        title: prayer,
        category: TaskCategory.prayer,
        isDefault: true,
      ));
    }

    for (final tasbih in AppConstants.defaultTasbih) {
      _tasks.add(TaskModel(
        id: uuid.v4(),
        title: tasbih,
        category: TaskCategory.tasbih,
        isDefault: true,
        targetCount: 33,
      ));
    }

    LocalStorageService.saveTasks(_tasks);
  }

  void _loadTodayEntries() {
    final key = DateHelpers.dateKey(DateTime.now());
    if (!_entriesByDate.containsKey(key)) {
      _entriesByDate[key] = LocalStorageService.getEntries(key);
    }
  }

  List<TaskEntry> getTodayEntries() {
    final key = DateHelpers.dateKey(DateTime.now());
    return _entriesByDate[key] ?? [];
  }

  List<TaskEntry> getEntriesForDate(DateTime date) {
    final key = DateHelpers.dateKey(date);
    if (!_entriesByDate.containsKey(key)) {
      // Always load from local Hive first (instant)
      _entriesByDate[key] = LocalStorageService.getEntries(key);
    }
    return _entriesByDate[key] ?? [];
  }

  bool isTaskCompletedToday(String taskId) {
    final entries = getTodayEntries();
    return entries.any((e) => e.taskId == taskId && e.completed);
  }

  int getTasbihCountToday(String taskId) {
    final entries = getTodayEntries();
    final entry = entries.where((e) => e.taskId == taskId).firstOrNull;
    return entry?.count ?? 0;
  }

  int get todayCompletedCount {
    final taskIds = _tasks.map((t) => t.id).toSet();
    return getTodayEntries()
        .where((e) => e.completed && taskIds.contains(e.taskId))
        .length;
  }

  int get todayTotalTasks => _tasks.length;

  double get todayProgress {
    if (_tasks.isEmpty) return 0;
    final prayerCompleted =
        prayerTasks.where((t) => isTaskCompletedToday(t.id)).length;
    final tasbihCompleted =
        tasbihTasks.where((t) => isTaskCompletedToday(t.id)).length;
    return (prayerCompleted + tasbihCompleted) / _tasks.length;
  }

  // ─── Save locally + trigger background sync ───────────
  void _save(String key, List<TaskEntry> entries) {
    _entriesByDate[key] = entries;
    // Save to Hive instantly (marks dirty automatically)
    LocalStorageService.saveEntries(key, entries);
    LocalStorageService.setTotalPoints(_totalPoints);

    // Trigger background sync (non-blocking)
    _triggerSync();
  }

  /// Trigger a background sync if user is logged in.
  void _triggerSync() {
    if (_userId != null) {
      // Fire-and-forget — runs in background
      _syncService.syncAll(_userId!);
    }
  }

  // ─── Add bonus points (e.g. from duas) ─────────────────
  void addBonusPoints(int points) {
    _totalPoints += points;
    LocalStorageService.setTotalPoints(_totalPoints);
    _triggerSync();
    notifyListeners();
  }

  // ─── Toggle prayer completion ──────────────────────────
  void togglePrayer(String taskId) {
    final key = DateHelpers.dateKey(DateTime.now());
    var entries = List<TaskEntry>.from(getTodayEntries());

    final idx = entries.indexWhere((e) => e.taskId == taskId);
    if (idx >= 0) {
      final wasCompleted = entries[idx].completed;
      entries[idx] = entries[idx].copyWith(completed: !wasCompleted);
      if (wasCompleted) {
        _totalPoints =
            (_totalPoints - AppConstants.pointsPerTask).clamp(0, 999999);
      } else {
        _totalPoints += AppConstants.pointsPerTask;
      }
    } else {
      entries.add(TaskEntry(
        id: const Uuid().v4(),
        taskId: taskId,
        date: DateTime.now(),
        completed: true,
      ));
      _totalPoints += AppConstants.pointsPerTask;
    }

    _save(key, entries);
    _calculateStreak();
    notifyListeners();
  }

  // ─── Toggle charity completion ─────────────────────────
  void toggleCharity(String taskId) {
    final key = DateHelpers.dateKey(DateTime.now());
    var entries = List<TaskEntry>.from(getTodayEntries());

    final idx = entries.indexWhere((e) => e.taskId == taskId);
    if (idx >= 0) {
      final wasCompleted = entries[idx].completed;
      entries[idx] = entries[idx].copyWith(completed: !wasCompleted);
      if (wasCompleted) {
        _totalPoints =
            (_totalPoints - AppConstants.pointsPerTask).clamp(0, 999999);
      } else {
        _totalPoints += AppConstants.pointsPerTask;
      }
    } else {
      entries.add(TaskEntry(
        id: const Uuid().v4(),
        taskId: taskId,
        date: DateTime.now(),
        completed: true,
      ));
      _totalPoints += AppConstants.pointsPerTask;
    }

    _save(key, entries);
    _calculateStreak();
    notifyListeners();
  }

  // ─── Add New Charity Entry (Sadaka Logging) ────────────
  void addCharityEntry(double amount, String? purpose, DateTime date) {
    final entry = CharityEntry(
      id: const Uuid().v4(),
      amount: amount,
      date: date,
      purpose: purpose,
    );

    _charityEntries.add(entry);
    // Sort descending by date
    _charityEntries.sort((a, b) => b.date.compareTo(a.date));

    // Save to Hive (marks dirty automatically)
    LocalStorageService.saveCharityEntries(_charityEntries);

    // Optional: Add some Sawab points for logging charity
    addBonusPoints(10);
    notifyListeners();
  }

  // ─── Remove Charity Entry ──────────────────────────────
  void removeCharityEntry(String id) {
    _charityEntries.removeWhere((e) => e.id == id);
    LocalStorageService.saveCharityEntries(_charityEntries);
    _triggerSync();
    notifyListeners();
  }

  // ─── Remove a user-added task ──────────────────────────
  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    LocalStorageService.saveTasks(_tasks);
    _triggerSync();
    notifyListeners();
  }

  // ─── Increment tasbih count ────────────────────────────
  void incrementTasbih(String taskId) {
    final key = DateHelpers.dateKey(DateTime.now());
    var entries = List<TaskEntry>.from(getTodayEntries());
    final task = _tasks.firstWhere((t) => t.id == taskId);

    final idx = entries.indexWhere((e) => e.taskId == taskId);
    if (idx >= 0) {
      final newCount = entries[idx].count + 1;
      final wasCompleted = entries[idx].completed;
      final nowCompleted = newCount >= task.targetCount;

      entries[idx] = entries[idx].copyWith(
        count: newCount,
        completed: nowCompleted,
      );

      if (!wasCompleted && nowCompleted) {
        _totalPoints += AppConstants.pointsPerTask;
      }
    } else {
      final nowCompleted = 1 >= task.targetCount;
      entries.add(TaskEntry(
        id: const Uuid().v4(),
        taskId: taskId,
        date: DateTime.now(),
        count: 1,
        completed: nowCompleted,
      ));
      if (nowCompleted) {
        _totalPoints += AppConstants.pointsPerTask;
      }
    }

    _save(key, entries);
    notifyListeners();
  }

  // ─── Durudh counting ───────────────────────────────────
  int get durudhCountToday {
    final key = DateHelpers.dateKey(DateTime.now());
    return LocalStorageService.getDurudhCount(key);
  }

  void incrementDurudh() {
    final key = DateHelpers.dateKey(DateTime.now());
    final currentCount = LocalStorageService.getDurudhCount(key);
    // Saves to Hive & marks dirty automatically
    LocalStorageService.setDurudhCount(key, currentCount + 1);

    _totalPoints += 10;
    LocalStorageService.setTotalPoints(_totalPoints);
    _triggerSync();
    notifyListeners();
  }

  // ─── Fasting (Siam) ────────────────────────────────────
  bool get isFastingToday {
    final key = DateHelpers.dateKey(DateTime.now());
    return LocalStorageService.isFasting(key);
  }

  int get totalFastingDays {
    return LocalStorageService.getAllFastingDateKeys().length;
  }

  void toggleFasting() {
    final key = DateHelpers.dateKey(DateTime.now());
    final current = LocalStorageService.isFasting(key);
    LocalStorageService.setFasting(key, !current);
    // No points awarded for fasting
    _triggerSync();
    notifyListeners();
  }

  // ─── Reset tasbih count ────────────────────────────────
  void resetTasbih(String taskId) {
    final key = DateHelpers.dateKey(DateTime.now());
    var entries = List<TaskEntry>.from(getTodayEntries());

    final idx = entries.indexWhere((e) => e.taskId == taskId);
    if (idx >= 0) {
      if (entries[idx].completed) {
        _totalPoints =
            (_totalPoints - AppConstants.pointsPerTask).clamp(0, 999999);
      }
      entries[idx] = entries[idx].copyWith(count: 0, completed: false);
      _save(key, entries);
      notifyListeners();
    }
  }

  // ─── Add custom task ───────────────────────────────────
  void addTask(String title, TaskCategory category, {int targetCount = 33}) {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      category: category,
      isDefault: false,
      targetCount: targetCount,
    );
    _tasks.add(task);
    LocalStorageService.saveTasks(_tasks);
    _triggerSync();
    notifyListeners();
  }

  // ─── Streak calculation ────────────────────────────────
  void _calculateStreak() {
    int streakCount = 0;
    var date = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final key = DateHelpers.dateKey(date);
      final entries = _entriesByDate[key] ?? LocalStorageService.getEntries(key);
      final completedCount = entries.where((e) => e.completed).length;

      if (completedCount > 0) {
        streakCount++;
        date = date.subtract(const Duration(days: 1));
      } else if (i == 0) {
        date = date.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }
    _streak = streakCount;
  }

  // ─── Weekly data for charts ────────────────────────────
  List<int> getWeeklyCompletions({TaskCategory? category}) {
    final taskIds = category != null
        ? _tasks.where((t) => t.category == category).map((t) => t.id).toSet()
        : null;
    final days = DateHelpers.getWeekDays();
    return days.map((day) {
      final entries = getEntriesForDate(day);
      return entries
          .where((e) => e.completed && (taskIds == null || taskIds.contains(e.taskId)))
          .length;
    }).toList();
  }

  // ─── Monthly data for charts (last 30 days) ───────────
  List<int> getMonthlyCompletions({TaskCategory? category}) {
    final taskIds = category != null
        ? _tasks.where((t) => t.category == category).map((t) => t.id).toSet()
        : null;
    final now = DateTime.now();
    return List.generate(30, (i) {
      final day = now.subtract(Duration(days: 29 - i));
      final entries = getEntriesForDate(day);
      return entries
          .where((e) => e.completed && (taskIds == null || taskIds.contains(e.taskId)))
          .length;
    });
  }
}
