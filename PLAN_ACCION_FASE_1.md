# PLAN DE ACCIÓN - FASE 1: PROBLEMAS CRÍTICOS
## Sistema de Sincronización Offline-First - Baudex Desktop

**Fecha:** 2026-01-06
**Duración Estimada:** 24-30 horas (3-4 semanas)
**Prioridad:** CRÍTICA - Prevenir pérdida de datos en producción

---

## 📋 RESUMEN EJECUTIVO

Este plan aborda **3 problemas críticos** que pueden causar pérdida de datos en el sistema offline-first:

1. ✅ **Sistema de Detección de Conflictos** (10-12 horas)
2. ✅ **Implementación de Idempotencia** (8-10 horas)
3. ✅ **Corrección de Payload Obsoleto** (6-8 horas)

---

## 🎯 PROBLEMA 1: SISTEMA DE DETECCIÓN DE CONFLICTOS

### Contexto del Problema

**Situación actual:**
- NO existe detección de conflictos cuando múltiples usuarios modifican la misma entidad
- Si Usuario A y Usuario B modifican la misma factura offline, la última sincronización sobrescribe cambios sin aviso
- **Riesgo:** Pérdida silenciosa de datos

**Ejemplo real del problema:**
```dart
// Usuario A (offline): Marca factura INV-001 como "pagada" a las 10:00 AM
// Usuario B (offline): Agrega un pago parcial a INV-001 a las 10:05 AM
// Usuario A sincroniza primero a las 11:00 AM → factura queda "pagada"
// Usuario B sincroniza después a las 11:05 AM → SOBRESCRIBE cambios de A
// RESULTADO: Se pierde el estado "pagada" que Usuario A guardó
```

### Solución: Agregar Versionamiento y Detección de Conflictos

---

## 📅 SEMANA 1-2: IMPLEMENTAR DETECCIÓN DE CONFLICTOS

### PASO 1: Agregar Campos de Versionamiento a Modelos Isar (3-4 horas)

#### 1.1 Identificar Archivos a Modificar

**Archivos Isar a actualizar (17 total):**
```
lib/app/data/local/isar/models/
├── isar_invoice.dart          ⚡ CRÍTICO - Alto volumen de cambios
├── isar_customer.dart          ⚡ CRÍTICO - Alto volumen de cambios
├── isar_product.dart           ✅ YA TIENE versionamiento parcial
├── isar_category.dart
├── isar_credit_note.dart
├── isar_customer_credit.dart
├── isar_bank_account.dart
├── isar_expense.dart
├── isar_inventory_item.dart
├── isar_purchase_order.dart
├── isar_supplier.dart
├── isar_organization.dart
├── isar_notification.dart
├── isar_report.dart
├── isar_setting.dart
├── isar_warehouse.dart
└── isar_user.dart
```

#### 1.2 Template de Código para Cada Modelo Isar

**ANTES (isar_invoice.dart - ejemplo):**
```dart
@collection
class IsarInvoice {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? serverId;

  String number;
  String? customerId;
  double total;
  bool isSynced = false;
  DateTime? deletedAt;
  DateTime? lastSyncAt;

  // ... otros campos
}
```

**DESPUÉS (con versionamiento):**
```dart
@collection
class IsarInvoice {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? serverId;

  String number;
  String? customerId;
  double total;
  bool isSynced = false;
  DateTime? deletedAt;
  DateTime? lastSyncAt;

  // ⭐ NUEVOS CAMPOS DE VERSIONAMIENTO
  int version = 0;                    // Versión del documento (incrementa con cada cambio)
  DateTime? lastModifiedAt;           // Timestamp del último cambio
  String? lastModifiedBy;             // Usuario que hizo el último cambio

  // ... otros campos

  // ⭐ NUEVO MÉTODO: Incrementar versión al modificar
  void incrementVersion() {
    version++;
    lastModifiedAt = DateTime.now();
    isSynced = false;
  }

  // ⭐ NUEVO MÉTODO: Detectar si hay conflicto
  bool hasConflictWith(IsarInvoice serverVersion) {
    // Si versión local >= versión servidor → posible conflicto
    return version >= serverVersion.version &&
           lastModifiedAt != serverVersion.lastModifiedAt;
  }
}
```

#### 1.3 Checklist de Implementación

**Para CADA uno de los 17 modelos Isar:**

- [ ] Agregar campo `int version = 0;`
- [ ] Agregar campo `DateTime? lastModifiedAt;`
- [ ] Agregar campo `String? lastModifiedBy;`
- [ ] Agregar método `void incrementVersion()`
- [ ] Agregar método `bool hasConflictWith(IsarX serverVersion)`
- [ ] Modificar método `updateFromModel()` para incrementar versión:
  ```dart
  void updateFromModel(InvoiceModel model) {
    number = model.number;
    customerId = model.customerId;
    total = model.total;
    // ... otros campos

    incrementVersion(); // ⭐ AGREGAR ESTA LÍNEA
  }
  ```

