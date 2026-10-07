import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';

class ScheduledReminder {
  final String id;
  final String title;
  final String body;
  final DateTime triggerTime;
  final String entityType; // 'event' or 'task'
  final String entityId;

  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerTime,
    required this.entityType,
    required this.entityId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'trigger_time': triggerTime.toIso8601String(),
    'entity_type': entityType,
    'entity_id': entityId,
  };

  factory ScheduledReminder.fromJson(Map<String, dynamic> json) => ScheduledReminder(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    triggerTime: DateTime.tryParse(json['trigger_time'] ?? '') ?? DateTime.now(),
    entityType: json['entity_type'] ?? 'event',
    entityId: json['entity_id'] ?? '',
  );
}

class ProductivityNotificationService {
  static const String _prefRemindersEnabled = 'op_productivity_reminders_enabled';
  static const String _prefActiveReminders = 'op_productivity_active_reminders';

  static final ProductivityNotificationService _instance = ProductivityNotificationService._internal();
  factory ProductivityNotificationService() => _instance;
  ProductivityNotificationService._internal();

  final List<ScheduledReminder> _activeReminders = [];
  bool _remindersEnabled = true;

  bool get remindersEnabled => _remindersEnabled;
  List<ScheduledReminder> get activeReminders => List.unmodifiable(_activeReminders);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _remindersEnabled = prefs.getBool(_prefRemindersEnabled) ?? true;
      final rawList = prefs.getStringList(_prefActiveReminders) ?? [];
      _activeReminders.clear();
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final reminder = ScheduledReminder.fromJson(decoded);
          // Only keep future reminders
          if (reminder.triggerTime.isAfter(DateTime.now())) {
            _activeReminders.add(reminder);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    _remindersEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefRemindersEnabled, enabled);
    } catch (_) {}
  }

  Future<void> scheduleEventReminders(EventModel event) async {
    if (!_remindersEnabled) return;
    // Clear old reminders for this event
    _activeReminders.removeWhere((r) => r.entityId == event.id);

    final now = DateTime.now();
    for (final minutesBefore in event.reminderSettings) {
      final trigger = event.startTime.subtract(Duration(minutes: minutesBefore));
      if (trigger.isAfter(now)) {
        final reminder = ScheduledReminder(
          id: '${event.id}_rem_$minutesBefore',
          title: 'Upcoming: ${event.title}',
          body: 'Starts in $minutesBefore minutes (${event.location ?? 'No location'})',
          triggerTime: trigger,
          entityType: 'event',
          entityId: event.id,
        );
        _activeReminders.add(reminder);
      }
    }
    await _persistReminders();
  }

  Future<void> scheduleTaskReminders(TaskModel task) async {
    if (!_remindersEnabled || task.dueDate == null) return;
    // Clear old reminders for this task
    _activeReminders.removeWhere((r) => r.entityId == task.id);

    final now = DateTime.now();
    for (final minutesBefore in task.reminderSettings) {
      final trigger = task.dueDate!.subtract(Duration(minutes: minutesBefore));
      if (trigger.isAfter(now)) {
        final reminder = ScheduledReminder(
          id: '${task.id}_rem_$minutesBefore',
          title: 'Deadline Approaching: ${task.title}',
          body: 'Due in $minutesBefore minutes (${task.priority} Priority)',
          triggerTime: trigger,
          entityType: 'task',
          entityId: task.id,
        );
        _activeReminders.add(reminder);
      }
    }
    await _persistReminders();
  }

  Future<void> cancelRemindersForEntity(String entityId) async {
    _activeReminders.removeWhere((r) => r.entityId == entityId);
    await _persistReminders();
  }

  Future<void> _persistReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = _activeReminders.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_prefActiveReminders, serialized);
    } catch (_) {}
  }
}
