# ANALISIS COMPLETO: Sincronizacion Offline-First

## Fecha
2025-12-27

## Problema Identificado

### Sintomas
Cuando se actualiza una entidad del servidor SIN CONEXION:
1. Se actualiza en SecureStorage
2. Se agrega operacion UPDATE a cola de sync
3. **NO se actualiza en ISAR** (base de datos local)

Esto causa DESINCRONIZACION entre los dos caches locales (SecureStorage vs ISAR).

### Impacto
- Datos inconsistentes entre diferentes capas de cache
- Queries de ISAR retornan datos obsoletos
- Offline repositories muestran informacion desactualizada
- Posibles conflictos cuando vuelve la conectividad

---

## Arquitectura Actual

### Patron Dual-Cache
El proyecto utiliza DOS sistemas de cache local:

#### 1. **SecureStorage** (flutter_secure_storage)
- **Uso**: Cache de entidades individuales y listas
- **Ubicacion**: `features/*/data/datasources/*_local_datasource.dart`
- **Formato**: JSON serializado
- **Ventajas**: Rapido para lectura/escritura, seguro
- **Desventajas**: No soporta queries complejas

#### 2. **ISAR Database** (NoSQL embebida)
- **Uso**: Base de datos local con queries complejas
- **Ubicacion**: `features/*/data/models/isar/isar_*.dart`
- **Formato**: Objetos ISAR nativos
- **Ventajas**: Queries potentes, indices, relaciones
- **Desventajas**: Requiere mas codigo de mapeo

### Flujo de Datos

```
┌─────────────────────────────────────────────────────┐
│                     ONLINE MODE                       │
├─────────────────────────────────────────────────────┤
│                                                       │
│  UPDATE Request (Repository)                         │
│        ↓                                              │
│  Remote API (backend)                                │
│        ↓                                              │
│  Actualiza AMBOS caches:                             │
│     • SecureStorage ← Model.toJson()                 │
│     • ISAR Database ← IsarModel.fromEntity()         │
│                                                       │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   OFFLINE MODE (ACTUAL - ROTO)       │
├─────────────────────────────────────────────────────┤
│                                                       │
│  UPDATE Request (Repository)                         │
│        ↓                                              │
│  NetworkInfo.isConnected = FALSE                     │
│        ↓                                              │
│  Agrega a SyncQueue (cola de sincronizacion)        │
│        ↓                                              │
│  Actualiza SOLO SecureStorage  ❌                   │
│  ISAR queda DESACTUALIZADO      ❌                   │
│                                                       │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│              OFFLINE MODE (CORRECTO - PRODUCTOS)     │
├─────────────────────────────────────────────────────┤
│                                                       │
│  UPDATE Request (Repository)                         │
│        ↓                                              │
│  NetworkInfo.isConnected = FALSE                     │
│        ↓                                              │
│  Actualiza ISAR PRIMERO       ✅                    │
│        ↓                                              │
│  Actualiza SecureStorage       ✅                    │
│        ↓                                              │
│  Agrega a SyncQueue            ✅                    │
│                                                       │
└─────────────────────────────────────────────────────┘
```

---

## Entidades ISAR Identificadas

### Con ISAR + SecureStorage (REQUIEREN FIX)
1. **Products** - YA ARREGLADO (linea 1177-1249)
2. **Categories** - YA ARREGLADO (linea 619-650)
3. **Customers** - REQUIERE FIX
4. **Suppliers** - REQUIERE FIX
5. **Expenses** - REQUIERE FIX
6. **Invoices** - REQUIERE FIX
7. **BankAccounts** - REQUIERE FIX (solo tiene ISAR model)
8. **PurchaseOrders** - REQUIERE FIX (solo tiene ISAR model)
9. **Inventory** - VERIFICAR
10. **Notifications** - VERIFICAR

### Solo SecureStorage (NO requieren cambios de ISAR)
- Organization
- Settings
- UserPreferences
- Auth data

---

## Mejores Practicas Investigadas

