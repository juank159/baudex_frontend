# Guía del SyncService de Baudex

## 📋 Descripción

El `SyncService` es el orquestador central del sistema offline-first de Baudex. Maneja la sincronización bidireccional entre el almacenamiento local (ISAR) y el servidor backend, garantizando que los datos estén consistentes en ambos lados.

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────┐
│                    SyncService                        │
│                                                       │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐ │
│  │   Timer    │───▶│  syncAll() │───▶│  Network   │ │
│  │ Auto-Sync  │    │            │    │   Check    │ │
│  └────────────┘    └────────────┘    └────────────┘ │
│                           │                           │
│                           ▼                           │
│            ┌──────────────────────────┐              │
│            │  RepositoriesRegistry    │              │
│            │  - products              │              │
│            │  - customers             │              │
│            │  - categories            │              │
│            │  - invoices              │              │
│            │  - notifications         │              │
│            │  - inventory             │              │
│            └──────────────────────────┘              │
│                           │                           │
│         ┌─────────────────┴─────────────────┐       │
│         ▼                                     ▼       │
│  ┌─────────────┐                      ┌─────────────┐│
│  │   Upload    │                      │  Download   ││
│  │   Local     │                      │   Server    ││
│  │  Changes    │                      │  Changes    ││
│  └─────────────┘                      └─────────────┘│
└──────────────────────────────────────────────────────┘
```

---

## 🚀 Inicio Rápido

### 1. Obtener Instancia

```dart
final syncService = Get.find<SyncService>();
```

### 2. Sincronización Manual

```dart
// Sincronizar todos los módulos
final result = await syncService.syncAll(showProgress: true);

if (result.isSuccess) {
  print('✅ Sincronización completada');
  print('Entidades: ${result.syncedEntities}/${result.totalEntities}');
} else {
  print('❌ Sincronización fallida');
  print('Errores: ${result.errors}');
}
```

### 3. Sincronización de un Módulo Específico

```dart
// Sincronizar solo productos
final result = await syncService.syncFeature('products');
```

### 4. Verificar si Hay Cambios Pendientes

```dart
final needsSync = await syncService.needsSync();
if (needsSync) {
  print('Hay cambios pendientes por sincronizar');
}
```

---

## 📊 Estados de Sincronización

```dart
enum SyncStatus {
  idle,              // Sin sincronizar
  syncing,           // Sincronizando actualmente
  completed,         // Completado exitosamente
  failed,            // Falló completamente
  partiallyCompleted // Completado parcialmente
}
```

### Observar Estado

```dart
// En un controller de GetX
class MyController extends GetxController {
  final SyncService syncService = Get.find();

  @override
  void onInit() {
    super.onInit();

    // Escuchar cambios en el estado
    ever(syncService.syncStatus, (status) {
      switch (status) {
        case SyncStatus.idle:
          print('Idle');
          break;
        case SyncStatus.syncing:
          print('Sincronizando...');
          showLoadingDialog();
          break;
        case SyncStatus.completed:
          print('Completado');
          hideLoadingDialog();
          break;
        case SyncStatus.failed:
          print('Error');
          showErrorDialog();
          break;
        case SyncStatus.partiallyCompleted:
          print('Completado parcialmente');
          showWarningDialog();
          break;
      }
    });
  }
}
```

---

## ⏱️ Auto-Sincronización

El `SyncService` incluye sincronización automática cada 5 minutos.

### Configuración

```dart
// Activar auto-sync
syncService.startAutoSync();

// Desactivar auto-sync
syncService.stopAutoSync();

// Verificar estado
final isEnabled = syncService.isAutoSyncEnabled;
```

### Personalizar Intervalo

Para cambiar el intervalo, modifica el constructor:

```dart
// En sync_service.dart
final Duration _autoSyncInterval = const Duration(minutes: 10); // Cambiar a 10 min
```

---

## 📤 Flujo de Sincronización

### Upload (Local → Servidor)

```
┌──────────────┐
│ Repository   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ getUnsyncedEntities() │  ← Obtener entidades no sincronizadas
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Remote Datasource │  ← Enviar al servidor
└──────┬───────────┘
       │ success
       ▼
