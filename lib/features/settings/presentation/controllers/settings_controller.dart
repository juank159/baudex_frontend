// lib/features/settings/presentation/controllers/settings_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/invoice_settings.dart';
import '../../domain/entities/printer_settings.dart';
import '../../domain/usecases/get_app_settings_usecase.dart';
import '../../domain/usecases/save_app_settings_usecase.dart';
import '../../domain/usecases/get_invoice_settings_usecase.dart';
import '../../domain/usecases/save_invoice_settings_usecase.dart';
import '../../domain/usecases/get_printer_settings_usecase.dart';
import '../../domain/usecases/save_printer_settings_usecase.dart';
import '../../../invoices/presentation/controllers/thermal_printer_controller.dart';

class SettingsController extends GetxController with SyncAutoRefreshMixin {
  // Dependencies
  final GetAppSettingsUseCase _getAppSettingsUseCase;
  final SaveAppSettingsUseCase _saveAppSettingsUseCase;
  final GetInvoiceSettingsUseCase _getInvoiceSettingsUseCase;
  final SaveInvoiceSettingsUseCase _saveInvoiceSettingsUseCase;
  final GetAllPrinterSettingsUseCase _getAllPrinterSettingsUseCase;
  final GetDefaultPrinterSettingsUseCase _getDefaultPrinterSettingsUseCase;
  final SavePrinterSettingsUseCase _savePrinterSettingsUseCase;
  final DeletePrinterSettingsUseCase _deletePrinterSettingsUseCase;
  final SetDefaultPrinterUseCase _setDefaultPrinterUseCase;
  final TestPrinterConnectionUseCase _testPrinterConnectionUseCase;

  SettingsController({
    required GetAppSettingsUseCase getAppSettingsUseCase,
    required SaveAppSettingsUseCase saveAppSettingsUseCase,
    required GetInvoiceSettingsUseCase getInvoiceSettingsUseCase,
    required SaveInvoiceSettingsUseCase saveInvoiceSettingsUseCase,
    required GetAllPrinterSettingsUseCase getAllPrinterSettingsUseCase,
    required GetDefaultPrinterSettingsUseCase getDefaultPrinterSettingsUseCase,
    required SavePrinterSettingsUseCase savePrinterSettingsUseCase,
    required DeletePrinterSettingsUseCase deletePrinterSettingsUseCase,
    required SetDefaultPrinterUseCase setDefaultPrinterUseCase,
    required TestPrinterConnectionUseCase testPrinterConnectionUseCase,
  })  : _getAppSettingsUseCase = getAppSettingsUseCase,
        _saveAppSettingsUseCase = saveAppSettingsUseCase,
        _getInvoiceSettingsUseCase = getInvoiceSettingsUseCase,
        _saveInvoiceSettingsUseCase = saveInvoiceSettingsUseCase,
        _getAllPrinterSettingsUseCase = getAllPrinterSettingsUseCase,
        _getDefaultPrinterSettingsUseCase = getDefaultPrinterSettingsUseCase,
        _savePrinterSettingsUseCase = savePrinterSettingsUseCase,
        _deletePrinterSettingsUseCase = deletePrinterSettingsUseCase,
        _setDefaultPrinterUseCase = setDefaultPrinterUseCase,
        _testPrinterConnectionUseCase = testPrinterConnectionUseCase {
  }

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoadingAppSettings = false.obs;
  final _isLoadingInvoiceSettings = false.obs;
  final _isLoadingPrinterSettings = false.obs;
  final _isSaving = false.obs;
  final _isTestingConnection = false.obs;

  // Configuraciones
  final _appSettings = Rxn<AppSettings>();
  final _invoiceSettings = Rxn<InvoiceSettings>();
  final _printerSettings = <PrinterSettings>[].obs;
  final _defaultPrinter = Rxn<PrinterSettings>();

  // Descubrimiento de impresoras del sistema
  final discoveredPrinters = <String>[].obs;
  final isDiscovering = false.obs;

  // ==================== GETTERS ====================

  bool get isLoadingAppSettings => _isLoadingAppSettings.value;
  bool get isLoadingInvoiceSettings => _isLoadingInvoiceSettings.value;
  bool get isLoadingPrinterSettings => _isLoadingPrinterSettings.value;
  bool get isSaving => _isSaving.value;
  bool get isTestingConnection => _isTestingConnection.value;

  AppSettings? get appSettings => _appSettings.value;
  InvoiceSettings? get invoiceSettings => _invoiceSettings.value;
  List<PrinterSettings> get printerSettings => _printerSettings;
  PrinterSettings? get defaultPrinter => _defaultPrinter.value;

