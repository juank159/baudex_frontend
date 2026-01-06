# PLAN DE ACCIÓN MAESTRO: Implementación Offline-First CRUD en Todos los Módulos

**Fecha de Creación:** 2025-12-28
**Objetivo:** Implementar el patrón offline-first completo (CREATE, READ, UPDATE, DELETE) en todos los módulos del sistema para garantizar operación continua online y offline.

---

## 📋 RESUMEN EJECUTIVO

**Total de Módulos:** 17
**Estado Actual:**
- ✅ **Completados (3):** Products, Customers, Expenses
- 🔄 **En Progreso (0):** -
- ⏳ **Pendientes (14):** Todos los demás

**Patrón de Referencia:** Products (`product_repository_impl.dart`)
**Tiempo Estimado Total:** 8-10 horas de trabajo enfocado
**Prioridad:** CRÍTICA - Afecta la usabilidad offline de toda la aplicación

---

## 🎯 OBJETIVOS ESPECÍFICOS

### 1. Análisis y Documentación
- [x] Identificar todos los repositorios del proyecto
- [ ] Analizar estado actual de cada módulo
- [ ] Documentar patrón correcto basado en Products
- [ ] Crear checklist de verificación por módulo

### 2. Implementación Sistemática
- [ ] Aplicar patrón a módulos de alta prioridad (Invoices, Categories, BankAccounts)
- [ ] Aplicar patrón a módulos de prioridad media
- [ ] Aplicar patrón a módulos de prioridad baja

### 3. Calidad y Verificación
- [ ] Testing offline de cada módulo modificado
- [ ] Verificación de sincronización automática
- [ ] Documentación de logs y comportamiento

---

## 📊 INVENTARIO COMPLETO DE MÓDULOS

### Módulos CRÍTICOS (Uso Diario - Prioridad 1)

| # | Módulo | Archivo | Estado | Prioridad | Estimado |
|---|--------|---------|--------|-----------|----------|
| 1 | **Invoices** | `invoice_repository_impl.dart` | ⏳ Pendiente | 🔴 MUY ALTA | 2h |
| 2 | **Categories** | `category_repository_impl.dart` | ⏳ Pendiente | 🔴 MUY ALTA | 1.5h |
| 3 | **Bank Accounts** | `bank_account_repository_impl.dart` | ⏳ Pendiente | 🔴 ALTA | 1.5h |
| 4 | **Suppliers** | `supplier_repository_impl.dart` | ⏳ Pendiente | 🔴 ALTA | 1.5h |

**Subtotal Prioridad 1:** 6.5 horas

### Módulos IMPORTANTES (Uso Frecuente - Prioridad 2)

| # | Módulo | Archivo | Estado | Prioridad | Estimado |
|---|--------|---------|--------|-----------|----------|
| 5 | **Credit Notes** | `credit_note_repository_impl.dart` | ⏳ Pendiente | 🟡 MEDIA | 1h |
| 6 | **Customer Credits** | `customer_credit_repository_impl.dart` | ⏳ Pendiente | 🟡 MEDIA | 1h |
| 7 | **Purchase Orders** | `purchase_order_repository_impl.dart` | ⏳ Pendiente | 🟡 MEDIA | 1h |
| 8 | **Inventory** | `inventory_repository_impl.dart` | ⏳ Pendiente | 🟡 MEDIA | 1h |

**Subtotal Prioridad 2:** 4 horas

### Módulos de SOPORTE (Uso Ocasional - Prioridad 3)

| # | Módulo | Archivo | Estado | Prioridad | Estimado |
|---|--------|---------|--------|-----------|----------|
| 9 | **Reports** | `reports_repository_impl.dart` | ⏳ Pendiente | 🟢 BAJA | 30min |
| 10 | **Organization** | `organization_repository_impl.dart` | ⏳ Pendiente | 🟢 BAJA | 30min |
| 11 | **User Preferences** | `user_preferences_repository_impl.dart` | ⏳ Pendiente | 🟢 BAJA | 30min |
| 12 | **Settings** | `settings_repository_impl.dart` | ⏳ Pendiente | 🟢 BAJA | 30min |

**Subtotal Prioridad 3:** 2 horas

### Módulos EXCLUIDOS (No Requieren Offline)

| # | Módulo | Archivo | Razón | Acción |
|---|--------|---------|-------|--------|
| 13 | **Auth** | `auth_repository_impl.dart` | Login/Logout requiere servidor | ✅ Excluir |
| 14 | **Dashboard** | `dashboard_repository_impl.dart` | Solo lectura, ya implementado | ✅ Completado |

---