#### 1.4 Ejecutar Code Generation

**Después de modificar todos los modelos Isar:**

```bash
# Regenerar código Isar
dart run build_runner build --delete-conflicting-outputs

# Verificar que no haya errores de compilación
flutter analyze
```

---

### PASO 2: Crear ConflictResolver Service (4-5 horas)

#### 2.1 Crear Archivo del Servicio

**Archivo:** `lib/app/core/services/conflict_resolver.dart`

```dart
// lib/app/core/services/conflict_resolver.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

/// Estrategias de resolución de conflictos
enum ConflictResolutionStrategy {
  serverWins,      // Servidor siempre gana (más seguro para datos críticos)
  clientWins,      // Cliente siempre gana (para preferencias de usuario)
  newerWins,       // El timestamp más reciente gana
  merge,           // Intentar merge automático (solo para campos no conflictivos)
  manual,          // Requiere intervención del usuario
}

/// Resultado de la detección de conflictos
class ConflictResolution<T> {
  final bool hasConflict;
  final T? resolvedData;
  final ConflictResolutionStrategy? strategyUsed;
  final String? conflictMessage;

  ConflictResolution({
    required this.hasConflict,
    this.resolvedData,
    this.strategyUsed,
    this.conflictMessage,
  });
}

/// Servicio centralizado para resolver conflictos de sincronización
class ConflictResolver {
  /// Detecta y resuelve conflictos entre versión local y servidor
  ///
  /// [localData] - Datos locales (Isar)
  /// [serverData] - Datos del servidor
  /// [strategy] - Estrategia de resolución
  /// [entityName] - Nombre de la entidad (para logging)
  Future<ConflictResolution<T>> resolveConflict<T>({
    required T localData,
    required T serverData,
    required ConflictResolutionStrategy strategy,
    required String entityName,
    required bool Function(T local, T server) hasConflictCheck,
    required int Function(T data) getVersion,
    required DateTime? Function(T data) getLastModifiedAt,
  }) async {
    // 1. Detectar si existe conflicto
    final hasConflict = hasConflictCheck(localData, serverData);

    if (!hasConflict) {
      // No hay conflicto, usar datos del servidor
      return ConflictResolution<T>(
        hasConflict: false,
        resolvedData: serverData,
      );
    }

    // 2. Aplicar estrategia de resolución
    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return ConflictResolution<T>(
          hasConflict: true,
          resolvedData: serverData,
          strategyUsed: strategy,
          conflictMessage: 'Conflicto en $entityName - Servidor gana',
        );

      case ConflictResolutionStrategy.clientWins:
        return ConflictResolution<T>(
          hasConflict: true,
          resolvedData: localData,
          strategyUsed: strategy,
          conflictMessage: 'Conflicto en $entityName - Cliente gana',
        );

      case ConflictResolutionStrategy.newerWins:
        final localTime = getLastModifiedAt(localData);
        final serverTime = getLastModifiedAt(serverData);

        if (localTime == null || serverTime == null) {
          // Fallback a serverWins si no hay timestamps
          return ConflictResolution<T>(
            hasConflict: true,
            resolvedData: serverData,
            strategyUsed: ConflictResolutionStrategy.serverWins,
            conflictMessage: 'Conflicto en $entityName - Sin timestamps, servidor gana',
          );
        }

        final winner = localTime.isAfter(serverTime) ? localData : serverData;
        return ConflictResolution<T>(
          hasConflict: true,
          resolvedData: winner,
          strategyUsed: strategy,
          conflictMessage: 'Conflicto en $entityName - Más reciente gana',
        );

      case ConflictResolutionStrategy.merge:
      case ConflictResolutionStrategy.manual:
        // Estas estrategias requieren implementación específica por entidad
        return ConflictResolution<T>(
          hasConflict: true,
          resolvedData: serverData, // Fallback a servidor
          strategyUsed: ConflictResolutionStrategy.serverWins,
          conflictMessage: 'Conflicto en $entityName - Merge/Manual no implementado, usando servidor',
        );
    }
  }

  /// Log de conflictos detectados (para monitoreo)
  void logConflict(String entityName, String entityId, String message) {
    print('⚠️ CONFLICT DETECTED: $entityName [$entityId] - $message');
    // TODO: Enviar a servicio de telemetría/logging
  }
}
```

#### 2.2 Registrar ConflictResolver en DI

**Archivo:** `lib/app/app_binding.dart`

```dart
// lib/app/app_binding.dart
import 'package:baudex_desktop/app/core/services/conflict_resolver.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ... otros bindings existentes

    // ⭐ AGREGAR: ConflictResolver como singleton
    Get.put<ConflictResolver>(
      ConflictResolver(),
      permanent: true,
    );
  }
}
```