  bool get hasNetworkPrinters => _printerSettings.any((p) => p.isNetworkPrinter);
  bool get hasUsbPrinters => _printerSettings.any((p) => p.isUsbPrinter);
  int get totalPrinters => _printerSettings.length;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();
    loadAllSettings();
  }

  @override
  Future<void> onSyncCompleted() async {
    await loadAllSettings();
  }

  // ==================== CORE METHODS ====================

  Future<void> loadAllSettings() async {
    await Future.wait([
      loadAppSettings(),
      loadInvoiceSettings(),
      loadPrinterSettings(),
    ]);
  }

  // ==================== APP SETTINGS ====================

  Future<void> loadAppSettings() async {
    try {
      _isLoadingAppSettings.value = true;

      final result = await _getAppSettingsUseCase(NoParams());

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo cargar la configuración de la aplicación');
        },
        (settings) {
          _appSettings.value = settings;
        },
      );
    } catch (e) {
    } finally {
      _isLoadingAppSettings.value = false;
    }
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    try {
      _isSaving.value = true;

      final result = await _saveAppSettingsUseCase(
        SaveAppSettingsParams(settings: settings),
      );

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo guardar la configuración de la aplicación');
        },
        (savedSettings) {
          _appSettings.value = savedSettings;
          _showSuccess('Configuración de aplicación guardada exitosamente');
        },
      );
    } catch (e) {
    } finally {
      _isSaving.value = false;
    }
  }

  // ==================== INVOICE SETTINGS ====================

  Future<void> loadInvoiceSettings() async {
    try {
      _isLoadingInvoiceSettings.value = true;

      final result = await _getInvoiceSettingsUseCase(NoParams());

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo cargar la configuración de facturas');
        },
        (settings) {
          _invoiceSettings.value = settings;
        },
      );
    } catch (e) {
    } finally {
      _isLoadingInvoiceSettings.value = false;
    }
  }

  Future<void> saveInvoiceSettings(InvoiceSettings settings) async {
    try {
      _isSaving.value = true;

      final result = await _saveInvoiceSettingsUseCase(
        SaveInvoiceSettingsParams(settings: settings),
      );

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo guardar la configuración de facturas');
        },
        (savedSettings) {
          _invoiceSettings.value = savedSettings;
          _showSuccess('Configuración de facturas guardada exitosamente');
        },
      );
    } catch (e) {
    } finally {
      _isSaving.value = false;
    }
  }

  // ==================== PRINTER SETTINGS ====================

  Future<void> loadPrinterSettings() async {
    try {
      _isLoadingPrinterSettings.value = true;

      final allPrintersResult = await _getAllPrinterSettingsUseCase(NoParams());
      final defaultPrinterResult = await _getDefaultPrinterSettingsUseCase(NoParams());

      allPrintersResult.fold(
        (failure) {
          _showError('Error', 'No se pudo cargar la configuración de impresoras');
        },
        (printers) {
          _printerSettings.value = printers;
        },
      );

      defaultPrinterResult.fold(
        (failure) {
        },
        (defaultPrinter) {
          _defaultPrinter.value = defaultPrinter;
          if (defaultPrinter != null) {
          }
        },
      );
    } catch (e) {
    } finally {
      _isLoadingPrinterSettings.value = false;
    }
  }

  Future<void> savePrinterSettings(PrinterSettings settings) async {
    try {
      _isSaving.value = true;

      final result = await _savePrinterSettingsUseCase(
        SavePrinterSettingsParams(settings: settings),
      );

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo guardar la configuración de la impresora');
        },
        (savedSettings) {
          // Actualizar la lista local
          final index = _printerSettings.indexWhere((p) => p.id == savedSettings.id);
          if (index != -1) {
            _printerSettings[index] = savedSettings;
          } else {
            _printerSettings.add(savedSettings);
          }

          // Actualizar impresora por defecto si corresponde
          if (savedSettings.isDefault) {
            _defaultPrinter.value = savedSettings;
          }

          _showSuccess('Configuración de impresora guardada exitosamente');
        },
      );
    } catch (e) {
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> deletePrinterSettings(String settingsId) async {
    try {
      _isSaving.value = true;

      final result = await _deletePrinterSettingsUseCase(
        DeletePrinterSettingsParams(settingsId: settingsId),
      );

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo eliminar la configuración de la impresora');
        },
        (_) {
          // Remover de la lista local
          _printerSettings.removeWhere((p) => p.id == settingsId);
          
          // Si era la impresora por defecto, limpiar
          if (_defaultPrinter.value?.id == settingsId) {
            _defaultPrinter.value = null;
          }

          _showSuccess('Configuración de impresora eliminada exitosamente');
        },
      );
    } catch (e) {
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> setDefaultPrinter(String settingsId) async {
    try {
      _isSaving.value = true;

      final result = await _setDefaultPrinterUseCase(
        SetDefaultPrinterParams(settingsId: settingsId),
      );

      result.fold(
        (failure) {
          _showError('Error', 'No se pudo establecer la impresora por defecto');
        },
        (defaultPrinter) {
          // Actualizar todas las impresoras en la lista
          for (int i = 0; i < _printerSettings.length; i++) {
            _printerSettings[i] = _printerSettings[i].copyWith(
              isDefault: _printerSettings[i].id == settingsId,
            );
          }

          _defaultPrinter.value = defaultPrinter;
          _showSuccess('Impresora por defecto establecida exitosamente');
        },
      );
    } catch (e) {
    } finally {
      _isSaving.value = false;
    }
  }

  Future<bool> testPrinterConnection(PrinterSettings settings) async {
    try {
      _isTestingConnection.value = true;

      // DIAGNÓSTICO: Verificar configuración básica
      if (settings.isNetworkPrinter) {
        if (settings.ipAddress == null || settings.ipAddress!.isEmpty) {
          _showError('Error de Configuración', 'La dirección IP no está configurada');
          return false;
        }
        if (settings.port == null || settings.port! <= 0) {
          _showError('Error de Configuración', 'El puerto no está configurado');
          return false;
        }
      }

      final result = await _testPrinterConnectionUseCase(
        TestPrinterConnectionParams(settings: settings),
      );

      return result.fold(
        (failure) {
          _showError('Error de Conexión', failure.message);
          return false;
        },
        (isConnected) {
          if (isConnected) {
            _showSuccess('Conexión exitosa con la impresora');
          } else {
            _showError('Error de Conexión', 'No se pudo conectar con la impresora');
          }
          return isConnected;
        },
      );
    } catch (e) {
      return false;
    } finally {
      _isTestingConnection.value = false;
    }
  }

  // ✅ NUEVA FUNCIÓN: Imprimir página de prueba
  Future<bool> printTestPage(PrinterSettings settings) async {
    try {
      _isTestingConnection.value = true;

      // DIAGNÓSTICO: Verificar que la configuración sea correcta
      if (settings.isNetworkPrinter) {
        if (settings.ipAddress == null || settings.ipAddress!.isEmpty) {
          _showError('Error de Configuración', 'La dirección IP no está configurada');
          return false;
        }
        if (settings.port == null || settings.port! <= 0) {
          _showError('Error de Configuración', 'El puerto no está configurado');
          return false;
        }
      }

      // Obtener el ThermalPrinterController
      ThermalPrinterController thermalController;
      try {
        thermalController = Get.find<ThermalPrinterController>();
      } catch (e) {
        // Si no existe, crearlo
        thermalController = Get.put(ThermalPrinterController());
      }
      
      // Configurar temporalmente la impresora
      await thermalController.setTempPrinterConfig(settings);
      
      // Imprimir página de prueba
      final success = await thermalController.printTestPage();
      
      if (success) {
        _showSuccess('Página de prueba enviada a la impresora');
      } else {
        _showError('Error de Impresión', 'No se pudo imprimir la página de prueba');
      }
      
      return success;
    } catch (e) {
      _showError('Error de Impresión', 'Error inesperado: $e');
      return false;
    } finally {
      _isTestingConnection.value = false;
    }
  }

  // ==================== DESCUBRIMIENTO DE IMPRESORAS ====================

  /// Detecta impresoras instaladas en el sistema operativo (USB + red locales)
  Future<void> discoverSystemPrinters() async {
    if (isDiscovering.value) return;

    try {
      isDiscovering.value = true;
      discoveredPrinters.clear();

      List<String> printers = [];

      if (Platform.isMacOS || Platform.isLinux) {
        // Usar lpstat -a para listar impresoras CUPS
        final result = await Process.run('lpstat', ['-a']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              // Format: "printer_name accepting requests since ..."
              final name = trimmed.split(' ').first;
              if (name.isNotEmpty) {
                printers.add(name);
              }
            }
          }
        }
      } else if (Platform.isWindows) {
        // Usar wmic para listar impresoras Windows
        final result = await Process.run('wmic', [
          'printer', 'get', 'name', '/format:list',
        ]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('Name=')) {
              final name = trimmed.substring(5).trim();
              if (name.isNotEmpty) {
                printers.add(name);
              }
            }
          }
        }
      }

      discoveredPrinters.addAll(printers);
      for (final p in printers) {
      }

      if (printers.isEmpty) {
        _showError('Sin impresoras', 'No se detectaron impresoras en el sistema');
      }
    } catch (e) {
      _showError('Error', 'No se pudieron detectar impresoras: $e');
    } finally {
      isDiscovering.value = false;
    }
  }

  // ==================== HELPER METHODS ====================

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> refreshAllSettings() async {
    await loadAllSettings();
  }

  PrinterSettings? getPrinterById(String id) {
    try {
      return _printerSettings.firstWhere((printer) => printer.id == id);
    } catch (e) {
      return null;
    }
  }

  List<PrinterSettings> getNetworkPrinters() {
    return _printerSettings.where((p) => p.isNetworkPrinter).toList();
  }

  List<PrinterSettings> getUsbPrinters() {
    return _printerSettings.where((p) => p.isUsbPrinter).toList();
  }
}