# Estado de Implementación Offline-First

## Resumen Ejecutivo

Se ha implementado la infraestructura completa para que la aplicación funcione 100% offline. La base de datos Isar está configurada con todos los schemas necesarios.

## Completado ✅

### 1. Modelos Isar (100% completo)
- ✅ **IsarBankAccount** - `/lib/features/bank_accounts/data/models/isar/isar_bank_account.dart`
- ✅ **IsarSupplier** - `/lib/features/suppliers/data/models/isar/isar_supplier.dart`
- ✅ **IsarPurchaseOrder** + **IsarPurchaseOrderItem** - `/lib/features/purchase_orders/data/models/isar/`
- ✅ **IsarInventoryMovement** - `/lib/features/inventory/data/models/isar/isar_inventory_movement.dart`
- ✅ **IsarProduct** - Ya existe en `/lib/features/products/data/models/isar/isar_product.dart`
- ✅ **IsarCustomer** - Ya existe en `/lib/features/customers/data/models/isar/isar_customer.dart`
- ✅ **IsarExpense** - Ya existe en `/lib/features/expenses/data/models/isar/isar_expense.dart`
- ✅ **IsarCategory** - Ya existe y funciona
- ✅ **IsarInvoice** - Ya existe y funciona
- ✅ **IsarNotification** - Ya existe y funciona

### 2. Enums (100% completo)
✅ Archivo `/lib/app/data/local/enums/isar_enums.dart` actualizado con:
- IsarBankAccountType
- IsarSupplierStatus
- IsarPurchaseOrderStatus
- IsarPurchaseOrderPriority
- IsarInventoryMovementType
- IsarInventoryMovementStatus
- IsarInventoryMovementReason

### 3. Base de Datos (100% completo)
✅ Archivo `/lib/app/data/local/isar_database.dart` actualizado con:
- Todos los imports de modelos Isar
- Todos los schemas registrados en `Isar.open()`
- Métodos `getStats()` y `verifyIntegrity()` actualizados

### 4. Build Runner (100% completo)
✅ Ejecutado exitosamente: `dart run build_runner build --delete-conflicting-outputs`
- Todos los archivos `.g.dart` generados
- Sin errores de compilación

### 5. Repositorios Offline Implementados
- ✅ **BankAccountOfflineRepository** - `/lib/features/bank_accounts/data/repositories/bank_account_offline_repository.dart`
- ✅ **CategoryOfflineRepository** - Ya existe y funciona
- ✅ **InvoiceOfflineRepository** - Ya existe y funciona

## Pendiente de Implementación ⚠️

### Repositorios Offline Faltantes

Siguiendo el patrón de `BankAccountOfflineRepository`, crear los siguientes repositorios:

#### 1. ProductOfflineRepository
**Archivo:** `/lib/features/products/data/repositories/product_offline_repository.dart`
**Referencia:** Ver `CategoryOfflineRepository` e interfaz en `/lib/features/products/domain/repositories/product_repository.dart`
**Métodos principales:**
```dart
- getProducts() // Paginado con filtros
- getProductById(String id)
- getProductBySku(String sku)
- getProductByBarcode(String barcode)
- findBySkuOrBarcode(String code)
- searchProducts(String searchTerm)
- getLowStockProducts()
- getOutOfStockProducts()
- getProductsByCategory(String categoryId)
- createProduct(...)
- updateProduct(...)
- deleteProduct(String id) // soft delete
- getProductStats()
```

#### 2. CustomerOfflineRepository
**Archivo:** `/lib/features/customers/data/repositories/customer_offline_repository.dart`
**Referencia:** Ver `BankAccountOfflineRepository` e interfaz en `/lib/features/customers/domain/repositories/customer_repository.dart`
**Métodos principales:**
```dart
- getCustomers() // Paginado con filtros
- getCustomerById(String id)
- searchCustomers(String searchTerm)
- createCustomer(...)
- updateCustomer(...)
- deleteCustomer(String id) // soft delete
- getCustomerStats()
```

#### 3. ExpenseOfflineRepository
**Archivo:** `/lib/features/expenses/data/repositories/expense_offline_repository.dart`
**Referencia:** Ver `InvoiceOfflineRepository` e interfaz en `/lib/features/expenses/domain/repositories/expense_repository.dart`
**Métodos principales:**
```dart
- getExpenses() // Paginado con filtros
- getExpenseById(String id)
- createExpense(...)
- updateExpense(...)
- deleteExpense(String id) // soft delete
- approveExpense(String id)
- rejectExpense(String id, String reason)
- getExpenseStats()
```

