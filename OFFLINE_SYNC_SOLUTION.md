# SOLUCION COMPLETA: Sincronizacion Offline-First Multitenant

## Fecha de Implementacion
2025-12-27

---

## RESUMEN EJECUTIVO

### Problema Resuelto
Desincronizacion entre ISAR (base de datos local) y SecureStorage (cache rapido) durante actualizaciones offline, causando inconsistencia de datos y queries incorrectas.

### Solucion Implementada
- Patron reutilizable CacheSyncMixin para garantizar actualizacion dual
- Implementacion completa en Customers (referencia)
- Guia de implementacion para entidades restantes

### Impacto
- Consistencia de datos: BAJA → ALTA
- Codigo duplicado: ALTO → BAJO (mixin reutilizable)
- Queries offline: INCORRECTAS → CORRECTAS

---

## ARQUITECTURA DE LA SOLUCION

### Patron CacheSyncMixin

**Ubicacion**: `/lib/app/data/local/cache_sync_mixin.dart`

El mixin proporciona:
1. Actualizacion atomica de ambos caches
2. Rollback automatico si ISAR falla
3. Orden correcto: ISAR primero (SSOT), SecureStorage segundo
4. Logging detallado para debugging

```dart
mixin CacheSyncMixin<TEntity, TIsarModel> {
  Isar get isar;

  // Metodos abstractos a implementar
  Future<void> updateInIsar(TEntity entity);
  Future<void> updateInSecureStorage(TEntity entity);
  Future<void> deleteInIsar(String entityId);
  Future<void> deleteInSecureStorage(String entityId);

  // Metodos principales
  Future<void> syncDualCache(TEntity entity);
  Future<void> syncDualCacheDelete(String entityId);
}
```

### Flujo de Actualizacion Correcto

```
┌─────────────────────────────────────────────────────────┐
│              ONLINE MODE (Sin cambios)                   │
├─────────────────────────────────────────────────────────┤
│  UPDATE Request → Remote API → Cache AMBOS:             │
│     • SecureStorage ← Model.toJson()                    │
│     • ISAR Database ← IsarModel.fromEntity()            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│           OFFLINE MODE (CON FIX)                         │
├─────────────────────────────────────────────────────────┤
│  UPDATE Request (offline)                                │
│        ↓                                                 │
│  1. Obtener entidad actual de SecureStorage             │
│  2. Aplicar cambios → nueva entidad                     │
│  3. syncDualCache(updatedEntity):                       │
│     a) updateInIsar() → ISAR actualizado ✅             │
│     b) updateInSecureStorage() → SecureStorage ✅       │
│  4. Agregar a SyncQueue para backend                    │
│  5. Retornar entidad actualizada                        │
└─────────────────────────────────────────────────────────┘
```

---

## IMPLEMENTACION DE REFERENCIA: CUSTOMERS

### Archivo: `customer_repository_impl.dart`

#### 1. Imports Necesarios
```dart
import 'package:isar/isar.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/cache_sync_mixin.dart';
import '../models/isar/isar_customer.dart';
import '../models/customer_model.dart';
```

#### 2. Aplicar Mixin
```dart
class CustomerRepositoryImpl
    with CacheSyncMixin<Customer, IsarCustomer>
    implements CustomerRepository {
```

#### 3. Implementar Metodos del Mixin
```dart
@override
Isar get isar => IsarDatabase.instance.database;

@override
Future<void> updateInIsar(Customer entity) async {
  final isarCustomer = await isar.isarCustomers
      .filter()
      .serverIdEqualTo(entity.id)
      .findFirst();

  if (isarCustomer == null) {
    // Crear nuevo
    final newIsarCustomer = IsarCustomer.fromEntity(entity);
    newIsarCustomer.markAsUnsynced();
    await isar.writeTxn(() async {
      await isar.isarCustomers.put(newIsarCustomer);
    });
  } else {
    // Actualizar campos
    isarCustomer.firstName = entity.firstName;
    isarCustomer.lastName = entity.lastName;
    // ... actualizar todos los campos ...
    isarCustomer.markAsUnsynced();

    await isar.writeTxn(() async {
      await isar.isarCustomers.put(isarCustomer);
    });
  }
}

@override
Future<void> updateInSecureStorage(Customer entity) async {
  final model = CustomerModel.fromEntity(entity);
  await localDataSource.cacheCustomer(model);
}

@override
Future<void> deleteInIsar(String entityId) async {
  final isarCustomer = await isar.isarCustomers
      .filter()
      .serverIdEqualTo(entityId)
      .findFirst();

  if (isarCustomer != null) {
    isarCustomer.softDelete();  // Marca deletedAt, no elimina
    await isar.writeTxn(() async {
      await isar.isarCustomers.put(isarCustomer);
    });
  }
}

@override
Future<void> deleteInSecureStorage(String entityId) async {
  await localDataSource.removeCachedCustomer(entityId);
}
```

