// lib/app/data/local/isar_database.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Import all ISAR models
import '../../../features/categories/data/models/isar/isar_category.dart';
import '../../../features/customers/data/models/isar/isar_customer.dart';
import '../../../features/products/data/models/isar/isar_product.dart';
import '../../../features/products/data/models/isar/isar_product_price.dart';
import '../../../features/expenses/data/models/isar/isar_expense.dart';
import '../../../features/invoices/data/models/isar/isar_invoice.dart';
import '../../../features/notifications/data/models/isar/isar_notification.dart';

/// Singleton para manejar la base de datos ISAR
/// 
/// Maneja todas las colecciones de ISAR para datos offline-first
class IsarDatabase {
  static IsarDatabase? _instance;
  static Isar? _isar;

  IsarDatabase._();

  static IsarDatabase get instance {
    _instance ??= IsarDatabase._();
    return _instance!;
  }

  /// Getter para la instancia de ISAR
  Isar get database {
    if (_isar == null) {
      throw Exception('ISAR database not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  /// Inicializar la base de datos ISAR
  Future<void> initialize() async {
    if (_isar != null) {
      print('💾 ISAR database already initialized');
      return;
    }

    try {
      print('💾 Inicializando base de datos ISAR...');
      
      // Obtener el directorio para la base de datos
      final dir = await getApplicationDocumentsDirectory();
      
      // Inicializar ISAR con todas las colecciones
      _isar = await Isar.open(
        [
          IsarCategorySchema,
          IsarCustomerSchema,
          IsarProductSchema,
          IsarExpenseSchema,
          IsarInvoiceSchema,
          IsarNotificationSchema,
        ],
        directory: dir.path,
        name: 'baudex_business',
      );
      
      print('✅ Base de datos ISAR inicializada exitosamente');
      print('📍 Ubicación: ${dir.path}/baudex_business.isar');
      
      // Mostrar estadísticas iniciales
      final stats = await getStats();
      print('📊 Estadísticas iniciales: $stats');
      
    } catch (e) {
      print('❌ Error inicializando ISAR database: $e');
      rethrow;
    }
  }

  /// Cerrar la base de datos
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      print('💾 Base de datos ISAR cerrada exitosamente');
    }
    _instance = null;
  }

  /// Limpiar toda la base de datos
  Future<void> clear() async {
    if (_isar == null) return;
    
    await _isar!.writeTxn(() async {
      await _isar!.clear();
    });
    
    print('💾 Base de datos ISAR limpiada exitosamente');
  }

  /// Verificar si la base de datos está inicializada
  bool get isInitialized => _isar != null;
  
  /// Obtener estadísticas de la base de datos
  Future<Map<String, int>> getStats() async {
    if (_isar == null) {
      return {
        'categories': 0,
        'customers': 0,
        'products': 0,
        'expenses': 0,
        'invoices': 0,
        'notifications': 0,
      };
    }

    return {
      'categories': await _isar!.isarCategorys.count(),
      'customers': await _isar!.isarCustomers.count(),
      'products': await _isar!.isarProducts.count(),
      'expenses': await _isar!.isarExpenses.count(),
      'invoices': await _isar!.isarInvoices.count(),
      'notifications': await _isar!.isarNotifications.count(),
    };
  }

  /// Backup de la base de datos
  Future<void> backup(String path) async {
    if (_isar == null) return;
    
    await _isar!.copyToFile(path);
    print('💾 Backup creado en: $path');
  }

  /// Obtener el tamaño de la base de datos en bytes
  Future<int> getDatabaseSize() async {
    if (_isar == null) return 0;
    
    return await _isar!.getSize();
  }

  /// Compactar la base de datos
  Future<void> compact() async {
    if (_isar == null) return;
    
    final sizeBefore = await getDatabaseSize();
    // ISAR auto-compacts, but we can trigger a manual compact by closing and reopening
    await close();
    await initialize();
    final sizeAfter = await getDatabaseSize();
    
    print('💾 Base de datos compactada: ${sizeBefore}B -> ${sizeAfter}B');
  }

  /// Verificar la integridad de la base de datos
  Future<bool> verifyIntegrity() async {
    if (_isar == null) return false;
    
    try {
      // Verificar que podemos leer de cada colección
      await _isar!.isarCategorys.count();
      await _isar!.isarCustomers.count();
      await _isar!.isarProducts.count();
      await _isar!.isarExpenses.count();
      await _isar!.isarInvoices.count();
      await _isar!.isarNotifications.count();
      
      print('✅ Integridad de base de datos verificada');
      return true;
    } catch (e) {
      print('❌ Error en verificación de integridad: $e');
      return false;
    }
  }
}