┌──────────────────┐
│  markAsSynced()   │  ← Marcar como sincronizado
└──────────────────┘
```

**Ejemplo:**

```dart
Future<_SyncOperationResult> _uploadLocalChanges(dynamic repo) async {
  try {
    // 1. Obtener entidades no sincronizadas
    final unsynced = await repo.getUnsyncedEntities();

    if (unsynced.isEmpty) {
      return _SyncOperationResult(syncedCount: 0, failedCount: 0, errors: []);
    }

    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    // 2. Enviar cada entidad al servidor
    for (final entity in unsynced) {
      try {
        await remoteDataSource.syncEntity(entity);
        await repo.markAsSynced([entity.id]);
        synced++;
      } catch (e) {
        failed++;
        errors.add('Failed to sync ${entity.id}: $e');
      }
    }

    return _SyncOperationResult(
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  } catch (e) {
    return _SyncOperationResult(
      syncedCount: 0,
      failedCount: 1,
      errors: ['Upload failed: $e'],
    );
  }
}
```

### Download (Servidor → Local)

```
┌──────────────┐
│ Remote API   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  Fetch Updates    │  ← Obtener cambios del servidor
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Local Cache      │  ← Cachear localmente
└──────────────────┘
```

**Ejemplo:**

```dart
Future<_SyncOperationResult> _downloadServerChanges(dynamic repo) async {
  try {
    // 1. Obtener cambios del servidor
    final serverData = await remoteDataSource.fetchAll();

    // 2. Cachear localmente
    await localDataSource.cacheAll(serverData);

    return _SyncOperationResult(
      syncedCount: serverData.length,
      failedCount: 0,
      errors: [],
    );
  } catch (e) {
    return _SyncOperationResult(
      syncedCount: 0,
      failedCount: 1,
      errors: ['Download failed: $e'],
    );
  }
}
```

---

## 📋 RepositoriesRegistry

El `RepositoriesRegistry` centraliza el acceso a todos los repositorios offline.

### Registro de Repositorios

```dart
// En app_binding.dart
Get.lazyPut<RepositoriesRegistry>(() =>
  RepositoriesRegistry(
    products: Get.find<ProductOfflineRepository>(),
    customers: Get.find<CustomerOfflineRepository>(),
    categories: Get.find<CategoryOfflineRepository>(),
    invoices: Get.find<InvoiceOfflineRepository>(),
    notifications: Get.find<NotificationOfflineRepository>(),
    inventory: Get.find<InventoryOfflineRepository>(),
  ),
);
```

### Métodos Disponibles

```dart
// Obtener total de entidades sin sincronizar
final unsyncedCount = await registry.getTotalUnsyncedCount();

// Obtener estadísticas por repositorio
final stats = await registry.getAllSyncStats();
// {
//   'products': RepositorySyncStats(...),
//   'customers': RepositorySyncStats(...),
//   ...
// }

// Obtener repositorios que necesitan sincronización
final needingSync = await registry.getRepositoriesNeedingSync();
// ['products', 'invoices']

// Marcar todas las entidades como sincronizadas
await registry.markAllAsSynced();

// Verificar si está configurado
final isConfigured = registry.isConfigured;

// Obtener lista de repositorios registrados
final registered = registry.registeredRepositories;
// ['products', 'customers', 'categories', ...]
```

---

## 🧪 Testing

### Mock SyncService

```dart
class MockSyncService extends GetxController implements SyncService {
  final _syncStatus = SyncStatus.idle.obs;
  final _lastSyncResult = Rxn<SyncResult>();

  @override
  SyncStatus get syncStatus => _syncStatus.value;

  @override
  Future<SyncResult> syncAll({bool showProgress = true}) async {
    _syncStatus.value = SyncStatus.syncing;
    await Future.delayed(Duration(seconds: 2));

    final result = SyncResult(
      status: SyncStatus.completed,
      totalEntities: 10,
      syncedEntities: 10,
      failedEntities: 0,
      errors: [],
      duration: Duration(seconds: 2),
    );

    _lastSyncResult.value = result;
    _syncStatus.value = SyncStatus.idle;
    return result;
  }
}
```

### Test de Integración

```dart
testWidgets('SyncService syncs all repositories', (tester) async {
  // Arrange
  final syncService = Get.find<SyncService>();

  // Crear datos offline
  await productRepo.createProduct(...);
  await customerRepo.createCustomer(...);

  // Act
  final result = await syncService.syncAll();

  // Assert
  expect(result.isSuccess, true);
  expect(result.syncedEntities, greaterThan(0));
  expect(result.failedEntities, 0);
});
```

---

## ⚙️ Configuración Avanzada

### Prioridades de Sincronización

Los repositorios se sincronizan en orden:
1. Categories (primero, son referenciadas por otros)
2. Products
3. Customers
4. Invoices
5. Notifications
6. Inventory

### Manejo de Errores

```dart
final result = await syncService.syncAll();

if (result.hasErrors) {
  for (final error in result.errors) {
    if (error.contains('Connection refused')) {
      // Error de red
      showSnackbar('Sin conexión a internet');
    } else if (error.contains('401')) {
      // Error de autenticación
      logout();
    } else {
      // Otro error
      log('Sync error: $error');
    }
  }
}
```

### Reintentos Automáticos

```dart
// El SyncService reintenta automáticamente después de 5 minutos
// Si una operación falla, se marcará como 'failed' en la cola
// y se reintentará en la próxima sincronización
```

---

## 📊 Métricas y Monitoring

### Obtener Resumen de Sincronización

```dart
final summary = await syncService.getSyncSummary();

print('Last Sync: ${summary['lastSync']}');
print('Status: ${summary['currentStatus']}');
print('Total Unsynced: ${summary['totalUnsyncedEntities']}');
print('Repositories Needing Sync: ${summary['repositoriesNeedingSync']}');

// Stats por repositorio
final stats = summary['repositoryStats'];
for (final entry in stats.entries) {
  print('${entry.key}:');
  print('  Total: ${entry.value['totalCount']}');
  print('  Unsynced: ${entry.value['unsyncedCount']}');
  print('  Deleted: ${entry.value['unsyncedDeletedCount']}');
}
```

### Monitorear Progreso en UI

```dart
class SyncProgressWidget extends StatelessWidget {
  final SyncService syncService = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (syncService.syncStatus == SyncStatus.syncing) {
        return Column(
          children: [
            LinearProgressIndicator(value: syncService.progress),
            Text('Sincronizando ${syncService.currentFeature}...'),
          ],
        );
      }
      return Container();
    });
  }
}
```

---

## 🔧 Troubleshooting

### Problema: Sincronización Lenta

**Causa:** Muchas entidades pendientes

**Solución:**
```dart
// Sincronizar por lotes
await syncService.syncFeature('products');
await syncService.syncFeature('customers');
// etc.
```

### Problema: Conflictos de Datos

**Causa:** Misma entidad modificada offline y online

**Solución:** Implementar resolución de conflictos
```dart
// TODO: Future implementation
if (entity.version != serverEntity.version) {
  // Conflict detected - resolve
}
```

### Problema: Auto-Sync No Funciona

**Verificación:**
```dart
// 1. Verificar que está habilitado
print('Auto-sync enabled: ${syncService.isAutoSyncEnabled}');

// 2. Verificar conexión
final hasInternet = await networkInfo.isConnected;
print('Has internet: $hasInternet');

// 3. Verificar timer
// El timer solo se ejecuta si syncStatus == idle
```

---

## 📚 Best Practices

1. **Sincronizar frecuentemente**: Usar auto-sync o sincronizar manualmente después de operaciones importantes

2. **Mostrar indicadores visuales**: Indicar al usuario cuando hay sincronización en progreso

3. **Manejar errores gracefully**: No bloquear la UI si la sincronización falla

4. **Validar antes de sincronizar**: Asegurar que los datos sean válidos antes de enviarlos al servidor

5. **Limpiar operaciones antiguas**: Usar `cleanOldSyncOperations()` periódicamente

6. **Monitorear performance**: Revisar `result.duration` para identificar cuellos de botella

---

## 🚀 Próximas Mejoras

- [ ] Resolución inteligente de conflictos
- [ ] Sincronización diferencial (solo cambios)
- [ ] Compresión de datos para upload/download
- [ ] Sincronización selectiva (permitir al usuario elegir qué sincronizar)
- [ ] Webhook listeners para sincronización en tiempo real

---

**Última actualización:** 2026-01-11
**Versión:** 2.0.0