## 🔍 ANÁLISIS DEL PATRÓN CORRECTO

### Patrón de Referencia: Products

**Archivo:** `/Users/mac/Documents/baudex/frontend/lib/features/products/data/repositories/product_repository_impl.dart`

#### Estructura Completa de Operaciones CRUD:

```dart
// ==================== CREATE ====================
Future<Either<Failure, Product>> createProduct(...) async {
  if (await networkInfo.isConnected) {
    try {
      final response = await remoteDataSource.createProduct(request);
      await localDataSource.cacheProduct(response);
      // Cachear en ISAR
      await _cacheInIsar(response);
      return Right(response);
    } on ServerException catch (e) {
      return _createProductOffline(...); // FALLBACK
    } on ConnectionException catch (e) {
      return _createProductOffline(...); // FALLBACK
    } catch (e) {
      return _createProductOffline(...); // FALLBACK
    }
  } else {
    return _createProductOffline(...); // OFFLINE DIRECTO
  }
}

// ==================== READ ====================
Future<Either<Failure, PaginatedResult<Product>>> getProducts(...) async {
  if (await networkInfo.isConnected) {
    try {
      final response = await remoteDataSource.getProducts(query);
      // Cachear en ISAR + SecureStorage
      await localDataSource.cacheProducts(response.data);
      await _cacheInIsar(response.data);
      return Right(response);
    } on ServerException catch (e) {
      return _getProductsFromCache(); // FALLBACK
    } catch (e) {
      return _getProductsFromCache(); // FALLBACK
    }
  } else {
    return _getProductsFromCache(); // OFFLINE DIRECTO
  }
}

// ==================== UPDATE ====================
Future<Either<Failure, Product>> updateProduct({
  required String id,
  ...
}) async {
  // DETECTAR SI ES PRODUCTO OFFLINE
  if (id.startsWith('product_offline_')) {
    return _updateProductOffline(...); // SOLO LOCAL
  }

  if (await networkInfo.isConnected) {
    try {
      final response = await remoteDataSource.updateProduct(id, request);
      await localDataSource.cacheProduct(response);
      // Actualizar ISAR
      await _updateInIsar(response);
      return Right(response);
    } on ServerException catch (e) {
      return _updateProductOffline(...); // FALLBACK
    } catch (e) {
      return _updateProductOffline(...); // FALLBACK
    }
  } else {
    return _updateProductOffline(...); // OFFLINE DIRECTO
  }
}

// ==================== DELETE ====================
Future<Either<Failure, Unit>> deleteProduct(String id) async {
  if (await networkInfo.isConnected) {
    try {
      await remoteDataSource.deleteProduct(id);
      // Soft delete en ISAR
      await _softDeleteInIsar(id);
      await localDataSource.removeCachedProduct(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return _deleteProductOffline(id); // FALLBACK
    } catch (e) {
      return _deleteProductOffline(id); // FALLBACK
    }
  } else {
    return _deleteProductOffline(id); // OFFLINE DIRECTO
  }
}

// ==================== MÉTODOS OFFLINE PRIVADOS ====================

Future<Either<Failure, Product>> _createProductOffline(...) async {
  final tempId = 'product_offline_${DateTime.now().millisecondsSinceEpoch}';

  // 1. Crear en ISAR
  final isarProduct = IsarProduct.create(..., serverId: tempId, isSynced: false);
  await isar.writeTxn(() => isar.isarProducts.put(isarProduct));

  // 2. Cachear en SecureStorage
  await localDataSource.cacheProduct(productModel);

  // 3. Agregar a cola de sincronización
  await syncService.addOperationForCurrentUser(
    entityType: 'Product',
    entityId: tempId,
    operationType: SyncOperationType.create,
    data: {...},
    priority: 1,
  );

  return Right(product);
}

Future<Either<Failure, Product>> _updateProductOffline(...) async {
  final isOfflineProduct = id.startsWith('product_offline_');

  // 1. Actualizar en ISAR
  final isarProduct = await isar.isarProducts.filter().serverIdEqualTo(id).findFirst();
  // Actualizar campos...
  isarProduct.markAsUnsynced();
  await isar.writeTxn(() => isar.isarProducts.put(isarProduct));

  // 2. Actualizar SecureStorage
  await localDataSource.cacheProduct(updatedModel);

  // 3. Agregar a cola de sincronización (SOLO si ya estaba sincronizado)
  if (!isOfflineProduct || wasAlreadySynced) {
    await syncService.addOperationForCurrentUser(
      entityType: 'Product',
      entityId: id,
      operationType: SyncOperationType.update,
      data: {...},
      priority: 1,
    );
  }

  return Right(product);
}

Future<Either<Failure, Unit>> _deleteProductOffline(String id) async {
  // 1. Soft delete en ISAR
  final isarProduct = await isar.isarProducts.filter().serverIdEqualTo(id).findFirst();
  isarProduct.softDelete();
  await isar.writeTxn(() => isar.isarProducts.put(isarProduct));

  // 2. Remover de SecureStorage
  await localDataSource.removeCachedProduct(id);

  // 3. Agregar a cola de sincronización
  await syncService.addOperationForCurrentUser(
    entityType: 'Product',
    entityId: id,
    operationType: SyncOperationType.delete,
    data: {'id': id},
    priority: 1,
  );

  return const Right(unit);
}

Future<Either<Failure, PaginatedResult<Product>>> _getProductsFromCache() async {
  // 1. Intentar ISAR primero
  final isarProducts = await isar.isarProducts
    .filter()
    .deletedAtIsNull()
    .sortByCreatedAtDesc()
    .findAll();

  if (isarProducts.isNotEmpty) {
    return Right(PaginatedResult(data: isarProducts.map((e) => e.toEntity()).toList()));
  }

  // 2. Fallback a SecureStorage
  final cachedProducts = await localDataSource.getCachedProducts();
  return Right(PaginatedResult(data: cachedProducts.map((e) => e.toEntity()).toList()));
}
```

