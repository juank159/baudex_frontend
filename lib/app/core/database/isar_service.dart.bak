// lib/app/core/database/isar_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../../features/settings/data/models/app_settings_model.dart';
import '../../../features/settings/data/models/invoice_settings_model.dart';
import '../../../features/settings/data/models/printer_settings_model.dart';

class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  Future<Isar> get database async {
    if (_isar != null) return _isar!;
    
    _isar = await _initializeDatabase();
    return _isar!;
  }

  Future<Isar> _initializeDatabase() async {
    try {
      print('🗃️ IsarService: Inicializando base de datos local...');
      
      
      final dir = await getApplicationDocumentsDirectory();
      print('🗃️ IsarService: Directorio de documentos: ${dir.path}');

      final isar = await Isar.open(
        [
          AppSettingsModelSchema,
          InvoiceSettingsModelSchema,
          PrinterSettingsModelSchema,
        ],
        directory: dir.path,
        name: 'baudex_settings',
      );

      print('✅ IsarService: Base de datos inicializada exitosamente');
      print('🗃️ IsarService: Esquemas registrados:');
      print('   - AppSettingsModel');
      print('   - InvoiceSettingsModel');
      print('   - PrinterSettingsModel');

      return isar;
    } catch (e) {
      print('❌ IsarService: Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    try {
      if (_isar != null) {
        await _isar!.close();
        _isar = null;
        print('✅ IsarService: Base de datos cerrada exitosamente');
      }
    } catch (e) {
      print('❌ IsarService: Error al cerrar base de datos: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      final isar = await database;
      
      await isar.writeTxn(() async {
        await isar.appSettingsModels.clear();
        await isar.invoiceSettingsModels.clear();
        await isar.printerSettingsModels.clear();
      });
      
      print('🧹 IsarService: Todos los datos borrados exitosamente');
    } catch (e) {
      print('❌ IsarService: Error al borrar datos: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final isar = await database;
      
      final appSettingsCount = await isar.appSettingsModels.count();
      final invoiceSettingsCount = await isar.invoiceSettingsModels.count();
      final printerSettingsCount = await isar.printerSettingsModels.count();
      
      return {
        'appSettings': appSettingsCount,
        'invoiceSettings': invoiceSettingsCount,
        'printerSettings': printerSettingsCount,
        'total': appSettingsCount + invoiceSettingsCount + printerSettingsCount,
      };
    } catch (e) {
      print('❌ IsarService: Error al obtener estadísticas: $e');
      return {};
    }
  }

  Future<bool> isDatabaseEmpty() async {
    try {
      final stats = await getDatabaseStats();
      return (stats['total'] ?? 0) == 0;
    } catch (e) {
      return true;
    }
  }

  Future<void> exportDatabase(String path) async {
    try {
      final isar = await database;
      await isar.copyToFile(path);
      print('📤 IsarService: Base de datos exportada a: $path');
    } catch (e) {
      print('❌ IsarService: Error al exportar base de datos: $e');
      rethrow;
    }
  }

  Future<void> importDatabase(String path) async {
    try {
      await closeDatabase();
      
      final dir = await getApplicationDocumentsDirectory();
      // Aquí podrías implementar lógica para importar desde un archivo
      
      // Reinicializar la base de datos
      _isar = await _initializeDatabase();
      
      print('📥 IsarService: Base de datos importada desde: $path');
    } catch (e) {
      print('❌ IsarService: Error al importar base de datos: $e');
      rethrow;
    }
  }
}