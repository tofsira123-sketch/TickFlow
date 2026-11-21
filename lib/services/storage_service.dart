import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class StorageService {
  static const String _keyInitialized = 'tickflow_initialized_v1';
  static const String _keyTasks = 'tickflow_tasks_v1';
  static const String _keyCategories = 'tickflow_categories_v1';
  static const String _keyThemeMode = 'tickflow_theme_mode_v1';
  static const String _keyNotificationsEnabled = 'tickflow_notifications_v1';
  static const String _keyCompletionHistory = 'tickflow_history_v1';

  Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInitialized) ?? false;
  }

  Future<void> markInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInitialized, true);
  }

  Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTasks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTasks, encoded);
  }

  Future<List<TaskCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCategories);
    if (raw == null || raw.isEmpty) return TaskCategory.defaults();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskCategory.fromJson)
          .toList();
      return loaded.isEmpty ? TaskCategory.defaults() : loaded;
    } catch (_) {
      return TaskCategory.defaults();
    }
  }

  Future<void> saveCategories(List<TaskCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_keyCategories, encoded);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyThemeMode) ?? 'system';
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<Map<String, int>> loadCompletionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCompletionHistory);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCompletionHistory(Map<String, int> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompletionHistory, jsonEncode(history));
  }

  String exportBackupJson({
    required List<TaskItem> tasks,
    required List<TaskCategory> categories,
    required Map<String, int> completionHistory,
  }) {
    final payload = {
      'app': 'TickFlow',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'completionHistory': completionHistory,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, dynamic>? parseBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['tasks'] is! List) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }
}
