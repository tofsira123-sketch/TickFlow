import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'tickflow_reminders',
    'TickFlow Reminders',
    channelDescription: 'Scheduled reminders for your TickFlow tasks',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Safe fallback on unsupported platforms
    }
  }

  Future<void> requestPermissions() async {
    if (!_initialized) await init();
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // Ignore if platform does not require runtime permission
    }
  }

  int _notificationId(String taskId) {
    return taskId.hashCode & 0x7FFFFFFF;
  }

  Future<void> scheduleTaskReminder(TaskItem task) async {
    if (!_initialized) await init();
    if (!task.hasReminder || task.dueDate == null || task.isCompleted) {
      await cancelTaskReminder(task.id);
      return;
    }
    if (task.dueDate!.isBefore(DateTime.now())) {
      return;
    }

    try {
      final scheduled = tz.TZDateTime.from(task.dueDate!, tz.local);
      await _plugin.zonedSchedule(
        _notificationId(task.id),
        'TickFlow Reminder',
        task.title,
        scheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Avoid crashing if timezone/alarm scheduling fails
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_notificationId(taskId));
    } catch (_) {
      // Ignore cancel errors
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Ignore
    }
  }

  Future<bool> showTestNotification() async {
    if (!_initialized) await init();
    try {
      await requestPermissions();
      await _plugin.show(
        999999,
        'TickFlow Reminder Ready',
        'Notifications are active. Plan simply, finish smoothly!',
        _notificationDetails,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
