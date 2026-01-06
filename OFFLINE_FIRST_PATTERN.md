# Patrón Offline-First para Baudex

## Problema
Los módulos fallan cuando el servidor no está disponible, mostrando errores en lugar de cargar datos desde cache local (ISAR).

## Solución: Patrón Offline-First

### 1. Flujo Correcto

```
ONLINE (servidor disponible):
├─ Intenta cargar del servidor
├─ Si éxito: Cachea en ISAR + SecureStorage
└─ Retorna datos del servidor

ONLINE (servidor NO disponible):
├─ Intenta cargar del servidor
├─ Falla con Exception
├─ FALLBACK: Carga desde cache (ISAR primero, SecureStorage después)
└─ Retorna datos del cache

OFFLINE (sin conexión):
├─ Detecta sin internet
├─ Carga directamente desde cache
└─ Retorna datos del cache
```

### 2. Implementación en Repository

#### A. Método Principal (ej: getCustomers)

```dart
@override
Future<Either<Failure, PaginatedResult<Customer>>> getCustomers({
  int page = 1,
  int limit = 10,
  String? search,
  // ... otros parámetros
}) async {
  print('🔍 [REPO] getCustomers llamado - page=$page, limit=$limit');

  final isConnected = await networkInfo.isConnected;
  print('🔍 [REPO] Network connected: $isConnected');

  if (isConnected) {
    print('🌐 [REPO] ONLINE - Llamando remoteDataSource...');
    try {
      // 1. Intenta cargar del servidor
      final response = await remoteDataSource.getCustomers(query);

      // 2. IMPORTANTE: Cachea en ISAR + SecureStorage
      if (_shouldCacheResult(page, search, status)) {
        try {
          // Cachear en SecureStorage
          await localDataSource.cacheCustomers(response.data);

          // CRÍTICO: También cachear en ISAR
          print('💾 [REPO] Cacheando ${response.data.length} items en ISAR...');
          for (final item in response.data) {
            await updateInIsar(item.toEntity());
          }
          print('✅ [REPO] ${response.data.length} items cacheados');
        } catch (e) {
          print('⚠️ Error al cachear: $e');
        }
      }

      // 3. Retorna datos del servidor
      return Right(response.toPaginatedResult());

    } on ServerException catch (e) {
      // FALLBACK A CACHE cuando falla el servidor
      print('⚠️ [REPO] ServerException: ${e.message} - Intentando cache...');
      return _getFromCache();
    } on ConnectionException catch (e) {
      print('⚠️ [REPO] ConnectionException: ${e.message} - Intentando cache...');
      return _getFromCache();
    } catch (e) {
      // IMPORTANTE: CUALQUIER otro error también hace fallback
      print('⚠️ [REPO] Exception: $e - Intentando cache como fallback...');
      return _getFromCache();
    }
  } else {
    // Sin conexión - ir directo a cache
    print('📴 [REPO] OFFLINE - Cargando desde cache...');
    return _getFromCache();
  }
}
```

#### B. Método de Cache Fallback

```dart
Future<Either<Failure, PaginatedResult<T>>> _getFromCache() async {
  print('💾 [REPO] _getFromCache - Intentando ISAR primero...');
  try {
    // 1. ISAR primero (más rápido, soporta queries)
    final isarItems = await isar.isarItems
        .filter()
        .deletedAtIsNull()
        .sortByCreatedAtDesc()
        .findAll();

    if (isarItems.isNotEmpty) {
      print('💾 [REPO] ISAR tiene ${isarItems.length} items');
      final items = isarItems.map((i) => i.toEntity()).toList();

      return Right(
        PaginatedResult<T>(
          data: items,
          meta: PaginationMeta(
            page: 1,
            limit: items.length,
            totalItems: items.length,
            totalPages: 1,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ),
      );
    }

    // 2. Fallback a SecureStorage si ISAR vacío
    print('💾 [REPO] ISAR vacío, intentando SecureStorage...');
    final items = await localDataSource.getCached();
    print('💾 [REPO] SecureStorage tiene ${items.length} items');

    return Right(
      PaginatedResult<T>(
        data: items.map((m) => m.toEntity()).toList(),
        meta: PaginationMeta(
          page: 1,
          limit: items.length,
          totalItems: items.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ),
    );
  } catch (e) {
    print('❌ [REPO] Error en cache: $e');
    return Left(CacheFailure('Error al obtener desde cache: $e'));
  }
}
```