### Componentes Clave del Patrón:

#### 1. **Detección de Entidades Offline**
```dart
final isOfflineEntity = id.startsWith('entity_offline_');
```

#### 2. **Generación de IDs Temporales**
```dart
final tempId = 'entity_offline_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}';
```

#### 3. **Marcadores de Sincronización en ISAR**
```dart
isarEntity.markAsUnsynced();  // Marca isSynced = false
isarEntity.markAsSynced();    // Marca isSynced = true
isarEntity.softDelete();      // Marca deletedAt = DateTime.now()
```

#### 4. **Cola de Sincronización**
```dart
await syncService.addOperationForCurrentUser(
  entityType: 'EntityName',     // Tipo de entidad
  entityId: id,                 // ID (puede ser temporal o real)
  operationType: SyncOperationType.create | update | delete,
  data: {...},                  // Payload para enviar al servidor
  priority: 1,                  // Alta prioridad
);
```

#### 5. **Cacheo Dual (ISAR + SecureStorage)**
```dart
// ISAR: Base de datos local NoSQL (primaria)
await isar.writeTxn(() => isar.isarEntities.put(isarEntity));

// SecureStorage: Almacenamiento encriptado (fallback)
await localDataSource.cacheEntity(entityModel);
```

---

## 📝 CHECKLIST DE IMPLEMENTACIÓN POR MÓDULO

Para cada módulo, verificar que tenga implementado:

### CREATE (Crear)
- [ ] Try-catch con fallback a `_createEntityOffline()` en online mode
- [ ] Método privado `_createEntityOffline()` implementado
- [ ] Generación de ID temporal con prefijo `entity_offline_`
- [ ] Guardado en ISAR con `isSynced = false`
- [ ] Guardado en SecureStorage
- [ ] Agregado a cola de sincronización con `SyncOperationType.create`
- [ ] Logs detallados de operación offline

### READ (Leer)
- [ ] Try-catch con fallback a `_getEntitiesFromCache()` en online mode
- [ ] Método privado `_getEntitiesFromCache()` implementado
- [ ] Intenta ISAR primero, luego SecureStorage
- [ ] Cacheo en ISAR cuando carga del servidor
- [ ] Cacheo en SecureStorage cuando carga del servidor
- [ ] Logs detallados de fallback

### UPDATE (Actualizar)
- [ ] Detección de entidades offline vs servidor (`id.startsWith('entity_offline_')`)
- [ ] Try-catch con fallback a `_updateEntityOffline()` en online mode
- [ ] Método privado `_updateEntityOffline()` implementado
- [ ] Actualización en ISAR con `markAsUnsynced()`
- [ ] Actualización en SecureStorage
- [ ] Agregado a cola SOLO si ya estaba sincronizado
- [ ] Logs detallados de operación offline

### DELETE (Eliminar)
- [ ] Try-catch con fallback a `_deleteEntityOffline()` en online mode
- [ ] Método privado `_deleteEntityOffline()` implementado
- [ ] Soft delete en ISAR (`softDelete()`)
- [ ] Remoción de SecureStorage
- [ ] Agregado a cola de sincronización con `SyncOperationType.delete`
- [ ] Logs detallados de operación offline