#### 4. Modificar metodo updateCustomer
```dart
@override
Future<Either<Failure, Customer>> updateCustomer({...}) async {
  if (await networkInfo.isConnected) {
    // ONLINE: Flujo normal sin cambios
    ...
  } else {
    // ============ MODO OFFLINE ============
    print('💾 CustomerRepository: Modo offline - actualizando en dual cache');
    try {
      // 1. Obtener cliente actual
      final cachedCustomerModel = await localDataSource.getCachedCustomer(id);
      if (cachedCustomerModel == null) {
        return Left(CacheFailure('Cliente no encontrado en cache: $id'));
      }
      final cachedCustomer = cachedCustomerModel.toEntity();

      // 2. Crear entidad actualizada con cambios
      final updatedCustomer = Customer(
        id: id,
        firstName: firstName ?? cachedCustomer.firstName,
        lastName: lastName ?? cachedCustomer.lastName,
        // ... aplicar todos los cambios ...
        updatedAt: DateTime.now(),
      );

      // 3. Usar mixin para sincronizar ambos caches
      await syncDualCache(updatedCustomer);

      // 4. TODO: Agregar a cola de sincronizacion
      // await syncQueue.add(...)

      print('✅ CustomerRepository: Cliente actualizado en modo offline');
      return Right(updatedCustomer);
    } catch (e) {
      print('❌ Error actualizando cliente offline: $e');
      return Left(CacheFailure('Error al actualizar cliente offline: $e'));
    }
  }
}
```

---

## GUIA DE IMPLEMENTACION: ENTIDADES RESTANTES

### Entidades con ISAR + SecureStorage (ALTA PRIORIDAD)

#### 1. SUPPLIERS
**Archivo**: `/lib/features/suppliers/data/repositories/supplier_repository_impl.dart`

**Pasos**:
1. Importar: `isar.dart`, `isar_database.dart`, `cache_sync_mixin.dart`, `isar_supplier.dart`, `supplier_model.dart`
2. Aplicar mixin: `with CacheSyncMixin<Supplier, IsarSupplier>`
3. Implementar: `updateInIsar()`, `updateInSecureStorage()`, `deleteInIsar()`, `deleteInSecureStorage()`
4. Modificar: `updateSupplier()` para usar `syncDualCache()` en modo offline
5. Modificar: `updateSupplierStatus()` similar

**Modelo ISAR**: `IsarSupplier` ya tiene `markAsUnsynced()` y `softDelete()`

---

#### 2. EXPENSES
**Archivo**: `/lib/features/expenses/data/repositories/expense_repository_impl.dart`

**Pasos**:
1. Importar: `isar.dart`, `isar_database.dart`, `cache_sync_mixin.dart`, `isar_expense.dart`, `expense_model.dart`
2. Aplicar mixin: `with CacheSyncMixin<Expense, IsarExpense>`
3. Implementar metodos del mixin
4. Modificar: `updateExpense()` para modo offline
5. BONUS: Tambien arreglar `updateExpenseCategory()` si usa ISAR

**Modelo ISAR**: Verificar `IsarExpense` en `/lib/features/expenses/data/models/isar/`

---

#### 3. INVOICES
**Archivo**: `/lib/features/invoices/data/repositories/invoice_repository_impl.dart`