---

### PASO 3: Integrar ConflictResolver en Repositorios (3-4 horas)

#### 3.1 Template de Integración

**Ejemplo: InvoiceRepositoryImpl**

**ANTES (lib/features/invoices/data/repositories/invoice_repository_impl.dart):**

```dart
@override
Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
  try {
    if (await networkInfo.isConnected) {
      // Traer del servidor
      final remoteInvoice = await remoteDataSource.getInvoiceById(id);

      // Cachear en Isar
      await localDataSource.cacheInvoice(remoteInvoice);

      return Right(remoteInvoice.toEntity());
    } else {
      // Traer de Isar
      final localInvoice = await localDataSource.getInvoiceById(id);
      if (localInvoice == null) {
        return Left(CacheFailure('Invoice not found in cache'));
      }
      return Right(localInvoice.toEntity());
    }
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

**DESPUÉS (con detección de conflictos):**

```dart
// ⭐ AGREGAR: Inyectar ConflictResolver
final ConflictResolver conflictResolver;

InvoiceRepositoryImpl({
  required this.remoteDataSource,
  required this.localDataSource,
  required this.networkInfo,
  required this.conflictResolver, // ⭐ NUEVO
});

@override
Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
  try {
    if (await networkInfo.isConnected) {
      // Traer del servidor
      final remoteInvoice = await remoteDataSource.getInvoiceById(id);

      // ⭐ AGREGAR: Verificar si existe versión local
      final localInvoice = await localDataSource.getInvoiceById(id);

      if (localInvoice != null && !localInvoice.isSynced) {
        // Hay versión local no sincronizada → detectar conflicto
        final resolution = await conflictResolver.resolveConflict(
          localData: localInvoice,
          serverData: IsarInvoice.fromModel(remoteInvoice),
          strategy: ConflictResolutionStrategy.serverWins, // Configuración por defecto
          entityName: 'Invoice',
          hasConflictCheck: (local, server) => local.hasConflictWith(server),
          getVersion: (data) => data.version,
          getLastModifiedAt: (data) => data.lastModifiedAt,
        );

        if (resolution.hasConflict) {
          conflictResolver.logConflict('Invoice', id, resolution.conflictMessage ?? '');
        }

        // Cachear versión resuelta
        await localDataSource.cacheInvoice(
          InvoiceModel.fromIsarInvoice(resolution.resolvedData!),
        );

        return Right(InvoiceModel.fromIsarInvoice(resolution.resolvedData!).toEntity());
      } else {
        // No hay conflicto → cachear normalmente
        await localDataSource.cacheInvoice(remoteInvoice);
        return Right(remoteInvoice.toEntity());
      }
    } else {
      // Sin conexión → traer de Isar
      final localInvoice = await localDataSource.getInvoiceById(id);
      if (localInvoice == null) {
        return Left(CacheFailure('Invoice not found in cache'));
      }
      return Right(localInvoice.toEntity());
    }
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

#### 3.2 Repositorios a Modificar (17 total)

**Checklist de integración:**

- [ ] `lib/features/invoices/data/repositories/invoice_repository_impl.dart` ⚡ CRÍTICO
- [ ] `lib/features/customers/data/repositories/customer_repository_impl.dart` ⚡ CRÍTICO
- [ ] `lib/features/products/data/repositories/product_repository_impl.dart`
- [ ] `lib/features/categories/data/repositories/category_repository_impl.dart`
- [ ] `lib/features/credit_notes/data/repositories/credit_note_repository_impl.dart`
- [ ] `lib/features/customer_credits/data/repositories/customer_credit_repository_impl.dart`
- [ ] `lib/features/bank_accounts/data/repositories/bank_account_repository_impl.dart`
- [ ] `lib/features/expenses/data/repositories/expense_repository_impl.dart`
- [ ] `lib/features/inventory/data/repositories/inventory_repository_impl.dart`
- [ ] `lib/features/purchase_orders/data/repositories/purchase_order_repository_impl.dart`
- [ ] `lib/features/suppliers/data/repositories/supplier_repository_impl.dart`
- [ ] ... (continuar con los otros 6 repositorios)

**Para cada repositorio:**

1. Agregar `final ConflictResolver conflictResolver;` al constructor
2. Modificar método `getById()` para detectar conflictos
3. Modificar método `getAll()` si es necesario
4. Actualizar binding del feature para inyectar `ConflictResolver`

---

## 🎯 PROBLEMA 2: IMPLEMENTACIÓN DE IDEMPOTENCIA

### Contexto del Problema

**Situación actual:**
- Las operaciones de sincronización NO son idempotentes
- Si el mismo `SyncQueueItem` se procesa 2 veces → se crean datos duplicados
- **Riesgo:** Facturas duplicadas, pagos duplicados, productos duplicados

**Ejemplo real del problema:**
```dart
// Usuario crea factura INV-001 offline
// Se agrega a sync queue con ID local "local-123"
// Sincronización #1: Se envía al servidor → Servidor crea factura con ID "server-456"
// Sincronización #1 falla DESPUÉS de crear en servidor (timeout de red)
// App intenta re-sincronizar el mismo SyncQueueItem
// Sincronización #2: Se envía DE NUEVO al servidor → Servidor crea OTRA factura "server-789"
// RESULTADO: Factura duplicada en el servidor
```

### Solución: Sistema de Idempotency Keys

---

## 📅 SEMANA 2-3: IMPLEMENTAR IDEMPOTENCIA

### PASO 4: Crear Modelo IsarIdempotencyRecord (2-3 horas)

#### 4.1 Crear Archivo del Modelo

**Archivo:** `lib/app/data/local/isar/models/isar_idempotency_record.dart`

```dart
// lib/app/data/local/isar/models/isar_idempotency_record.dart
import 'package:isar/isar.dart';

part 'isar_idempotency_record.g.dart';

/// Registro de idempotencia para prevenir operaciones duplicadas en sync
@collection
class IsarIdempotencyRecord {
  Id id = Isar.autoIncrement;

  /// Clave de idempotencia única (hash de la operación)
  @Index(unique: true, replace: false)
  late String idempotencyKey;

  /// Tipo de entidad (invoice, customer, product, etc.)
  late String entityType;

  /// ID de la entidad
  late String entityId;

  /// Tipo de operación (create, update, delete)
  late String operationType;

  /// Hash del payload (para detectar cambios)
  late String payloadHash;

  /// Timestamp de cuando se procesó la operación
  late DateTime processedAt;

  /// Resultado de la operación (success, failed, pending)
  late String status;

  /// ID del servidor (si la operación creó una entidad nueva)
  String? serverId;

  /// Mensaje de error (si falló)
  String? errorMessage;

  /// Timestamp de expiración (para cleanup automático)
  late DateTime expiresAt;

  IsarIdempotencyRecord();

  /// Constructor para crear nuevo registro
  factory IsarIdempotencyRecord.create({
    required String idempotencyKey,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadHash,
  }) {
    return IsarIdempotencyRecord()
      ..idempotencyKey = idempotencyKey
      ..entityType = entityType
      ..entityId = entityId
      ..operationType = operationType
      ..payloadHash = payloadHash
      ..processedAt = DateTime.now()
      ..status = 'pending'
      ..expiresAt = DateTime.now().add(const Duration(days: 30)); // Expirar después de 30 días
  }

  /// Marcar como exitoso
  void markAsSuccess({String? serverId}) {
    status = 'success';
    this.serverId = serverId;
  }

  /// Marcar como fallido
  void markAsFailed(String error) {
    status = 'failed';
    errorMessage = error;
  }
}
```

#### 4.2 Agregar a IsarDatabase

**Archivo:** `lib/app/data/local/isar_database.dart`

```dart
// lib/app/data/local/isar_database.dart
import 'package:baudex_desktop/app/data/local/isar/models/isar_idempotency_record.dart';

class IsarDatabase {
  static Future<Isar> openIsar() async {
    return await Isar.open(
      [
        // ... colecciones existentes
        IsarInvoiceSchema,
        IsarCustomerSchema,
        // ... otras colecciones

        IsarIdempotencyRecordSchema, // ⭐ AGREGAR
      ],
      directory: path,
    );
  }
}
```

#### 4.3 Regenerar Código Isar

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

### PASO 5: Crear IdempotencyService (3-4 horas)

#### 5.1 Crear Archivo del Servicio

**Archivo:** `lib/app/core/services/idempotency_service.dart`

```dart
// lib/app/core/services/idempotency_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/isar/models/isar_idempotency_record.dart';
import 'package:isar/isar.dart';

/// Servicio para gestionar idempotencia de operaciones de sincronización
class IdempotencyService {
  final IsarDatabase isarDatabase;

  IdempotencyService({required this.isarDatabase});

  /// Genera clave de idempotencia para una operación
  ///
  /// Formato: {entityType}:{entityId}:{operationType}:{payloadHash}
  /// Ejemplo: "invoice:local-123:create:abc123def456"
  String generateIdempotencyKey({
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) {
    // 1. Crear hash del payload
    final payloadJson = json.encode(payload);
    final payloadHash = _hashPayload(payloadJson);

    // 2. Crear clave única
    final key = '$entityType:$entityId:$operationType:$payloadHash';

    return key;
  }

  /// Verifica si una operación ya fue procesada
  ///
  /// Returns:
  /// - null: Operación nueva, puede proceder
  /// - IsarIdempotencyRecord: Operación ya procesada, usar resultado existente
  Future<IsarIdempotencyRecord?> checkIfAlreadyProcessed(
    String idempotencyKey,
  ) async {
    final isar = isarDatabase.isar;

    final existing = await isar.isarIdempotencyRecords
        .filter()
        .idempotencyKeyEqualTo(idempotencyKey)
        .findFirst();

    return existing;
  }

  /// Registra una nueva operación (antes de ejecutar)
  Future<IsarIdempotencyRecord> recordOperation({
    required String idempotencyKey,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadHash,
  }) async {
    final isar = isarDatabase.isar;

    final record = IsarIdempotencyRecord.create(
      idempotencyKey: idempotencyKey,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payloadHash: payloadHash,
    );

    await isar.writeTxn(() async {
      await isar.isarIdempotencyRecords.put(record);
    });

    return record;
  }

  /// Marca operación como exitosa
  Future<void> markOperationAsSuccess(
    String idempotencyKey, {
    String? serverId,
  }) async {
    final isar = isarDatabase.isar;

    await isar.writeTxn(() async {
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record != null) {
        record.markAsSuccess(serverId: serverId);
        await isar.isarIdempotencyRecords.put(record);
      }
    });
  }

  /// Marca operación como fallida
  Future<void> markOperationAsFailed(
    String idempotencyKey,
    String error,
  ) async {
    final isar = isarDatabase.isar;

    await isar.writeTxn(() async {
      final record = await isar.isarIdempotencyRecords
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();

      if (record != null) {
        record.markAsFailed(error);
        await isar.isarIdempotencyRecords.put(record);
      }
    });
  }

  /// Limpia registros expirados (para mantenimiento)
  Future<int> cleanupExpiredRecords() async {
    final isar = isarDatabase.isar;

    int deletedCount = 0;

    await isar.writeTxn(() async {
      final expired = await isar.isarIdempotencyRecords
          .filter()
          .expiresAtLessThan(DateTime.now())
          .findAll();

      for (final record in expired) {
        await isar.isarIdempotencyRecords.delete(record.id);
        deletedCount++;
      }
    });

    print('🧹 Cleaned up $deletedCount expired idempotency records');
    return deletedCount;
  }

  // Helper: Generar hash del payload
  String _hashPayload(String payload) {
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

#### 5.2 Agregar Dependencia crypto

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  # ... dependencias existentes
  crypto: ^3.0.3  # ⭐ AGREGAR
```

```bash
flutter pub get
```

#### 5.3 Registrar IdempotencyService en DI

**Archivo:** `lib/app/app_binding.dart`

```dart
import 'package:baudex_desktop/app/core/services/idempotency_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ... otros bindings

    // ⭐ AGREGAR: IdempotencyService
    Get.lazyPut<IdempotencyService>(
      () => IdempotencyService(
        isarDatabase: Get.find<IsarDatabase>(),
      ),
      fenix: true,
    );
  }
}
```

---

### PASO 6: Integrar Idempotencia en SyncService (3-4 horas)

#### 6.1 Modificar SyncService

**Archivo:** `lib/app/data/local/sync_service.dart`

**ANTES (método _syncCreateOperation - línea ~676):**

```dart
Future<void> _syncCreateOperation(SyncQueueItem item) async {
  try {
    switch (item.entityType) {
      case 'product':
        final productModel = ProductModel.fromJson(json.decode(item.payload));
        final result = await _productRepository.createProduct(productModel.toEntity());

        result.fold(
          (failure) => throw Exception(failure.message),
          (product) async {
            // Marcar como sincronizado
            await _markItemAsSynced(item.id);
          },
        );
        break;

      // ... otros casos
    }
  } catch (e) {
    // Error handling
  }
}
```

**DESPUÉS (con idempotencia):**

```dart
// ⭐ AGREGAR: Inyectar IdempotencyService
final IdempotencyService idempotencyService;

SyncService({
  required this.isarDatabase,
  // ... otros parámetros
  required this.idempotencyService, // ⭐ NUEVO
});

Future<void> _syncCreateOperation(SyncQueueItem item) async {
  try {
    // ⭐ PASO 1: Generar clave de idempotencia
    final payload = json.decode(item.payload) as Map<String, dynamic>;
    final idempotencyKey = idempotencyService.generateIdempotencyKey(
      entityType: item.entityType,
      entityId: item.entityId,
      operationType: 'create',
      payload: payload,
    );

    // ⭐ PASO 2: Verificar si ya fue procesado
    final existingRecord = await idempotencyService.checkIfAlreadyProcessed(
      idempotencyKey,
    );

    if (existingRecord != null && existingRecord.status == 'success') {
      // Ya fue procesado exitosamente → skip
      print('⏭️ Skipping duplicate operation: $idempotencyKey');
      await _markItemAsSynced(item.id);
      return;
    }

    // ⭐ PASO 3: Registrar operación (marca como "pending")
    if (existingRecord == null) {
      await idempotencyService.recordOperation(
        idempotencyKey: idempotencyKey,
        entityType: item.entityType,
        entityId: item.entityId,
        operationType: 'create',
        payloadHash: idempotencyService._hashPayload(item.payload),
      );
    }

    // ⭐ PASO 4: Ejecutar operación
    switch (item.entityType) {
      case 'product':
        final productModel = ProductModel.fromJson(payload);
        final result = await _productRepository.createProduct(productModel.toEntity());

        result.fold(
          (failure) async {
            // ⭐ PASO 5a: Marcar como fallido
            await idempotencyService.markOperationAsFailed(
              idempotencyKey,
              failure.message,
            );
            throw Exception(failure.message);
          },
          (product) async {
            // ⭐ PASO 5b: Marcar como exitoso
            await idempotencyService.markOperationAsSuccess(
              idempotencyKey,
              serverId: product.id,
            );

            // Marcar sync queue item como sincronizado
            await _markItemAsSynced(item.id);
          },
        );
        break;

      // ... otros casos (aplicar mismo patrón)
    }
  } catch (e) {
    // Error handling
  }
}
```

#### 6.2 Aplicar Patrón a Todas las Operaciones

**Métodos a modificar en SyncService:**

- [ ] `_syncCreateOperation()` - Para operaciones CREATE
- [ ] `_syncUpdateOperation()` - Para operaciones UPDATE
- [ ] `_syncDeleteOperation()` - Para operaciones DELETE

**Para cada uno, aplicar el patrón:**

1. Generar `idempotencyKey`
2. Verificar si ya existe con `checkIfAlreadyProcessed()`
3. Si existe y es exitoso → skip
4. Si no existe → registrar con `recordOperation()`
5. Ejecutar operación
6. Marcar como exitoso con `markOperationAsSuccess()` o fallido con `markOperationAsFailed()`

---

## 🎯 PROBLEMA 3: PAYLOAD OBSOLETO

### Contexto del Problema

**Situación actual:**
- `SyncQueueItem` guarda snapshot del payload al momento de crearse
- Si entidad cambia DESPUÉS de agregar a queue PERO ANTES de sincronizar → se envía data vieja
- **Actualmente SOLO products lee data fresca de Isar antes de sincronizar**
- **16 módulos restantes envían payload obsoleto**

**Ejemplo real del problema:**
```dart
// Usuario crea factura INV-001 con total: $1000 (offline, 10:00 AM)
// Se agrega a SyncQueue con payload: {total: 1000}
// Usuario edita factura INV-001 → total: $1500 (offline, 10:05 AM)
// Se actualiza en Isar → total ahora es $1500
// Sincronización ocurre a las 11:00 AM
// PROBLEMA: SyncService envía payload obsoleto {total: 1000} en lugar de leer Isar
// Servidor guarda factura con total incorrecto: $1000
```

### Solución: Leer Datos Frescos de Isar Antes de Sincronizar

---

## 📅 SEMANA 3: CORREGIR PAYLOAD OBSOLETO

### PASO 7: Implementar _getCurrentDataFromIsar() Genérico (3-4 horas)

#### 7.1 Modificar SyncService

**Archivo:** `lib/app/data/local/sync_service.dart`

**Agregar método helper genérico:**

```dart
// ⭐ NUEVO MÉTODO: Obtener datos actuales de Isar antes de sincronizar
Future<Map<String, dynamic>?> _getCurrentDataFromIsar({
  required String entityType,
  required String entityId,
}) async {
  final isar = isarDatabase.isar;

  try {
    switch (entityType) {
      case 'product':
        final product = await isar.isarProducts
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (product == null) return null;

        return ProductModel.fromIsarProduct(product).toJson();

      case 'invoice':
        final invoice = await isar.isarInvoices
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (invoice == null) return null;

        return InvoiceModel.fromIsarInvoice(invoice).toJson();

      case 'customer':
        final customer = await isar.isarCustomers
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (customer == null) return null;

        return CustomerModel.fromIsarCustomer(customer).toJson();

      case 'category':
        final category = await isar.isarCategories
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (category == null) return null;

        return CategoryModel.fromIsarCategory(category).toJson();

      case 'credit_note':
        final creditNote = await isar.isarCreditNotes
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (creditNote == null) return null;

        return CreditNoteModel.fromIsarCreditNote(creditNote).toJson();

      case 'customer_credit':
        final customerCredit = await isar.isarCustomerCredits
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (customerCredit == null) return null;

        return CustomerCreditModel.fromIsarCustomerCredit(customerCredit).toJson();

      case 'bank_account':
        final bankAccount = await isar.isarBankAccounts
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (bankAccount == null) return null;

        return BankAccountModel.fromIsarBankAccount(bankAccount).toJson();

      case 'expense':
        final expense = await isar.isarExpenses
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (expense == null) return null;

        return ExpenseModel.fromIsarExpense(expense).toJson();

      case 'inventory_item':
        final inventoryItem = await isar.isarInventoryItems
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (inventoryItem == null) return null;

        return InventoryItemModel.fromIsarInventoryItem(inventoryItem).toJson();

      case 'purchase_order':
        final purchaseOrder = await isar.isarPurchaseOrders
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (purchaseOrder == null) return null;

        return PurchaseOrderModel.fromIsarPurchaseOrder(purchaseOrder).toJson();

      case 'supplier':
        final supplier = await isar.isarSuppliers
            .filter()
            .serverIdEqualTo(entityId)
            .findFirst();

        if (supplier == null) return null;

        return SupplierModel.fromIsarSupplier(supplier).toJson();

      // ⭐ AGREGAR casos para los 6 módulos restantes:
      // - notification
      // - report
      // - setting
      // - warehouse
      // - organization
      // - user

      default:
        print('⚠️ Entity type not supported: $entityType');
        return null;
    }
  } catch (e) {
    print('❌ Error getting current data from Isar for $entityType [$entityId]: $e');
    return null;
  }
}
```

#### 7.2 Usar _getCurrentDataFromIsar en Operaciones

**Modificar _syncCreateOperation, _syncUpdateOperation, _syncDeleteOperation:**

```dart
Future<void> _syncCreateOperation(SyncQueueItem item) async {
  try {
    // ⭐ LEER DATOS ACTUALES DE ISAR (no usar item.payload obsoleto)
    final currentPayload = await _getCurrentDataFromIsar(
      entityType: item.entityType,
      entityId: item.entityId,
    );

    // Si no existe en Isar → entidad fue eliminada, skip sync
    if (currentPayload == null) {
      print('⏭️ Skipping sync for deleted entity: ${item.entityType} [${item.entityId}]');
      await _removeFromQueue(item.id);
      return;
    }

    // Generar idempotency key con payload ACTUAL
    final idempotencyKey = idempotencyService.generateIdempotencyKey(
      entityType: item.entityType,
      entityId: item.entityId,
      operationType: 'create',
      payload: currentPayload, // ⭐ Usar payload fresco
    );

    // ... resto del código (verificar idempotencia, ejecutar operación)

    switch (item.entityType) {
      case 'product':
        final productModel = ProductModel.fromJson(currentPayload); // ⭐ Usar payload fresco
        // ... resto del código
        break;

      // ... otros casos
    }
  } catch (e) {
    // Error handling
  }
}
```

**Aplicar mismo patrón a:**
- `_syncUpdateOperation()`
- `_syncDeleteOperation()`

---

## ✅ PASO 8: TESTING Y VALIDACIÓN (2-3 horas)

### 8.1 Crear Tests Unitarios

**Crear archivo de test para ConflictResolver:**

`test/unit/core/services/conflict_resolver_test.dart`

```dart
import 'package:baudex_desktop/app/core/services/conflict_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ConflictResolver conflictResolver;

  setUp(() {
    conflictResolver = ConflictResolver();
  });

  group('ConflictResolver - serverWins strategy', () {
    test('should return server data when conflict detected', () async {
      // Arrange
      final localData = TestEntity(version: 1, data: 'local');
      final serverData = TestEntity(version: 1, data: 'server');

      // Act
      final resolution = await conflictResolver.resolveConflict<TestEntity>(
        localData: localData,
        serverData: serverData,
        strategy: ConflictResolutionStrategy.serverWins,
        entityName: 'TestEntity',
        hasConflictCheck: (local, server) => local.version >= server.version,
        getVersion: (data) => data.version,
        getLastModifiedAt: (data) => data.lastModifiedAt,
      );

      // Assert
      expect(resolution.hasConflict, true);
      expect(resolution.resolvedData?.data, 'server');
    });
  });

  group('ConflictResolver - newerWins strategy', () {
    test('should return newer data based on timestamp', () async {
      // Arrange
      final oldTime = DateTime.now().subtract(Duration(hours: 1));
      final newTime = DateTime.now();

      final localData = TestEntity(version: 1, data: 'local', lastModifiedAt: newTime);
      final serverData = TestEntity(version: 1, data: 'server', lastModifiedAt: oldTime);

      // Act
      final resolution = await conflictResolver.resolveConflict<TestEntity>(
        localData: localData,
        serverData: serverData,
        strategy: ConflictResolutionStrategy.newerWins,
        entityName: 'TestEntity',
        hasConflictCheck: (local, server) => local.version >= server.version,
        getVersion: (data) => data.version,
        getLastModifiedAt: (data) => data.lastModifiedAt,
      );

      // Assert
      expect(resolution.hasConflict, true);
      expect(resolution.resolvedData?.data, 'local'); // Local is newer
    });
  });
}

class TestEntity {
  final int version;
  final String data;
  final DateTime? lastModifiedAt;

  TestEntity({
    required this.version,
    required this.data,
    this.lastModifiedAt,
  });
}
```

**Crear archivo de test para IdempotencyService:**

`test/unit/core/services/idempotency_service_test.dart`

```dart
import 'package:baudex_desktop/app/core/services/idempotency_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IdempotencyService idempotencyService;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsarDatabase = MockIsarDatabase();
    idempotencyService = IdempotencyService(
      isarDatabase: mockIsarDatabase,
    );
  });

  group('IdempotencyService - generateIdempotencyKey', () {
    test('should generate consistent key for same payload', () {
      // Arrange
      final payload1 = {'id': '123', 'total': 1000};
      final payload2 = {'id': '123', 'total': 1000};

      // Act
      final key1 = idempotencyService.generateIdempotencyKey(
        entityType: 'invoice',
        entityId: 'inv-001',
        operationType: 'create',
        payload: payload1,
      );

      final key2 = idempotencyService.generateIdempotencyKey(
        entityType: 'invoice',
        entityId: 'inv-001',
        operationType: 'create',
        payload: payload2,
      );

      // Assert
      expect(key1, equals(key2));
    });

    test('should generate different key for different payload', () {
      // Arrange
      final payload1 = {'id': '123', 'total': 1000};
      final payload2 = {'id': '123', 'total': 2000}; // Different total

      // Act
      final key1 = idempotencyService.generateIdempotencyKey(
        entityType: 'invoice',
        entityId: 'inv-001',
        operationType: 'create',
        payload: payload1,
      );

      final key2 = idempotencyService.generateIdempotencyKey(
        entityType: 'invoice',
        entityId: 'inv-001',
        operationType: 'create',
        payload: payload2,
      );

      // Assert
      expect(key1, isNot(equals(key2)));
    });
  });
}
```

### 8.2 Tests de Integración

**Escenario de prueba manual:**

```dart
// 1. Crear factura offline
// 2. Modificar factura ANTES de sincronizar
// 3. Forzar sincronización
// 4. Verificar que se envíe versión actualizada (no obsoleta)
// 5. Intentar re-sincronizar mismo item
// 6. Verificar que no se cree duplicado (idempotencia)
```

### 8.3 Checklist de Validación Final

**Antes de pasar a producción:**

- [ ] Todos los tests unitarios pasan (`flutter test`)
- [ ] Code generation completado sin errores (`dart run build_runner build`)
- [ ] Análisis estático sin warnings críticos (`flutter analyze`)
- [ ] 17 modelos Isar tienen campos de versionamiento
- [ ] 17 repositorios integran ConflictResolver
- [ ] SyncService usa IdempotencyService
- [ ] SyncService lee datos frescos de Isar (no payload obsoleto)
- [ ] Probado manualmente:
  - [ ] Conflictos se detectan correctamente
  - [ ] Idempotencia previene duplicados
  - [ ] Cambios recientes se sincronizan (no versiones obsoletas)

---

## 📊 MÉTRICAS DE ÉXITO

### Indicadores de que la Fase 1 está completa:

1. **Detección de Conflictos:**
   - [ ] Log `⚠️ CONFLICT DETECTED` aparece cuando hay conflictos reales
   - [ ] No hay sobrescritura silenciosa de datos

2. **Idempotencia:**
   - [ ] Log `⏭️ Skipping duplicate operation` aparece para operaciones duplicadas
   - [ ] No se crean registros duplicados en servidor

3. **Payload Fresco:**
   - [ ] Cambios recientes se reflejan en sincronización
   - [ ] No se envían datos obsoletos al servidor

4. **Performance:**
   - [ ] Sincronización no es significativamente más lenta
   - [ ] No hay aumento dramático en uso de espacio (Isar)

---

## 🚀 SIGUIENTE PASO: FASE 2

**Una vez completada Fase 1, continuar con:**

- **Fase 2:** Abstracción de Capa Isar (16-20 horas)
- **Fase 3:** Métricas y Telemetría (8-10 horas)

---

## 📞 SOPORTE Y PREGUNTAS

Si durante la implementación surgen dudas:

1. **Revisar ejemplos de código** en productos (ya tienen partial implementation)
2. **Consultar documentación de Isar**: https://isar.dev
3. **Pedir asistencia** si hay bloqueos técnicos

---

## ✅ CONCLUSIÓN

Este plan te guía paso a paso para resolver los **3 problemas más críticos** del sistema de sincronización:

1. ✅ Conflictos detectados y resueltos
2. ✅ Operaciones idempotentes (sin duplicados)
3. ✅ Datos siempre frescos (no obsoletos)

**Tiempo total estimado:** 24-30 horas
**Prioridad:** CRÍTICA - Previene pérdida de datos
**Resultado esperado:** Sistema de sincronización robusto y confiable

---

**¿Listo para comenzar? Empieza con el PASO 1 y avanza secuencialmente.**