### GENERAL
- [ ] Imports necesarios (IsarDatabase, SyncService, SyncQueue, enums)
- [ ] Métodos helper de mapeo (si usa ISAR con enums)
- [ ] Manejo correcto de errores con Either<Failure, Success>
- [ ] Compilación sin errores
- [ ] Testing en 3 escenarios (online OK, online fail, offline)

---

## 🤖 ESTRATEGIA CON AGENTES ESPECIALIZADOS

### Agente 1: Analyzer Agent
**Responsabilidad:** Analizar estado actual de cada módulo
**Tareas:**
1. Leer archivo completo del repositorio
2. Identificar métodos CRUD existentes
3. Verificar si tiene fallback offline
4. Identificar métodos faltantes
5. Generar reporte de estado

**Prompt para Agente:**
```
Analiza el repositorio {module}_repository_impl.dart y genera un reporte con:
1. Métodos CRUD encontrados (create, read, update, delete)
2. Para cada método, indica si tiene:
   - Try-catch con fallback offline
   - Método privado offline implementado
   - Cacheo en ISAR
   - Agregado a cola de sincronización
3. Lista de métodos faltantes o incompletos
4. Recomendaciones de implementación
```

### Agente 2: Implementation Agent
**Responsabilidad:** Implementar patrón offline-first en un módulo
**Tareas:**
1. Recibir reporte del Analyzer Agent
2. Leer patrón de referencia (Products)
3. Implementar métodos privados offline (_createOffline, _updateOffline, _deleteOffline, _getFromCache)
4. Actualizar métodos públicos con fallback
5. Agregar imports necesarios
6. Verificar compilación

**Prompt para Agente:**
```
Implementa el patrón offline-first completo en {module}_repository_impl.dart siguiendo EXACTAMENTE el patrón de product_repository_impl.dart:

1. Para CREATE:
   - Agrega fallback a _create{Entity}Offline en todos los catch blocks
   - Implementa método _create{Entity}Offline con:
     * Generación de ID temporal
     * Guardado en ISAR con isSynced=false
     * Guardado en SecureStorage
     * Agregado a SyncQueue con priority=1

2. Para UPDATE:
   - Detecta si es entidad offline (id.startsWith('entity_offline_'))
   - Agrega fallback a _update{Entity}Offline en catch blocks
   - Implementa método _update{Entity}Offline con:
     * Actualización en ISAR + markAsUnsynced()
     * Actualización en SecureStorage
     * Agregado a SyncQueue SOLO si wasAlreadySynced

3. Para DELETE:
   - Agrega fallback a _delete{Entity}Offline en catch blocks
   - Implementa método _delete{Entity}Offline con:
     * Soft delete en ISAR
     * Remoción de SecureStorage
     * Agregado a SyncQueue

4. Para READ:
   - Agrega fallback a _get{Entities}FromCache en catch blocks
   - Implementa método _get{Entities}FromCache con:
     * Intenta ISAR primero
     * Fallback a SecureStorage
     * Paginación Dart-side

Verifica compilación con flutter analyze antes de finalizar.
```

### Agente 3: Verification Agent
**Responsabilidad:** Verificar implementación correcta
**Tareas:**
1. Ejecutar checklist de verificación
2. Compilar y verificar sin errores
3. Generar logs de prueba
4. Documentar resultados

**Prompt para Agente:**
```
Verifica la implementación offline-first en {module}_repository_impl.dart:

1. Ejecuta checklist completo (ver sección CHECKLIST arriba)
2. Verifica compilación: flutter analyze
3. Identifica warnings o errores
4. Genera reporte de verificación con:
   - Items completados ✅
   - Items faltantes ❌
   - Errores encontrados
   - Recomendaciones
```

---

## 📅 CRONOGRAMA DE IMPLEMENTACIÓN

### Fase 1: Módulos Críticos (Días 1-3)
**Objetivo:** Implementar offline-first en módulos de uso diario

| Día | Módulos | Agente | Estimado |
|-----|---------|--------|----------|
| 1 | Invoices | Implementation | 2h |
| 1 | Categories | Implementation | 1.5h |
| 2 | BankAccounts | Implementation | 1.5h |
| 2 | Suppliers | Implementation | 1.5h |
| 3 | Verification de Fase 1 | Verification | 1h |

**Total Fase 1:** 7.5 horas

### Fase 2: Módulos Importantes (Días 4-5)
**Objetivo:** Completar módulos de uso frecuente

