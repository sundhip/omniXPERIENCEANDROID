import 'dart:async';
import '../network/api_client.dart';

class SyncMutation {
  final String id;
  final String entityType;
  final String entityId;
  final String mutationType;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  SyncMutation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.mutationType,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    'mutation_type': mutationType,
    'payload': payload,
    'client_timestamp': timestamp.toIso8601String(),
  };
}

class SyncEngine {
  final ApiClient apiClient;
  final List<SyncMutation> _pendingQueue = [];
  bool _isSyncing = false;

  SyncEngine({required this.apiClient});

  void queueMutation(SyncMutation mutation) {
    _pendingQueue.add(mutation);
  }

  int get pendingCount => _pendingQueue.length;
  bool get isSyncing => _isSyncing;

  Future<bool> flushQueue() async {
    if (_pendingQueue.isEmpty || _isSyncing) return true;
    _isSyncing = true;
    try {
      final payload = {
        'mutations': _pendingQueue.map((m) => m.toJson()).toList(),
        'last_synced_version': 1,
      };
      final res = await apiClient.dio.post('/sync/batch', data: payload);
      if (res.statusCode == 200) {
        _pendingQueue.clear();
        _isSyncing = false;
        return true;
      }
    } catch (e) {
      // Retain items in queue on network error for offline resilience
    }
    _isSyncing = false;
    return false;
  }
}