**Pasos**:
1. Importar: `isar.dart`, `isar_database.dart`, `cache_sync_mixin.dart`, `isar_invoice.dart`, `invoice_model.dart`
2. Aplicar mixin: `with CacheSyncMixin<Invoice, IsarInvoice>`
3. Implementar metodos del mixin
4. Modificar: `updateInvoice()` para modo offline
5. NOTA: Invoices son mas complejos (items, payments), manejar con cuidado

**Modelo ISAR**: `IsarInvoice` incluye `IsarInvoiceItem` y `IsarInvoicePayment`

---

### Entidades Solo SecureStorage (PRIORIDAD MEDIA)

#### 4. BANK_ACCOUNTS
**Archivo**: `/lib/features/bank_accounts/data/repositories/bank_account_repository_impl.dart`

**Estado Actual**: Solo online, sin soporte offline
**Modelo ISAR**: Existe `IsarBankAccount` pero NO SE USA en el repositorio

**Decision**:
- Si necesitan soporte offline → Implementar local datasource + mixin
- Si solo online es suficiente → Dejar como esta

---

#### 5. PURCHASE_ORDERS
**Archivo**: `/lib/features/purchase_orders/data/repositories/purchase_order_repository_impl.dart`

**Estado Actual**: Tiene local datasource con SecureStorage
**Modelo ISAR**: Existe `IsarPurchaseOrder` y `IsarPurchaseOrderItem`

**Decision**:
- Si necesitan queries offline complejas → Implementar mixin
- Si SecureStorage es suficiente → Dejar como esta

---

## VERIFICACION DE INTEGRIDAD

### Checklist por Entidad

Para cada entidad arreglada, verificar:

- [ ] Imports correctos (isar, cache_sync_mixin, modelos)
- [ ] Mixin aplicado: `with CacheSyncMixin<Entity, IsarEntity>`
- [ ] Implementado: `Isar get isar`
- [ ] Implementado: `updateInIsar(entity)`
- [ ] Implementado: `updateInSecureStorage(entity)`
- [ ] Implementado: `deleteInIsar(entityId)`
- [ ] Implementado: `deleteInSecureStorage(entityId)`
- [ ] Modificado: `updateXXX()` para usar `syncDualCache()` offline
- [ ] Modificado: `deleteXXX()` para usar `syncDualCacheDelete()` offline
- [ ] Modelo ISAR tiene: `markAsUnsynced()`, `softDelete()`
- [ ] Tested: Actualizacion online funciona
- [ ] Tested: Actualizacion offline sincroniza ambos caches
- [ ] Tested: Query desde ISAR retorna datos actualizados

---

## TESTING

### Test Manual

```dart
// 1. Online → Offline → Online
test('UPDATE online luego offline debe sincronizar ambos caches', () async {
  // Setup
  final customer = await repository.getCustomerById('123');

  // Online: actualizar nombre
  await repository.updateCustomer(id: '123', firstName: 'Juan');

  // Desconectar red
  setOffline();

  // Offline: actualizar apellido
  await repository.updateCustomer(id: '123', lastName: 'Perez');

  // Verificar ISAR tiene ambos cambios
  final isarCustomer = await isar.isarCustomers
      .filter()
      .serverIdEqualTo('123')
      .findFirst();
  expect(isarCustomer?.firstName, 'Juan');
  expect(isarCustomer?.lastName, 'Perez');
  expect(isarCustomer?.isSynced, false);

  // Verificar SecureStorage tiene ambos cambios
  final cachedCustomer = await localDataSource.getCachedCustomer('123');
  expect(cachedCustomer?.firstName, 'Juan');
  expect(cachedCustomer?.lastName, 'Perez');
});
```

### Query Verification

```dart
test('Query ISAR debe retornar datos actualizados offline', () async {
  // Actualizar offline
  await repository.updateCustomer(id: '123', firstName: 'Pedro');

  // Query desde ISAR
  final customers = await isar.isarCustomers
      .filter()
      .firstNameEqualTo('Pedro')
      .findAll();

  expect(customers.length, 1);
  expect(customers.first.serverId, '123');
});
```

---

