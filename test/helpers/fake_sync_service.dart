// test/helpers/fake_sync_service.dart
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';

/// Cola de sincronización de prueba: guarda lo encolado en memoria.
class FakeSyncService extends SyncService {
  FakeSyncService() : super(null);

  final ops = <Map<String, dynamic>>[];
  bool fail = false;

  @override
  Future<void> onInit() async {}

  void _add(String entityType, String entityId, SyncOperationType type,
      Map<String, dynamic> data) {
    if (fail) throw Exception('cola no disponible');
    ops.add({'entityType': entityType, 'entityId': entityId, 'op': type.name, ...data});
  }

  @override
  Future<void> addOperation({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required String organizationId,
    int priority = 0,
  }) async =>
      _add(entityType, entityId, operationType, data);

  @override
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async =>
      _add(entityType, entityId, operationType, data);
}
