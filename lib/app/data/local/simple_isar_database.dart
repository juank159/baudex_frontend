// lib/app/data/local/simple_isar_database.dart
// import 'package:isar/isar.dart';
// import 'package:path_provider/path_provider.dart';
// import 'isar_test_models.dart';

/// Implementación stub de SimpleIsarDatabase
/// 
/// Esta es una implementación temporal que compila sin errores
/// mientras se resuelven los problemas de generación de código ISAR
class SimpleIsarDatabase {
  static SimpleIsarDatabase? _instance;
  static SimpleIsarDatabase get instance => _instance ??= SimpleIsarDatabase._();
  
  // Isar? _isar;
  
  SimpleIsarDatabase._();
  
  // Stub getter - siempre lanza excepción indicando que no está disponible
  dynamic get isar {
    throw Exception('ISAR database not available - using stub implementation');
  }
  
  Future<void> initialize() async {
    // Stub implementation - no real initialization
    print('💾 Using ISAR stub implementation - no real database initialization');
    print('✅ Stub database "initialized" successfully');
  }
  
  Future<void> close() async {
    // Stub implementation - no real cleanup needed
    print('💾 Stub database "closed" successfully');
  }
}