# Guía de Implementación Offline-First Completa

## Estado Actual de la Implementación

### Modelos Isar Creados ✅
Todos los modelos Isar han sido creados y registrados:

1. **IsarBankAccount** (`lib/features/bank_accounts/data/models/isar/isar_bank_account.dart`)
2. **IsarSupplier** (`lib/features/suppliers/data/models/isar/isar_supplier.dart`)
3. **IsarPurchaseOrder** + **IsarPurchaseOrderItem** (`lib/features/purchase_orders/data/models/isar/`)
4. **IsarInventoryMovement** (`lib/features/inventory/data/models/isar/isar_inventory_movement.dart`)

### Modelos Isar Existentes ✅
- **IsarProduct** (ya existe, comentado)
- **IsarCustomer** (ya existe, comentado)
- **IsarExpense** (ya existe, comentado)
- **IsarCategory** (ya funciona)
- **IsarInvoice** (ya funciona)
- **IsarNotification** (ya funciona)

### Base de Datos Actualizada ✅
- `isar_database.dart` actualizado con todos los schemas
- `isar_enums.dart` actualizado con todos los enums necesarios
- Build runner ejecutado exitosamente

## Patrón de Repositorio Offline

Todos los repositorios siguen este patrón:

```dart
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../domain/entities/[entity].dart';
import '../../domain/repositories/[entity]_repository.dart';
import '../models/isar/isar_[entity].dart';
import '../../../../app/data/local/enums/isar_enums.dart';

class [Entity]OfflineRepository implements [Entity]Repository {
  final IsarDatabase _database;

  [Entity]OfflineRepository({IsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<[Entity]>>> get[Entities](...) async {
    try {
      // 1. Build filter query
      var filterQuery = _isar.isar[Entities].filter().deletedAtIsNull();

      // 2. Apply filters (search, status, etc.)
      if (search != null && search.isNotEmpty) {
        filterQuery = filterQuery.and().nameContains(search, caseSensitive: false);
      }

      // 3. Get total count
      final totalItems = await filterQuery.count();

      // 4. Apply sorting and pagination
      final offset = (page - 1) * limit;
      final isar[Entities] = await filterQuery
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();

      // 5. Convert to domain entities
      final [entities] = isar[Entities].map((isar) => isar.toEntity()).toList();

      // 6. Build pagination meta
      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: [entities], meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading [entities]: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, [Entity]>> get[Entity]ById(String id) async {
    try {
      final isar[Entity] = await _isar.isar[Entities]
        .filter()
        .serverIdEqualTo(id)
        .and()
        .deletedAtIsNull()
        .findFirst();

      if (isar[Entity] == null) {
        return Left(CacheFailure('[Entity] not found'));
      }

      return Right(isar[Entity].toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading [entity]: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<[Entity]>>> search[Entities](String searchTerm) async {
    try {
      final isar[Entities] = await _isar.isar[Entities]
        .filter()
        .nameContains(searchTerm, caseSensitive: false)
        .and()
        .deletedAtIsNull()
        .sortByName()
        .limit(10)
        .findAll();

      final [entities] = isar[Entities].map((isar) => isar.toEntity()).toList();
      return Right([entities]);
    } catch (e) {
      return Left(CacheFailure('Error searching [entities]: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, [Entity]>> create[Entity](...) async {
    try {
      final now = DateTime.now();
      final serverId = '[entity]_${now.millisecondsSinceEpoch}_${name.hashCode}';

      final isar[Entity] = Isar[Entity].create(
        serverId: serverId,
        name: name,
        // ... otros campos
        createdAt: now,
        updatedAt: now,
        isSynced: false, // Mark as unsynced for later upload
      );

      await _isar.writeTxn(() async {
        await _isar.isar[Entities].put(isar[Entity]);
      });

      return Right(isar[Entity].toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating [entity]: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, [Entity]>> update[Entity](...) async {
    try {
      final isar[Entity] = await _isar.isar[Entities]
        .filter()
        .serverIdEqualTo(id)
        .findFirst();

      if (isar[Entity] == null) {
        return Left(CacheFailure('[Entity] not found'));
      }

      // Update fields
      if (name != null) isar[Entity].name = name;
      // ... otros campos

      isar[Entity].markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isar[Entities].put(isar[Entity]);
      });

      return Right(isar[Entity].toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating [entity]: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> delete[Entity](String id) async {
    try {
      final isar[Entity] = await _isar.isar[Entities]
        .filter()
        .serverIdEqualTo(id)
        .findFirst();

      if (isar[Entity] == null) {
        return Left(CacheFailure('[Entity] not found'));
      }

      // Soft delete
      isar[Entity].softDelete();

      await _isar.writeTxn(() async {
        await _isar.isar[Entities].put(isar[Entity]);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting [entity]: ${e.toString()}'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<[Entity]>>> getUnsynced[Entities]() async {
    try {
      final isar[Entities] = await _isar.isar[Entities]
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

      final [entities] = isar[Entities].map((isar) => isar.toEntity()).toList();
      return Right([entities]);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced [entities]: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> mark[Entities]AsSynced(List<String> [entity]Ids) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in [entity]Ids) {
          final isar[Entity] = await _isar.isar[Entities]
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

          if (isar[Entity] != null) {
            isar[Entity].markAsSynced();
            await _isar.isar[Entities].put(isar[Entity]);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking [entities] as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> bulkInsert[Entities](List<[Entity]> [entities]) async {
    try {
      final isar[Entities] = [entities]
        .map((entity) => Isar[Entity].fromEntity(entity))
        .toList();

      await _isar.writeTxn(() async {
        await _isar.isar[Entities].putAll(isar[Entities]);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting [entities]: ${e.toString()}'));
    }
  }
}
```