| Día | Módulos | Agente | Estimado |
|-----|---------|--------|----------|
| 4 | Credit Notes + Customer Credits | Implementation | 2h |
| 4 | Purchase Orders | Implementation | 1h |
| 5 | Inventory | Implementation | 1h |
| 5 | Verification de Fase 2 | Verification | 30min |

**Total Fase 2:** 4.5 horas

### Fase 3: Módulos de Soporte (Día 6)
**Objetivo:** Completar módulos restantes

| Día | Módulos | Agente | Estimado |
|-----|---------|--------|----------|
| 6 | Reports + Organization + Preferences + Settings | Implementation | 2h |
| 6 | Verification Final | Verification | 30min |

**Total Fase 3:** 2.5 horas

### Fase 4: Testing y Documentación (Día 7)
**Objetivo:** Testing completo y documentación final

| Día | Actividad | Responsable | Estimado |
|-----|-----------|-------------|----------|
| 7 | Testing offline de todos los módulos | QA Manual | 3h |
| 7 | Actualización de documentación | Documentation | 1h |
| 7 | Creación de guías de uso | Documentation | 1h |

**Total Fase 4:** 5 horas

**TIEMPO TOTAL ESTIMADO:** 19.5 horas (~3 semanas a 1h/día o 2.5 días full-time)

---

## 🎯 MÉTRICAS DE ÉXITO

### Métricas Técnicas
- [ ] 100% de módulos con patrón offline-first implementado
- [ ] 0 errores de compilación
- [ ] 0 warnings críticos
- [ ] Cobertura de logs >= 90%

### Métricas Funcionales
- [ ] CREATE funciona offline en todos los módulos
- [ ] UPDATE funciona offline en todos los módulos
- [ ] DELETE funciona offline en todos los módulos
- [ ] READ funciona offline en todos los módulos
- [ ] Sincronización automática funciona correctamente

### Métricas de Usuario
- [ ] Usuario puede trabajar 100% offline
- [ ] Datos se sincronizan automáticamente al volver online
- [ ] No hay pérdida de datos
- [ ] Feedback inmediato en todas las operaciones

---

## 📚 DOCUMENTACIÓN GENERADA

### Durante Implementación
1. **Reporte de Análisis por Módulo** (`ANALISIS_{MODULE}.md`)
2. **Reporte de Implementación por Módulo** (`IMPLEMENTATION_{MODULE}.md`)
3. **Reporte de Verificación por Módulo** (`VERIFICATION_{MODULE}.md`)

### Al Final
4. **Guía del Patrón Offline-First** (`OFFLINE_FIRST_PATTERN_GUIDE.md`)
5. **Resumen Ejecutivo Final** (`OFFLINE_FIRST_SUMMARY.md`)
6. **Manual de Testing Offline** (`OFFLINE_TESTING_MANUAL.md`)

---

## 🚀 INICIO DE EJECUCIÓN

### Comando para Iniciar Fase 1
```bash
# Módulo: Invoices (Prioridad 1)
Agente: Implementation Agent
Prompt: "Implementa patrón offline-first CRUD completo en invoice_repository_impl.dart"
```

### Orden de Ejecución Recomendado
1. **Invoices** (más complejo, mayor impacto)
2. **Categories** (usado por múltiples módulos)
3. **BankAccounts** (crítico para finanzas)
4. **Suppliers** (crítico para compras)
5. Resto según cronograma

---

## ⚠️ CONSIDERACIONES IMPORTANTES

### Riesgos Identificados
1. **Complejidad de Invoices:** Tiene línea de items, requiere manejo especial
2. **Dependencias entre módulos:** Categories usado por Products/Expenses
3. **Sincronización de relaciones:** Productos con categorías, facturas con clientes
4. **Conflictos de sync:** Ediciones simultáneas online/offline

### Mitigaciones
1. Implementar en orden de complejidad (simple → complejo)
2. Testing exhaustivo de cada módulo antes de continuar
3. Logs detallados para debugging
4. Documentación clara de casos edge

---

## ✅ APROBACIÓN Y PRÓXIMOS PASOS

**Este plan debe ser aprobado antes de iniciar la implementación.**

### Aprobación Requerida Para:
- [ ] Priorización de módulos
- [ ] Cronograma propuesto
- [ ] Uso de agentes especializados
- [ ] Estrategia de testing

### Próximos Pasos Inmediatos:
1. Aprobar este plan
2. Iniciar Fase 1 con Invoices
3. Ejecutar Implementation Agent
4. Verificar resultados
5. Continuar con siguiente módulo

---

**Preparado por:** Claude AI
**Revisión:** Pendiente
**Aprobación:** Pendiente
**Fecha Inicio Planeada:** Inmediata tras aprobación
