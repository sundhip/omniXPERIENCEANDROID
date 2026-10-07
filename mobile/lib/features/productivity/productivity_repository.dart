import 'dart:convert';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

class ProductivityRepository {
  final ApiClient apiClient;

  ProductivityRepository({required this.apiClient});

  // --- EVENTS ---

  Future<List<EventModel>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (category != null) queryParams['category'] = category;

      final res = await apiClient.dio.get('/events', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        final events = (res.data as List)
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // Update local cache
        await _cacheEvents(events);
        return events;
      }
    } catch (_) {
      // Fallback to local cache on offline/network failure
    }
    return await _loadCachedEvents();
  }

  Future<EventModel> createEvent(EventModel event) async {
    try {
      final payload = event.toJson();
      payload.remove('id'); // Let server assign standard ID
      final res = await apiClient.dio.post('/events', data: payload);
      if (res.statusCode == 201) {
        final created = EventModel.fromJson(res.data as Map<String, dynamic>);
        final cached = await _loadCachedEvents();
        cached.add(created);
        await _cacheEvents(cached);
        return created;
      }
    } catch (e) {
      // If offline, save locally
      final cached = await _loadCachedEvents();
      cached.add(event);
      await _cacheEvents(cached);
      return event;
    }
    return event;
  }

  Future<EventModel> updateEvent(EventModel event) async {
    try {
      final res = await apiClient.dio.put('/events/${event.id}', data: event.toJson());
      if (res.statusCode == 200) {
        final updated = EventModel.fromJson(res.data as Map<String, dynamic>);
        final cached = await _loadCachedEvents();
        final idx = cached.indexWhere((e) => e.id == event.id);
        if (idx != -1) {
          cached[idx] = updated;
          await _cacheEvents(cached);
        }
        return updated;
      }
    } catch (_) {
      final cached = await _loadCachedEvents();
      final idx = cached.indexWhere((e) => e.id == event.id);
      if (idx != -1) {
        cached[idx] = event;
        await _cacheEvents(cached);
      }
    }
    return event;
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await apiClient.dio.delete('/events/$eventId');
    } catch (_) {}
    final cached = await _loadCachedEvents();
    cached.removeWhere((e) => e.id == eventId);
    await _cacheEvents(cached);
  }

  // --- TASKS ---

  Future<List<TaskModel>> getTasks({
    String? status,
    String? category,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (priority != null) queryParams['priority'] = priority;

      final res = await apiClient.dio.get('/tasks', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        final tasks = (res.data as List)
            .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
            .toList();
        await _cacheTasks(tasks);
        return tasks;
      }
    } catch (_) {
      // Fallback to local cache
    }
    return await _loadCachedTasks();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final payload = task.toJson();
      payload.remove('id');
      final res = await apiClient.dio.post('/tasks', data: payload);
      if (res.statusCode == 201) {
        final created = TaskModel.fromJson(res.data as Map<String, dynamic>);
        final cached = await _loadCachedTasks();
        cached.add(created);
        await _cacheTasks(cached);
        return created;
      }
    } catch (e) {
      final cached = await _loadCachedTasks();
      cached.add(task);
      await _cacheTasks(cached);
      return task;
    }
    return task;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final res = await apiClient.dio.put('/tasks/${task.id}', data: task.toJson());
      if (res.statusCode == 200) {
        final updated = TaskModel.fromJson(res.data as Map<String, dynamic>);
        final cached = await _loadCachedTasks();
        final idx = cached.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          cached[idx] = updated;
          await _cacheTasks(cached);
        }
        return updated;
      }
    } catch (_) {
      final cached = await _loadCachedTasks();
      final idx = cached.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        cached[idx] = task;
        await _cacheTasks(cached);
      }
    }
    return task;
  }

  Future<TaskModel> toggleTaskCompletion(String taskId) async {
    try {
      final res = await apiClient.dio.post('/tasks/$taskId/complete');
      if (res.statusCode == 200) {
        final updated = TaskModel.fromJson(res.data as Map<String, dynamic>);
        final cached = await _loadCachedTasks();
        final idx = cached.indexWhere((t) => t.id == taskId);
        if (idx != -1) {
          cached[idx] = updated;
          await _cacheTasks(cached);
        }
        return updated;
      }
    } catch (_) {
      // Optimistic offline toggle
      final cached = await _loadCachedTasks();
      final idx = cached.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        final current = cached[idx];
        final newStatus = current.status == 'Completed' ? 'Todo' : 'Completed';
        final updated = current.copyWith(
          status: newStatus,
          completedAt: newStatus == 'Completed' ? DateTime.now() : null,
        );
        cached[idx] = updated;
        await _cacheTasks(cached);
        return updated;
      }
    }
    throw Exception('Task not found');
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await apiClient.dio.delete('/tasks/$taskId');
    } catch (_) {}
    final cached = await _loadCachedTasks();
    cached.removeWhere((t) => t.id == taskId);
    await _cacheTasks(cached);
  }

  // --- TODAY DASHBOARD ---

  Future<Map<String, dynamic>?> getTodayDashboard() async {
    try {
      final res = await apiClient.dio.get('/productivity/today');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // --- CACHE HELPERS ---

  Future<void> _cacheEvents(List<EventModel> events) async {
    final raw = jsonEncode(events.map((e) => e.toJson()).toList());
    await SecureStorage.saveEventsCache(raw);
  }

  Future<List<EventModel>> _loadCachedEvents() async {
    final raw = await SecureStorage.getEventsCache();
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheTasks(List<TaskModel> tasks) async {
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await SecureStorage.saveTasksCache(raw);
  }

  Future<List<TaskModel>> _loadCachedTasks() async {
    final raw = await SecureStorage.getTasksCache();
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((t) => TaskModel.fromJson(t as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