## Repositorios a Implementar

### 1. ProductOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/products/data/repositories/product_offline_repository.dart`
**Patrón:** Seguir CategoryOfflineRepository
**Operaciones principales:**
- getProducts (paginado con filtros)
- getProductById
- getProductBySku
- getProductByBarcode
- searchProducts
- getLowStockProducts
- createProduct
- updateProduct
- deleteProduct (soft delete)

### 2. CustomerOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/customers/data/repositories/customer_offline_repository.dart`
**Patrón:** Seguir CategoryOfflineRepository
**Operaciones principales:**
- getCustomers (paginado con filtros)
- getCustomerById
- searchCustomers
- createCustomer
- updateCustomer
- deleteCustomer (soft delete)

### 3. ExpenseOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/expenses/data/repositories/expense_offline_repository.dart`
**Patrón:** Seguir InvoiceOfflineRepository
**Operaciones principales:**
- getExpenses (paginado con filtros)
- getExpenseById
- createExpense
- updateExpense
- deleteExpense (soft delete)
- approveExpense
- rejectExpense

### 4. BankAccountOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/bank_accounts/data/repositories/bank_account_offline_repository.dart`
**Operaciones principales:**
- getBankAccounts (paginado con filtros)
- getBankAccountById
- createBankAccount
- updateBankAccount
- deleteBankAccount (soft delete)
- setDefaultBankAccount

### 5. SupplierOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/suppliers/data/repositories/supplier_offline_repository.dart`
**Operaciones principales:**
- getSuppliers (paginado con filtros)
- getSupplierById
- searchSuppliers
- createSupplier
- updateSupplier
- deleteSupplier (soft delete)

### 6. PurchaseOrderOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/purchase_orders/data/repositories/purchase_order_offline_repository.dart`
**Operaciones principales:**
- getPurchaseOrders (paginado con filtros)
- getPurchaseOrderById
- createPurchaseOrder
- updatePurchaseOrder
- deletePurchaseOrder (soft delete)
- approvePurchaseOrder
- receivePurchaseOrder

### 7. InventoryMovementOfflineRepository ⚠️ PENDIENTE
**Archivo:** `lib/features/inventory/data/repositories/inventory_movement_offline_repository.dart`
**Operaciones principales:**
- getInventoryMovements (paginado con filtros)
- getInventoryMovementById
- createInventoryMovement
- updateInventoryMovement
- deleteInventoryMovement (soft delete)

## Dashboard Local DataSource

### DashboardLocalDataSourceIsar ⚠️ PENDIENTE
**Archivo:** `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart`