### 3. Checklist por Módulo

Para CADA módulo (Customers, Products, Invoices, Expenses, etc.):

- [ ] **Repository implementa fallback a cache en TODOS los catch blocks**
- [ ] **Datos del servidor se cachean en ISAR (no solo SecureStorage)**
- [ ] **Método _getFromCache usa ISAR como fuente principal**
- [ ] **Logs claros en cada paso del flujo**
- [ ] **Probado con servidor online**
- [ ] **Probado con servidor offline (Connection refused)**
- [ ] **Probado sin conexión a internet**

### 4. Módulos que NECESITAN este fix

1. ❌ **Dashboard** - Falla offline
2. ✅ **Customers** - FIXED
3. ❌ **Products** - Falla offline
4. ❌ **Invoices** - Falla offline
5. ❌ **Expenses** - Falla offline
6. ❌ **Categories** - Falla offline
7. ❌ **Bank Accounts** - Falla offline
8. ❌ **Notifications** - Falla offline
9. ❌ **Activities** - Falla offline

### 5. Errores Comunes a Evitar

❌ **MAL:** Retornar error cuando falla servidor
```dart
} catch (e) {
  return Left(UnknownFailure('Error: $e'));
}
```

✅ **BIEN:** Hacer fallback a cache
```dart
} catch (e) {
  print('⚠️ Error servidor - fallback a cache');
  return _getFromCache();
}
```

❌ **MAL:** Solo cachear en SecureStorage
```dart
await localDataSource.cache(data);
```

✅ **BIEN:** Cachear en ambos
```dart
await localDataSource.cache(data);
for (final item in data) {
  await updateInIsar(item.toEntity());
}
```

❌ **MAL:** Solo leer de SecureStorage en cache
```dart
final items = await localDataSource.getCached();
```

✅ **BIEN:** ISAR primero, SecureStorage fallback
```dart
final isarItems = await isar.items.findAll();
if (isarItems.isEmpty) {
  return await localDataSource.getCached();
}
```

### 6. Testing

Para cada módulo, probar estos 3 escenarios:

1. **Servidor Online y Disponible**
   - ✅ Debe cargar del servidor
   - ✅ Debe cachear en ISAR + SecureStorage
   - ✅ Datos visibles en la app

2. **Servidor Online pero NO Disponible** (puerto cerrado)
   - ✅ Intenta servidor, falla
   - ✅ Hace fallback a cache
   - ✅ Datos visibles desde cache

3. **Sin Conexión a Internet**
   - ✅ Detecta offline
   - ✅ Va directo a cache
   - ✅ Datos visibles desde cache

### 7. Logs Esperados

**Escenario Online exitoso:**
```
🔍 [REPO] Network connected: true
🌐 [REPO] ONLINE - Llamando remoteDataSource...
💾 [REPO] Cacheando 4 items en ISAR...
✅ [REPO] 4 items cacheados
```

**Escenario Offline con cache:**
```
🔍 [REPO] Network connected: true
🌐 [REPO] ONLINE - Llamando remoteDataSource...
⚠️ [REPO] Exception: Connection refused - Intentando cache como fallback...
💾 [REPO] _getFromCache - Intentando ISAR primero...
💾 [REPO] ISAR tiene 4 items
```

**Escenario Sin internet:**
```
🔍 [REPO] Network connected: false
📴 [REPO] OFFLINE - Cargando desde cache...
💾 [REPO] ISAR tiene 4 items
```