#### 4. SupplierOfflineRepository
**Archivo:** `/lib/features/suppliers/data/repositories/supplier_offline_repository.dart`
**Referencia:** Ver `BankAccountOfflineRepository` e interfaz en `/lib/features/suppliers/domain/repositories/supplier_repository.dart`
**Métodos principales:**
```dart
- getSuppliers() // Paginado con filtros
- getSupplierById(String id)
- searchSuppliers(String searchTerm)
- createSupplier(...)
- updateSupplier(...)
- deleteSupplier(String id) // soft delete
- getSupplierStats()
```

#### 5. PurchaseOrderOfflineRepository
**Archivo:** `/lib/features/purchase_orders/data/repositories/purchase_order_offline_repository.dart`
**Referencia:** Ver `InvoiceOfflineRepository` e interfaz en `/lib/features/purchase_orders/domain/repositories/purchase_order_repository.dart`
**Métodos principales:**
```dart
- getPurchaseOrders() // Paginado con filtros
- getPurchaseOrderById(String id)
- createPurchaseOrder(...)
- updatePurchaseOrder(...)
- deletePurchaseOrder(String id) // soft delete
- approvePurchaseOrder(String id)
- receivePurchaseOrder(String id, ...)
- getPurchaseOrderStats()
```

#### 6. InventoryMovementOfflineRepository
**Archivo:** `/lib/features/inventory/data/repositories/inventory_movement_offline_repository.dart`
**Referencia:** Ver `InvoiceOfflineRepository` e interfaz en `/lib/features/inventory/domain/repositories/inventory_repository.dart`
**Métodos principales:**
```dart
- getInventoryMovements() // Paginado con filtros
- getInventoryMovementById(String id)
- createInventoryMovement(...)
- updateInventoryMovement(...)
- deleteInventoryMovement(String id) // soft delete
- confirmInventoryMovement(String id)
```

### Dashboard Local DataSource

#### DashboardLocalDataSourceIsar
**Archivo:** `/lib/features/dashboard/data/datasources/dashboard_local_datasource.dart`

Necesitas crear una clase que calcule estadísticas desde Isar:

```dart
import 'package:isar/isar.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../domain/entities/dashboard_stats.dart';

abstract class DashboardLocalDataSource {
  Future<DashboardStats> getDashboardStats();
}

class DashboardLocalDataSourceIsar implements DashboardLocalDataSource {
  final IsarDatabase _database;

  DashboardLocalDataSourceIsar({IsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  @override
  Future<DashboardStats> getDashboardStats() async {
    // Revenue: suma de todas las facturas pagadas
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

    // Expenses: suma de gastos aprobados/pagados
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

    // Profit
    final profit = revenue - expenses;

    // Payment Methods Breakdown
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

    // Income Type Breakdown (puedes ajustar según necesidad)
    final incomeTypeBreakdown = {
      'sales': revenue,
      'services': 0.0,
      'other': 0.0,
    };

    // Invoices counts
    final invoicesCount = allInvoices.length;
    final pendingInvoices = allInvoices
      .where((i) => i.status == IsarInvoiceStatus.pending)
      .length;
    final overdueInvoices = allInvoices
      .where((i) =>
        i.status == IsarInvoiceStatus.pending &&
        i.dueDate.isBefore(DateTime.now()))
      .length;

    return DashboardStats(
      totalRevenue: revenue,
      totalExpenses: expenses,
      profit: profit,
      profitMargin: revenue > 0 ? (profit / revenue) * 100 : 0,
      invoicesCount: invoicesCount,
      pendingInvoices: pendingInvoices,
      paidInvoices: paidInvoices.length,
      overdueInvoices: overdueInvoices,
      paymentMethodsBreakdown: paymentMethodsBreakdown,
      incomeTypeBreakdown: incomeTypeBreakdown,
      // Agrega otros campos según la entidad DashboardStats
    );
  }
}
```

## Actualización de Dependency Injection

Una vez implementados todos los repositorios, actualizar `/lib/app/app_binding.dart`:

