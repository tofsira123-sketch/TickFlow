import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFE53935);
      case TaskPriority.medium:
        return const Color(0xFFFB8C00);
      case TaskPriority.low:
        return const Color(0xFF00ACC1);
    }
  }

  int get sortWeight {
    switch (this) {
      case TaskPriority.high:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.low:
        return 2;
    }
  }
}

enum RecurrenceType { none, daily, weekly, monthly }

extension RecurrenceTypeX on RecurrenceType {
  String get label {
    switch (this) {
      case RecurrenceType.none:
        return 'No Repeat';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }
}

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class TaskCategory {
  final String id;
  final String name;
  final int colorValue;
  final bool isDefault;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    return TaskCategory(
      id: json['id'] as String? ?? 'personal',
      name: json['name'] as String? ?? 'Personal',
      colorValue: json['colorValue'] as int? ?? 0xFF3949AB,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  static List<TaskCategory> defaults() => const [
        TaskCategory(
          id: 'personal',
          name: 'Personal',
          colorValue: 0xFF3949AB,
          isDefault: true,
        ),
        TaskCategory(
          id: 'work',
          name: 'Work',
          colorValue: 0xFF00897B,
          isDefault: true,
        ),
        TaskCategory(
          id: 'study',
          name: 'Study',
          colorValue: 0xFF8E24AA,
          isDefault: true,
        ),
        TaskCategory(
          id: 'shopping',
          name: 'Shopping',
          colorValue: 0xFFFB8C00,
          isDefault: true,
        ),
      ];
}

class TaskItem {
  final String id;
  final String title;
  final String notes;
  final String categoryId;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool hasReminder;
  final RecurrenceType recurrence;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final List<SubTask> subTasks;

  const TaskItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.categoryId = 'personal',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.hasReminder = false,
    this.recurrence = RecurrenceType.none,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.subTasks = const [],
  });

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  int get completedSubTaskCount =>
      subTasks.where((s) => s.isCompleted).length;

  TaskItem copyWith({
    String? id,
    String? title,
    String? notes,
    String? categoryId,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? hasReminder,
    RecurrenceType? recurrence,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    List<SubTask>? subTasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      hasReminder: hasReminder ?? this.hasReminder,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'categoryId': categoryId,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'hasReminder': hasReminder,
        'recurrence': recurrence.name,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'subTasks': subTasks.map((s) => s.toJson()).toList(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final priorityName = json['priority'] as String? ?? 'medium';
    final recurrenceName = json['recurrence'] as String? ?? 'none';
    final rawSubTasks = json['subTasks'] as List<dynamic>? ?? const [];

    return TaskItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? 'personal',
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == priorityName,
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      hasReminder: json['hasReminder'] as bool? ?? false,
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == recurrenceName,
        orElse: () => RecurrenceType.none,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      subTasks: rawSubTasks
          .whereType<Map<String, dynamic>>()
          .map(SubTask.fromJson)
          .toList(),
    );
  }
}
