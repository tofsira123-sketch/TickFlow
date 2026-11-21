import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

enum SmartFilter { all, today, upcoming, overdue, completed }

extension SmartFilterX on SmartFilter {
  String get label {
    switch (this) {
      case SmartFilter.all:
        return 'All';
      case SmartFilter.today:
        return 'Today';
      case SmartFilter.upcoming:
        return 'Upcoming';
      case SmartFilter.overdue:
        return 'Overdue';
      case SmartFilter.completed:
        return 'Completed';
    }
  }
}

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService.instance;

  List<TaskItem> _tasks = [];
  List<TaskCategory> _categories = TaskCategory.defaults();
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  Map<String, int> _completionHistory = {};

  SmartFilter _activeFilter = SmartFilter.all;
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<TaskCategory> get categories => List.unmodifiable(_categories);
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  SmartFilter get activeFilter => _activeFilter;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    await _notifications.init();
    final initialized = await _storage.isInitialized();
    _categories = await _storage.loadCategories();
    _themeMode = await _storage.loadThemeMode();
    _notificationsEnabled = await _storage.loadNotificationsEnabled();
    _completionHistory = await _storage.loadCompletionHistory();

    if (!initialized) {
      _tasks = _createStarterTasks();
      await _storage.saveCategories(_categories);
      await _storage.saveTasks(_tasks);
      await _storage.markInitialized();
    } else {
      _tasks = await _storage.loadTasks();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<TaskItem> _createStarterTasks() {
    final now = DateTime.now();
    final todayEvening = DateTime(now.year, now.month, now.day, 19, 0);
    final tomorrowMorning =
        DateTime(now.year, now.month, now.day + 1, 9, 30);

    return [
      TaskItem(
        id: 'starter_1',
        title: 'Plan today\'s top 3 priorities',
        notes: 'Tap this card to view sub-tasks, set reminders, or edit details.',
        categoryId: 'work',
        priority: TaskPriority.high,
        dueDate: todayEvening,
        hasReminder: false,
        recurrence: RecurrenceType.daily,
        createdAt: now,
        subTasks: const [
          SubTask(id: 'sub_1', title: 'Review pending tasks', isCompleted: true),
          SubTask(id: 'sub_2', title: 'Focus on highest priority item'),
          SubTask(id: 'sub_3', title: 'Check off completed work'),
        ],
      ),
      TaskItem(
        id: 'starter_2',
        title: 'Read for 20 minutes',
        notes: 'Swipe right on any task card to complete it quickly.',
        categoryId: 'study',
        priority: TaskPriority.medium,
        dueDate: tomorrowMorning,
        hasReminder: false,
        recurrence: RecurrenceType.daily,
        createdAt: now,
      ),
      TaskItem(
        id: 'starter_3',
        title: 'Pick up daily groceries',
        notes: 'Milk, eggs, fruits, and coffee',
        categoryId: 'shopping',
        priority: TaskPriority.low,
        createdAt: now,
      ),
    ];
  }

  String _dateKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  TaskCategory getCategoryById(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => _categories.first,
    );
  }

  void setFilter(SmartFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<TaskItem> get filteredTasks {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final query = _searchQuery.trim().toLowerCase();

    final list = _tasks.where((task) {
      if (_selectedCategoryId != null &&
          task.categoryId != _selectedCategoryId) {
        return false;
      }

      if (query.isNotEmpty) {
        final inTitle = task.title.toLowerCase().contains(query);
        final inNotes = task.notes.toLowerCase().contains(query);
        final inSub = task.subTasks
            .any((s) => s.title.toLowerCase().contains(query));
        if (!inTitle && !inNotes && !inSub) return false;
      }

      switch (_activeFilter) {
        case SmartFilter.all:
          return true;
        case SmartFilter.today:
          return !task.isCompleted && task.isDueToday;
        case SmartFilter.upcoming:
          return !task.isCompleted &&
              task.dueDate != null &&
              task.dueDate!.isAfter(endOfToday);
        case SmartFilter.overdue:
          return task.isOverdue;
        case SmartFilter.completed:
          return task.isCompleted;
      }
    }).toList();

    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.priority.sortWeight != b.priority.sortWeight) {
        return a.priority.sortWeight.compareTo(b.priority.sortWeight);
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return list;
  }

  List<TaskItem> tasksForDate(DateTime date) {
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  int get totalTasksCount => _tasks.length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get overdueTasksCount => _tasks.where((t) => t.isOverdue).length;

  int get todayTotalCount => _tasks.where((t) => t.isDueToday).length;
  int get todayCompletedCount =>
      _tasks.where((t) => t.isDueToday && t.isCompleted).length;

  double get todayProgress {
    if (todayTotalCount == 0) {
      if (totalTasksCount == 0) return 0;
      return completedTasksCount / totalTasksCount;
    }
    return todayCompletedCount / todayTotalCount;
  }

  int get currentStreak {
    var streak = 0;
    var day = DateTime.now();
    // If nothing completed today yet, start checking from yesterday
    if ((_completionHistory[_dateKey(day)] ?? 0) == 0) {
      day = day.subtract(const Duration(days: 1));
    }
    while ((_completionHistory[_dateKey(day)] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<MapEntry<DateTime, int>> get last7DaysStats {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, int>>[];
    for (var i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final count = _completionHistory[_dateKey(date)] ?? 0;
      result.add(MapEntry(date, count));
    }
    return result;
  }

  Future<void> addTask(TaskItem task) async {
    _tasks.insert(0, task);
    await _storage.saveTasks(_tasks);
    if (_notificationsEnabled && task.hasReminder) {
      await _notifications.requestPermissions();
      await _notifications.scheduleTaskReminder(task);
    }
    notifyListeners();
  }

  Future<void> updateTask(TaskItem updated) async {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;
    _tasks[index] = updated;
    await _storage.saveTasks(_tasks);
    if (_notificationsEnabled && updated.hasReminder && !updated.isCompleted) {
      await _notifications.requestPermissions();
      await _notifications.scheduleTaskReminder(updated);
    } else {
      await _notifications.cancelTaskReminder(updated.id);
    }
    notifyListeners();
  }

  Future<TaskItem?> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    final removed = _tasks.removeAt(index);
    await _storage.saveTasks(_tasks);
    await _notifications.cancelTaskReminder(id);
    notifyListeners();
    return removed;
  }

  Future<void> toggleTaskComplete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _tasks[index];
    final now = DateTime.now();
    final nowCompleted = !current.isCompleted;

    _tasks[index] = current.copyWith(
      isCompleted: nowCompleted,
      completedAt: nowCompleted ? now : null,
      clearCompletedAt: !nowCompleted,
    );

    final todayKey = _dateKey(now);
    if (nowCompleted) {
      _completionHistory[todayKey] = (_completionHistory[todayKey] ?? 0) + 1;
      await _notifications.cancelTaskReminder(current.id);

      // Auto-create next occurrence if task is recurring
      if (current.recurrence != RecurrenceType.none) {
        final baseDate = current.dueDate ?? now;
        DateTime nextDate;
        switch (current.recurrence) {
          case RecurrenceType.daily:
            nextDate = baseDate.add(const Duration(days: 1));
            break;
          case RecurrenceType.weekly:
            nextDate = baseDate.add(const Duration(days: 7));
            break;
          case RecurrenceType.monthly:
            nextDate = DateTime(
              baseDate.year,
              baseDate.month + 1,
              baseDate.day,
              baseDate.hour,
              baseDate.minute,
            );
            break;
          case RecurrenceType.none:
            nextDate = baseDate;
            break;
        }

        final nextTask = TaskItem(
          id: 'task_${DateTime.now().microsecondsSinceEpoch}',
          title: current.title,
          notes: current.notes,
          categoryId: current.categoryId,
          priority: current.priority,
          dueDate: nextDate,
          hasReminder: current.hasReminder,
          recurrence: current.recurrence,
          createdAt: now,
          subTasks: current.subTasks
              .map((s) => s.copyWith(isCompleted: false))
              .toList(),
        );
        _tasks.insert(0, nextTask);
        if (_notificationsEnabled && nextTask.hasReminder) {
          await _notifications.scheduleTaskReminder(nextTask);
        }
      }
    } else {
      final prev = _completionHistory[todayKey] ?? 0;
      if (prev > 0) {
        _completionHistory[todayKey] = prev - 1;
      }
      if (_notificationsEnabled && current.hasReminder) {
        await _notifications.scheduleTaskReminder(_tasks[index]);
      }
    }

    await _storage.saveTasks(_tasks);
    await _storage.saveCompletionHistory(_completionHistory);
    notifyListeners();
  }

  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    final updatedSubs = task.subTasks.map((s) {
      if (s.id == subTaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    _tasks[index] = task.copyWith(subTasks: updatedSubs);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> addCategory(String name, int colorValue) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final cat = TaskCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      colorValue: colorValue,
      isDefault: false,
    );
    _categories.add(cat);
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1 || _categories[idx].isDefault) return;

    _categories.removeWhere((c) => c.id == categoryId);
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null;
    }

    // Reassign tasks in deleted category to 'personal'
    _tasks = _tasks
        .map((t) => t.categoryId == categoryId
            ? t.copyWith(categoryId: 'personal')
            : t)
        .toList();

    await _storage.saveCategories(_categories);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _storage.saveNotificationsEnabled(enabled);
    if (enabled) {
      await _notifications.requestPermissions();
      for (final task in _tasks) {
        if (!task.isCompleted && task.hasReminder) {
          await _notifications.scheduleTaskReminder(task);
        }
      }
    } else {
      await _notifications.cancelAll();
    }
    notifyListeners();
  }

  Future<bool> sendTestNotification() {
    return _notifications.showTestNotification();
  }

  String exportBackupJson() {
    return _storage.exportBackupJson(
      tasks: _tasks,
      categories: _categories,
      completionHistory: _completionHistory,
    );
  }

  Future<bool> importBackupJson(String rawJson) async {
    final parsed = _storage.parseBackupJson(rawJson);
    if (parsed == null) return false;

    final rawTasks = parsed['tasks'] as List<dynamic>;
    final loadedTasks = rawTasks
        .whereType<Map<String, dynamic>>()
        .map(TaskItem.fromJson)
        .toList();

    final rawCats = parsed['categories'] as List<dynamic>?;
    final loadedCats = rawCats != null
        ? rawCats
            .whereType<Map<String, dynamic>>()
            .map(TaskCategory.fromJson)
            .toList()
        : TaskCategory.defaults();

    final rawHistory = parsed['completionHistory'] as Map<String, dynamic>?;
    final loadedHistory = rawHistory != null
        ? rawHistory.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0))
        : <String, int>{};

    _tasks = loadedTasks;
    _categories = loadedCats.isEmpty ? TaskCategory.defaults() : loadedCats;
    _completionHistory = loadedHistory;

    await _storage.saveTasks(_tasks);
    await _storage.saveCategories(_categories);
    await _storage.saveCompletionHistory(_completionHistory);
    notifyListeners();
    return true;
  }
}