```dart
// En InitialBinding.dependencies():

// ==================== REPOSITORIES ====================

// Products
Get.lazyPut<ProductRepository>(
  () => ProductOfflineRepository(),
);

// Customers
Get.lazyPut<CustomerRepository>(
  () => CustomerOfflineRepository(),
);

// Expenses
Get.lazyPut<ExpenseRepository>(
  () => ExpenseOfflineRepository(),
);

// Bank Accounts
Get.lazyPut<BankAccountRepository>(
  () => BankAccountOfflineRepository(),
);

// Suppliers
Get.lazyPut<SupplierRepository>(
  () => SupplierOfflineRepository(),
);

// Purchase Orders
Get.lazyPut<PurchaseOrderRepository>(
  () => PurchaseOrderOfflineRepository(),
);

// Inventory
Get.lazyPut<InventoryRepository>(
  () => InventoryMovementOfflineRepository(),
);

// ==================== DATA SOURCES ====================

Get.lazyPut<DashboardLocalDataSource>(
  () => DashboardLocalDataSourceIsar(),
);
```

## Patrón de Implementación

Para cada repositorio, sigue este patrón (ver `BankAccountOfflineRepository` como ejemplo):

1. **Imports necesarios:**
   - `dartz` para Either
   - `isar` para queries
   - Failures del core
   - IsarDatabase
   - Entidad del dominio
   - Interface del repositorio
   - Modelo Isar
   - Enums Isar

2. **Constructor con IsarDatabase:**
   ```dart
   final IsarDatabase _database;

   [Entity]OfflineRepository({IsarDatabase? database})
     : _database = database ?? IsarDatabase.instance;

   Isar get _isar => _database.database;
   ```

3. **Operaciones READ:**
   - Siempre filtrar por `deletedAtIsNull()` (soft delete)
   - Aplicar filtros adicionales según parámetros
   - Convertir Isar entities a domain entities con `.toEntity()`
   - Retornar `Right(result)` en éxito, `Left(CacheFailure(...))` en error

4. **Operaciones WRITE:**
   - Generar `serverId` único con timestamp
   - Marcar como `isSynced: false` al crear/modificar
   - Usar `writeTxn()` para operaciones de escritura
   - Llamar `markAsUnsynced()` al actualizar
   - Soft delete con `softDelete()`

5. **Helpers opcionales:**
   - Mappers de enums domain ↔ Isar
   - Métodos auxiliares para lógica compleja

6. **Sync operations:**
   - `getUnsynced[Entities]()` - Obtener no sincronizados
   - `mark[Entities]AsSynced()` - Marcar como sincronizados
   - `bulkInsert[Entities]()` - Inserción masiva desde servidor

## Verificación Final

Después de implementar todos los repositorios:

1. ✅ Ejecutar build_runner nuevamente (por si acaso):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. ✅ Verificar que la app compile sin errores:
   ```bash
   flutter analyze
   ```

3. ✅ Probar la app en modo offline:
   - Crear entidades (productos, clientes, gastos, etc.)
   - Editar entidades
   - Eliminar entidades (soft delete)
   - Ver estadísticas en dashboard
   - Verificar que todo funcione sin internet

## Archivos de Referencia

Los mejores ejemplos para copiar son:

1. **Para entidades simples:** `BankAccountOfflineRepository`
2. **Para entidades con relaciones:** `InvoiceOfflineRepository`
3. **Para entidades jerárquicas:** `CategoryOfflineRepository`

## Beneficios de esta Implementación

- ✅ App funciona 100% sin internet
- ✅ Datos se guardan localmente en Isar
- ✅ Sincronización automática cuando vuelve internet (con SyncQueue)
- ✅ Soft delete mantiene integridad de datos
- ✅ Multitenancy preparado (campo organizationId)
- ✅ Búsqueda y filtrado eficiente con índices Isar
- ✅ Paginación para grandes volúmenes de datos
- ✅ Estadísticas calculadas desde datos locales

## Próximos Pasos Recomendados

1. Implementar los 6 repositorios faltantes
2. Implementar DashboardLocalDataSourceIsar
3. Actualizar app_binding.dart
4. Ejecutar build_runner
5. Probar exhaustivamente offline
6. Implementar sincronización bidireccional con SyncService

## Notas Importantes

- **Multitenancy:** Aunque el campo `organizationId` existe en los modelos, aún no se filtra en las queries. Agregar `.organizationIdEqualTo(currentOrgId)` cuando se implemente autenticación completa.

- **Sincronización:** El sistema SyncQueue ya existe y está configurado. Los repositorios marcan entidades como no sincronizadas, y SyncService las sincronizará automáticamente cuando haya conexión.

- **Soft Delete:** Todas las entidades usan `deletedAt` para soft delete. Nunca se eliminan físicamente de Isar hasta que se sincronicen con el servidor.

- **IDs offline:** Se generan IDs temporales con el formato `{entity}_{timestamp}_{hash}`. Cuando se sincronice con el servidor, se debe mapear el ID temporal al ID real del servidor.