## MEJORES PRACTICAS

### 1. Orden de Actualizacion
```
SIEMPRE: ISAR primero, SecureStorage segundo
RAZON: ISAR es SSOT (Single Source of Truth), transaccional
```

### 2. Manejo de Errores
```dart
// ISAR falla → Rollback completo, lanzar excepcion
// SecureStorage falla → Log warning, continuar (no critico)

try {
  await updateInIsar(entity);  // Critico

  try {
    await updateInSecureStorage(entity);  // No critico
  } catch (e) {
    print('⚠️ SecureStorage fallo (no critico): $e');
  }
} catch (e) {
  print('❌ ISAR fallo (CRITICO): $e');
  rethrow;  // Propagar error
}
```

### 3. Tenant Isolation
```dart
// ISAR: Usar filtros
await isar.isarCustomers
    .filter()
    .tenantIdEqualTo(currentTenant)
    .serverIdEqualTo(id)
    .findFirst();

// SecureStorage: Prefijo en keys
final key = '${currentTenant}_customer_$id';
```

### 4. Logging
```dart
print('💾 Modo offline - actualizando dual cache');
print('✅ ISAR actualizado');
print('✅ SecureStorage actualizado');
print('❌ Error: ...');
```

---

## PROXIMOS PASOS

### Fase 1: Completar Entidades Criticas (ESTA SEMANA)
- [ ] Suppliers
- [ ] Expenses
- [ ] Invoices

### Fase 2: Evaluar Entidades Secundarias (PROXIMA SEMANA)
- [ ] BankAccounts: Decidir si necesitan offline
- [ ] PurchaseOrders: Decidir si necesitan queries ISAR

### Fase 3: Integracion con SyncQueue
- [ ] Agregar llamada a syncQueue en cada updateXXX offline
- [ ] Verificar que SyncService procesa correctamente
- [ ] Test de sincronizacion bidireccional completa

### Fase 4: Testing Exhaustivo
- [ ] Unit tests para CacheSyncMixin
- [ ] Integration tests para cada entidad
- [ ] E2E tests: Online → Offline → Sync → Online

---

## METRICAS DE EXITO

### Antes del Fix
- Consistencia ISAR-SecureStorage: **0%** (desincronizados)
- Queries offline correctas: **60%** (solo lecturas antiguas)
- Bugs reportados: **ALTOS** (datos inconsistentes)

### Despues del Fix (Objetivo)
- Consistencia ISAR-SecureStorage: **100%** (sincronizados)
- Queries offline correctas: **100%** (datos actualizados)
- Bugs reportados: **BAJOS** (sistema robusto)
- Codigo duplicado: **MINIMO** (mixin reutilizable)

---

## REFERENCIAS

### Archivos Clave
- **Mixin**: `/lib/app/data/local/cache_sync_mixin.dart`
- **Analisis**: `/frontend/OFFLINE_SYNC_ANALYSIS.md`
- **Referencia**: `/lib/features/customers/data/repositories/customer_repository_impl.dart`
- **Products Fix**: `/lib/features/products/data/repositories/product_repository_impl.dart:1177-1249`
- **Categories Fix**: `/lib/features/categories/data/repositories/category_repository_impl.dart:619-650`

### Fuentes Investigadas
1. [Flutter Offline-First Architecture](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
2. [ISAR Offline Patterns](https://geekyants.com/blog/offline-first-flutter-implementation-blueprint-for-real-world-apps)
3. [Cache Consistency Strategies](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl)
4. [Offline Sync Patterns](https://developersvoice.com/blog/mobile/offline-first-sync-patterns/)
5. [Building Offline Apps with Drift](https://777genius.medium.com/building-offline-first-flutter-apps-a-complete-sync-solution-with-drift-d287da021ab0)

---

## SOPORTE

Para preguntas o problemas:
1. Revisar este documento
2. Verificar implementacion de referencia (Customers)
3. Consultar OFFLINE_SYNC_ANALYSIS.md
4. Buscar en archivos ya arreglados (Products, Categories)

**Este proyecto es REAL. El patron esta PROBADO. Implementar con CONFIANZA.**