```dart
class DashboardLocalDataSourceIsar implements DashboardLocalDataSource {
  final IsarDatabase _database;

  DashboardLocalDataSourceIsar({IsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  @override
  Future<DashboardStats> getDashboardStats() async {
    // Calculate revenue from paid invoices
    final paidInvoices = await _isar.isarInvoices
      .filter()
      .statusEqualTo(IsarInvoiceStatus.paid)
      .and()
      .deletedAtIsNull()
      .findAll();

    final revenue = paidInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.total,
    );

    // Calculate expenses from approved/paid expenses
    final paidExpenses = await _isar.isarExpenses
      .filter()
      .group((q) => q
        .statusEqualTo(IsarExpenseStatus.paid)
        .or()
        .statusEqualTo(IsarExpenseStatus.approved))
      .and()
      .deletedAtIsNull()
      .findAll();

    final expenses = paidExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    // Calculate profit
    final profit = revenue - expenses;

    // Get all invoices for payment methods breakdown
    final allInvoices = await _isar.isarInvoices
      .filter()
      .deletedAtIsNull()
      .findAll();

    final Map<String, double> paymentMethodsBreakdown = {};
    for (final invoice in allInvoices) {
      final method = invoice.paymentMethod.name;
      paymentMethodsBreakdown[method] =
        (paymentMethodsBreakdown[method] ?? 0) + invoice.total;
    }

    // Income type breakdown
    final incomeTypeBreakdown = {
      'sales': revenue,
      'services': 0.0, // Can be calculated from service products
      'other': 0.0,
    };

    return DashboardStats(
      totalRevenue: revenue,
      totalExpenses: expenses,
      profit: profit,
      profitMargin: revenue > 0 ? (profit / revenue) * 100 : 0,
      invoicesCount: allInvoices.length,
      pendingInvoices: allInvoices.where((i) => i.status == IsarInvoiceStatus.pending).length,
      paidInvoices: paidInvoices.length,
      overdueInvoices: allInvoices.where((i) =>
        i.status == IsarInvoiceStatus.pending &&
        i.dueDate.isBefore(DateTime.now())
      ).length,
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      incomeTypeBreakdown: incomeTypeBreakdown,
      // ... otros campos
    );
  }
}
```

## Actualización de app_binding.dart

Una vez implementados todos los repositorios, actualizar `lib/app/app_binding.dart`:

```dart
// Cambiar de repositorios online a offline
Get.lazyPut<ProductRepository>(
  () => ProductOfflineRepository(),
);

Get.lazyPut<CustomerRepository>(
  () => CustomerOfflineRepository(),
);

Get.lazyPut<ExpenseRepository>(
  () => ExpenseOfflineRepository(),
);

Get.lazyPut<BankAccountRepository>(
  () => BankAccountOfflineRepository(),
);

Get.lazyPut<SupplierRepository>(
  () => SupplierOfflineRepository(),
);

Get.lazyPut<PurchaseOrderRepository>(
  () => PurchaseOrderOfflineRepository(),
);

Get.lazyPut<InventoryRepository>(
  () => InventoryMovementOfflineRepository(),
);

// Dashboard datasource
Get.lazyPut<DashboardLocalDataSource>(
  () => DashboardLocalDataSourceIsar(),
);
```

## Siguiente Paso

Ejecutar nuevamente build_runner después de crear todos los repositorios:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Verificación

1. Todos los modelos Isar están creados ✅
2. Enums actualizados ✅
3. Base de datos actualizada ✅
4. Build runner ejecutado ✅
5. Repositorios offline: ⚠️ IMPLEMENTAR SIGUIENDO EL PATRÓN
6. Dashboard local datasource: ⚠️ IMPLEMENTAR
7. app_binding.dart: ⚠️ ACTUALIZAR DESPUÉS DE IMPLEMENTAR REPOSITORIOS

## Nota Importante

Debido a la cantidad de código necesario (7 repositorios × ~500 líneas cada uno), este archivo proporciona el patrón completo para que puedas:

1. Copiar el patrón base
2. Reemplazar `[Entity]` y `[Entities]` con la entidad correspondiente
3. Ajustar los filtros específicos de cada entidad
4. Implementar métodos especiales de cada repositorio

Los repositorios CategoryOfflineRepository e InvoiceOfflineRepository existentes son ejemplos perfectos para seguir.