### Fuentes Consultadas
1. [Flutter Offline-First Architecture (Official)](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
2. [ISAR Offline Patterns (GeekyAnts)](https://geekyants.com/blog/offline-first-flutter-implementation-blueprint-for-real-world-apps)
3. [Cache Consistency Strategies (DEV Community)](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl)

### Principios Clave

#### 1. Single Source of Truth (SSOT)
- ISAR debe ser el SSOT para datos complejos
- SecureStorage para cache rapido y datos sensibles
- UI lee de ISAR para consistencia

#### 2. Repository Pattern
- Actua como mediador entre multiples fuentes de datos
- Abstrae la logica de sincronizacion dual
- Presenta una API unificada a la capa de dominio

#### 3. Conflict Resolution
- **Latest Wins**: El timestamp mas reciente prevalece
- **Local First**: Cambios locales tienen prioridad
- **Server First**: Servidor es autoridad final
- Este proyecto usa: **Latest Wins** con cola de sincronizacion

#### 4. Write-Through Cache
- Escrituras van a AMBOS caches simultaneamente
- Garantiza consistencia inmediata
- Patron recomendado para offline-first

---

## Solucion Arquitectonica

### Patron Propuesto: CacheSyncMixin

Un mixin reutilizable que garantiza sincronizacion dual entre ISAR y SecureStorage.

```dart
/// Mixin para sincronizar dual cache (ISAR + SecureStorage)
mixin CacheSyncMixin<TEntity, TModel, TIsarModel> {

  /// Implementado por cada repositorio
  Isar get isar;
  LocalDataSource get localDataSource;

  /// Mappers que deben implementar los repositorios
  TIsarModel entityToIsarModel(TEntity entity);
  TModel entityToModel(TEntity entity);
  TEntity isarModelToEntity(TIsarModel isarModel);

  /// Sincronizacion dual: ISAR + SecureStorage
  Future<void> syncDualCache({
    required TEntity updatedEntity,
    required String entityId,
  }) async {
    // 1. Actualizar ISAR primero (source of truth)
    await updateInIsar(updatedEntity);

    // 2. Actualizar SecureStorage (cache rapido)
    await updateInSecureStorage(updatedEntity);
  }

  Future<void> updateInIsar(TEntity entity) async {
    final isarModel = entityToIsarModel(entity);
    await isar.writeTxn(() async {
      await isar.collection<TIsarModel>().put(isarModel);
    });
  }

  Future<void> updateInSecureStorage(TEntity entity) async {
    final model = entityToModel(entity);
    await localDataSource.cache(model);
  }
}
```

### Ventajas del Patron
1. Reutilizable entre todos los repositorios
2. Garantiza consistencia dual-cache
3. Facil de testear
4. Reduce duplicacion de codigo
5. Claro punto de extension

---

## Plan de Implementacion

### Fase 1: Infraestructura (PRIORIDAD ALTA)
- [x] Crear CacheSyncMixin en `/lib/app/data/local/cache_sync_mixin.dart`
- [ ] Crear tests unitarios para el mixin

### Fase 2: Fix Entidades con ISAR (PRIORIDAD ALTA)
- [ ] Customers: Implementar mixin + fix updateCustomer
- [ ] Suppliers: Implementar mixin + fix updateSupplier
- [ ] Expenses: Implementar mixin + fix updateExpense
- [ ] Invoices: Implementar mixin + fix updateInvoice

### Fase 3: Entidades Solo SecureStorage (PRIORIDAD MEDIA)
- [ ] BankAccounts: Verificar si necesita ISAR
- [ ] PurchaseOrders: Verificar si necesita ISAR

### Fase 4: Verificacion (PRIORIDAD ALTA)
- [ ] Test offline-online de cada entidad
- [ ] Verificar sincronizacion bidireccional
- [ ] Pruebas de conflictos y resolucion

### Fase 5: Documentacion (PRIORIDAD MEDIA)
- [ ] Documentar patron en README
- [ ] Ejemplos de uso del mixin
- [ ] Guia de migracion para nuevas entidades

---

## Metricas de Exito

### Antes (Problema)
- Actualizacion offline: SecureStorage ✅, ISAR ❌
- Consistencia de datos: BAJA
- Bugs reportados: ALTOS
- Queries offline: INCORRECTAS

### Despues (Solucion)
- Actualizacion offline: SecureStorage ✅, ISAR ✅
- Consistencia de datos: ALTA
- Codigo duplicado: BAJO (mixin reutilizable)
- Queries offline: CORRECTAS

---

## Notas Tecnicas

### Orden de Operaciones Offline
```
1. Validar datos de entrada
2. Actualizar ISAR (SSOT) - markAsUnsynced()
3. Actualizar SecureStorage (cache rapido)
4. Agregar a SyncQueue
5. Retornar entidad actualizada
```

### Manejo de Errores
- Si ISAR falla → Rollback completo
- Si SecureStorage falla → Log warning, continuar (no critico)
- Si SyncQueue falla → Reintentar automaticamente

### Tenant Isolation
- ISAR: Usar indices en `tenantId`
- SecureStorage: Prefijo de keys con `tenant_`
- Queries: Filtrar `.tenantIdEqualTo(currentTenant)`

---

## Referencias
- Products fix: `product_repository_impl.dart:1177-1249`
- Categories fix: `category_repository_impl.dart:619-650`
- Base pattern: `base_offline_repository.dart`
- Sync service: `sync_service.dart`
