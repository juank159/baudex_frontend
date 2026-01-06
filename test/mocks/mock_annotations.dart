// test/mocks/mock_annotations.dart
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core imports
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';

// Products
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_local_datasource_isar.dart';

// Categories
import 'package:baudex_desktop/features/categories/domain/repositories/category_repository.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_local_datasource.dart';

// Customers
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_local_datasource.dart';

// Suppliers
import 'package:baudex_desktop/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:baudex_desktop/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:baudex_desktop/features/suppliers/data/datasources/supplier_local_datasource.dart';

// Expenses
import 'package:baudex_desktop/features/expenses/domain/repositories/expense_repository.dart';
import 'package:baudex_desktop/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:baudex_desktop/features/expenses/data/datasources/expense_local_datasource.dart';

// Invoices
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';

// Purchase Orders
import 'package:baudex_desktop/features/purchase_orders/domain/repositories/purchase_order_repository.dart';
import 'package:baudex_desktop/features/purchase_orders/data/datasources/purchase_order_remote_datasource.dart';
import 'package:baudex_desktop/features/purchase_orders/data/datasources/purchase_order_local_datasource.dart';

// Inventory
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource.dart';

// Credit Notes
import 'package:baudex_desktop/features/credit_notes/domain/repositories/credit_note_repository.dart';
import 'package:baudex_desktop/features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import 'package:baudex_desktop/features/credit_notes/data/datasources/credit_note_local_datasource.dart';

// Customer Credits
import 'package:baudex_desktop/features/customer_credits/domain/repositories/customer_credit_repository.dart';
import 'package:baudex_desktop/features/customer_credits/data/datasources/customer_credit_remote_datasource.dart';
import 'package:baudex_desktop/features/customer_credits/data/datasources/customer_credit_local_datasource_isar.dart';

/// Generate mocks for all repositories, data sources, and core services
///
/// Run the following command to generate mocks:
/// ```
/// dart run build_runner build --delete-conflicting-outputs
/// ```
///
/// This will generate:
/// - test/mocks/mock_annotations.mocks.dart
///
/// Import in your tests:
/// ```dart
/// import 'package:baudex_desktop/test/mocks/mock_annotations.mocks.dart';
/// ```
@GenerateMocks([
  // Core services
  SyncService,
  NetworkInfo,
  Connectivity,
  Dio,

  // Products
  ProductRepository,
  ProductRemoteDataSource,
  ProductLocalDataSourceIsar,

  // Categories
  CategoryRepository,
  CategoryRemoteDataSource,
  CategoryLocalDataSource,

  // Customers
  CustomerRepository,
  CustomerRemoteDataSource,
  CustomerLocalDataSource,

  // Suppliers
  SupplierRepository,
  SupplierRemoteDataSource,
  SupplierLocalDataSource,

  // Expenses
  ExpenseRepository,
  ExpenseRemoteDataSource,
  ExpenseLocalDataSource,

  // Invoices
  InvoiceRepository,
  InvoiceRemoteDataSource,
  InvoiceLocalDataSource,

  // Purchase Orders
  PurchaseOrderRepository,
  PurchaseOrderRemoteDataSource,
  PurchaseOrderLocalDataSource,

  // Inventory
  InventoryRepository,
  InventoryRemoteDataSource,
  InventoryLocalDataSource,

  // Credit Notes
  CreditNoteRepository,
  CreditNoteRemoteDataSource,
  CreditNoteLocalDataSource,

  // Customer Credits
  CustomerCreditRepository,
  CustomerCreditRemoteDataSource,
  CustomerCreditLocalDataSourceIsar,
])
void main() {
  // This file is only for annotation purposes
  // Mocks will be generated in mock_annotations.mocks.dart
}
