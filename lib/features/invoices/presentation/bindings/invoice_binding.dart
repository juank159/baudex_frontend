// lib/features/invoices/presentation/bindings/invoice_binding.dart
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';

import '../../domain/repositories/invoice_repository.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';
import '../../domain/usecases/get_invoice_by_number_usecase.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/update_invoice_usecase.dart';
import '../../domain/usecases/confirm_invoice_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../../domain/usecases/add_multiple_payments_usecase.dart';
import '../../domain/usecases/get_invoice_stats_usecase.dart';
import '../../domain/usecases/get_overdue_invoices_usecase.dart';
import '../../domain/usecases/delete_invoice_usecase.dart';
import '../../domain/usecases/search_invoices_usecase.dart';
import '../../domain/usecases/get_invoices_by_customer_usecase.dart';
import '../../domain/usecases/export_and_share_invoice_pdf_usecase.dart';

import '../../data/datasources/invoice_remote_datasource.dart';
import '../../data/datasources/invoice_local_datasource.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../data/repositories/invoice_offline_repository_simple.dart';

// Importar use cases de clientes y productos
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../customers/domain/usecases/search_customers_usecase.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

import '../controllers/invoice_list_controller.dart';
import '../controllers/invoice_form_controller.dart';
import '../controllers/invoice_detail_controller.dart';
import '../controllers/invoice_stats_controller.dart';
import '../controllers/thermal_printer_controller.dart';
import '../services/invoice_inventory_service.dart';
import '../../../inventory/domain/usecases/process_outbound_movement_fifo_usecase.dart';

class InvoiceBinding extends Bindings {
  @override
  void dependencies() {

    // ==================== VERIFICACIÓN DE DEPENDENCIAS CORE ====================
    _verifyCoreDependencies();

    // ==================== DATA SOURCES ====================
    _registerDataSources();

    // ==================== REPOSITORY ====================
    _registerRepository();

    // ==================== USE CASES ====================
    _registerUseCases();

    // ==================== STATS CONTROLLER (SINGLETON) ====================
    _registerStatsController();

    // ==================== THERMAL PRINTER CONTROLLER ====================
    _registerThermalPrinterController();

    // ==================== INVENTORY SERVICE ====================
    _registerInventoryService();

  }

  /// Registrar dependencias SIN cargar InvoiceStatsController automáticamente
  /// Útil para pantallas que no necesitan estadísticas (como creación de facturas)
  void dependenciesWithoutStats() {

    // ==================== VERIFICACIÓN DE DEPENDENCIAS CORE ====================
    _verifyCoreDependencies();

    // ==================== DATA SOURCES ====================
    _registerDataSources();

    // ==================== REPOSITORY ====================
    _registerRepository();

    // ==================== USE CASES ====================
    _registerUseCases();

    // ==================== NOTA: NO REGISTRAR STATS CONTROLLER ====================

    // ==================== THERMAL PRINTER CONTROLLER ====================
    _registerThermalPrinterController();

  }

  /// Verificar que las dependencias core estén disponibles
  void _verifyCoreDependencies() {
    if (!Get.isRegistered<DioClient>()) {
      throw Exception(
        'DioClient no está registrado. Asegúrate de inicializar CoreBinding primero.',
      );
    }
    if (!Get.isRegistered<NetworkInfo>()) {
      throw Exception(
        'NetworkInfo no está registrado. Asegúrate de inicializar CoreBinding primero.',
      );
    }
    if (!Get.isRegistered<SecureStorageService>()) {
      throw Exception(
        'SecureStorageService no está registrado. Asegúrate de inicializar CoreBinding primero.',
      );
    }
  }

  /// Registrar data sources
  void _registerDataSources() {
    // Remote DataSource
    Get.lazyPut<InvoiceRemoteDataSource>(
      () => InvoiceRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Local DataSource
    Get.lazyPut<InvoiceLocalDataSource>(
      () => InvoiceLocalDataSourceImpl(
        storageService: Get.find<SecureStorageService>(),
      ),
      fenix: true,
    );
  }

  /// Registrar repository
  void _registerRepository() {
    // Register offline repository
    Get.lazyPut<InvoiceOfflineRepositorySimple>(
      () => InvoiceOfflineRepositorySimple(),
      fenix: true,
    );

    // Register main repository (with offline ISAR fallback)
    Get.lazyPut<InvoiceRepository>(
      () => InvoiceRepositoryImpl(
        remoteDataSource: Get.find<InvoiceRemoteDataSource>(),
        localDataSource: Get.find<InvoiceLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
        offlineRepository: Get.find<InvoiceOfflineRepositorySimple>(),
      ),
      fenix: true,
    );
  }

  /// Registrar use cases
  void _registerUseCases() {
    // Read Use Cases
    Get.lazyPut(
      () => GetInvoicesUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetInvoiceByIdUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetInvoiceByNumberUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetInvoiceStatsUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetOverdueInvoicesUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SearchInvoicesUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => GetInvoicesByCustomerUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );

    // Write Use Cases
    Get.lazyPut(
      () => CreateInvoiceUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateInvoiceUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ConfirmInvoiceUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => CancelInvoiceUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => AddPaymentUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => AddMultiplePaymentsUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => DeleteInvoiceUseCase(Get.find<InvoiceRepository>()),
      fenix: true,
    );

    // PDF Export Use Case
    Get.lazyPut(
      () => ExportAndShareInvoicePdfUseCase(
        repository: Get.find<InvoiceRepository>(),
      ),
      fenix: true,
    );

  }

  /// Registrar controlador de estadísticas (singleton global)
  void _registerStatsController() {
    if (!Get.isRegistered<InvoiceStatsController>()) {
      Get.put(
        InvoiceStatsController(
          getInvoiceStatsUseCase: Get.find<GetInvoiceStatsUseCase>(),
          getOverdueInvoicesUseCase: Get.find<GetOverdueInvoicesUseCase>(),
        ),
        permanent: true,
      );
    }
  }

  /// Registrar ThermalPrinterController (singleton global)
  void _registerThermalPrinterController() {
    if (!Get.isRegistered<ThermalPrinterController>()) {
      Get.put(
        ThermalPrinterController(),
        permanent: true, // Mantener disponible globalmente
      );
    } else {
    }
  }

  /// Registrar InvoiceInventoryService (singleton global, OPCIONAL)
  ///
  /// Este servicio es opcional y solo se registra si las dependencias
  /// de inventario están disponibles. Si no está registrado, el descuento
  /// automático de inventario estará deshabilitado.
  void _registerInventoryService() {
    if (!Get.isRegistered<InvoiceInventoryService>()) {
      // Verificar que el use case de inventario esté disponible
      if (!Get.isRegistered<ProcessOutboundMovementFifoUseCase>()) {
        return;
      }

      try {
        Get.put(
          InvoiceInventoryService(
            processOutboundMovementFifoUseCase:
                Get.find<ProcessOutboundMovementFifoUseCase>(),
          ),
          permanent: true, // Mantener disponible globalmente
        );
      } catch (e) {
      }
    } else {
    }
  }

  // ==================== MÉTODOS PARA CONTROLADORES ESPECÍFICOS ====================

  /// ✅ SOLUCIÓN: Registrar controlador de lista como PERMANENTE
  /// Esto evita que el controller se disponga al navegar entre pantallas
  static void registerListController() {
    if (!Get.isRegistered<InvoiceListController>()) {
      try {

        // Validar dependencias antes de crear el controlador
        final requiredDeps = {
          'GetInvoicesUseCase': Get.isRegistered<GetInvoicesUseCase>(),
          'SearchInvoicesUseCase': Get.isRegistered<SearchInvoicesUseCase>(),
          'DeleteInvoiceUseCase': Get.isRegistered<DeleteInvoiceUseCase>(),
          'ConfirmInvoiceUseCase': Get.isRegistered<ConfirmInvoiceUseCase>(),
          'CancelInvoiceUseCase': Get.isRegistered<CancelInvoiceUseCase>(),
          'GetInvoiceByIdUseCase': Get.isRegistered<GetInvoiceByIdUseCase>(),
        };

        for (final entry in requiredDeps.entries) {
          if (!entry.value) {
            throw Exception('${entry.key} no está registrado');
          }
        }

        // Crear y registrar como PERMANENTE
        Get.put<InvoiceListController>(
          InvoiceListController(
            getInvoicesUseCase: Get.find<GetInvoicesUseCase>(),
            searchInvoicesUseCase: Get.find<SearchInvoicesUseCase>(),
            deleteInvoiceUseCase: Get.find<DeleteInvoiceUseCase>(),
            confirmInvoiceUseCase: Get.find<ConfirmInvoiceUseCase>(),
            cancelInvoiceUseCase: Get.find<CancelInvoiceUseCase>(),
            getInvoiceByIdUseCase: Get.find<GetInvoiceByIdUseCase>(),
          ),
          permanent: true, // ✅ PERMANENTE para evitar disposal al navegar
        );

      } catch (e, stackTrace) {
        throw Exception('No se pudo registrar InvoiceListController: $e');
      }
    } else {
    }
  }

  /// Registrar controlador de formulario
  // static void registerFormController() {
  //   if (!Get.isRegistered<InvoiceFormController>()) {
  //     try {
  //       // Obtener use cases de clientes y productos de forma segura
  //       final getCustomersUseCase = _getUseCaseSafely<GetCustomersUseCase>();
  //       final searchCustomersUseCase =
  //           _getUseCaseSafely<SearchCustomersUseCase>();
  //       final getProductsUseCase = _getUseCaseSafely<GetProductsUseCase>();
  //       final searchProductsUseCase =
  //           _getUseCaseSafely<SearchProductsUseCase>();

  //       // Log de disponibilidad de dependencias
  //       print('🔍 Dependencias disponibles para InvoiceFormController:');
  //       print(
  //         '   - GetCustomersUseCase: ${getCustomersUseCase != null ? "✅" : "❌"}',
  //       );
  //       print(
  //         '   - SearchCustomersUseCase: ${searchCustomersUseCase != null ? "✅" : "❌"}',
  //       );
  //       print(
  //         '   - GetProductsUseCase: ${getProductsUseCase != null ? "✅" : "❌"}',
  //       );
  //       print(
  //         '   - SearchProductsUseCase: ${searchProductsUseCase != null ? "✅" : "❌"}',
  //       );

  //       Get.put(
  //         InvoiceFormController(
  //           // Dependencias requeridas
  //           createInvoiceUseCase: Get.find<CreateInvoiceUseCase>(),
  //           updateInvoiceUseCase: Get.find<UpdateInvoiceUseCase>(),
  //           getInvoiceByIdUseCase: Get.find<GetInvoiceByIdUseCase>(),
  //           // Dependencias opcionales para clientes y productos
  //           getCustomersUseCase: getCustomersUseCase,
  //           searchCustomersUseCase: searchCustomersUseCase,
  //           getProductsUseCase: getProductsUseCase,
  //           searchProductsUseCase: searchProductsUseCase,
  //         ),
  //       );
  //       print(
  //         '✅ InvoiceFormController registrado con dependencias disponibles',
  //       );
  //     } catch (e) {
  //       print('❌ Error registrando InvoiceFormController: $e');
  //       throw Exception('No se pudo registrar InvoiceFormController: $e');
  //     }
  //   } else {
  //     print('ℹ️ InvoiceFormController ya está registrado');
  //   }
  // }

  // ✅ MÉTODO OBSOLETO - YA NO SE USA
  // El InvoiceFormController ahora se crea directamente en el wrapper
  // para evitar problemas de dependencias circulares
  static void registerFormController() {
  }

  // static void _verifyExternalDependencies() {
  //   print('🔍 Verificando dependencias externas...');

  //   // Verificar CustomerRepository
  //   if (!Get.isRegistered<CustomerRepository>()) {
  //     print(
  //       '⚠️ CustomerRepository no encontrado - esto puede causar problemas',
  //     );
  //     print(
  //       '💡 Sugerencia: Asegúrate de que InitialBinding esté inicializado correctamente',
  //     );
  //   } else {
  //     print('✅ CustomerRepository disponible');
  //   }

  //   // Verificar GetCustomerByIdUseCase específicamente
  //   if (!Get.isRegistered<GetCustomerByIdUseCase>()) {
  //     print('⚠️ GetCustomerByIdUseCase no encontrado');
  //     print('💡 El cliente por defecto usará fallback');
  //   } else {
  //     print('✅ GetCustomerByIdUseCase disponible');
  //   }

  //   // Verificar use cases principales de Invoice
  //   final requiredUseCases = [
  //     'CreateInvoiceUseCase',
  //     'UpdateInvoiceUseCase',
  //     'GetInvoiceByIdUseCase',
  //   ];

  //   for (String useCase in requiredUseCases) {
  //     final isRegistered = Get.isRegistered(tag: useCase);
  //     if (!isRegistered) {
  //       throw Exception('UseCase crítico no encontrado: $useCase');
  //     }
  //   }

  //   print('✅ Verificación de dependencias completada');
  // }

  // ==================== MÉTODOS AUXILIARES OBSOLETOS ====================
  // Estos métodos ya no se usan porque el controlador se crea en el wrapper

  /// ✅ SOLUCIÓN: Registrar controlador de detalle SIN TAG
  static void registerDetailController() {
    if (!Get.isRegistered<InvoiceDetailController>()) {
      try {
        Get.put(
          InvoiceDetailController(
            getInvoiceByIdUseCase: Get.find<GetInvoiceByIdUseCase>(),
            addPaymentUseCase: Get.find<AddPaymentUseCase>(),
            addMultiplePaymentsUseCase: Get.find<AddMultiplePaymentsUseCase>(),
            confirmInvoiceUseCase: Get.find<ConfirmInvoiceUseCase>(),
            cancelInvoiceUseCase: Get.find<CancelInvoiceUseCase>(),
            deleteInvoiceUseCase: Get.find<DeleteInvoiceUseCase>(),
            exportAndShareInvoicePdfUseCase:
                Get.find<ExportAndShareInvoicePdfUseCase>(),
          ),
          permanent: false, // ✅ No permanente para permitir disposal correcto
          // ✅ REMOVER TAG PARA QUE SEA ACCESIBLE SIN TAG
          // tag: 'invoice_detail', ← COMENTADO
        );
      } catch (e) {
        throw Exception('No se pudo registrar InvoiceDetailController: $e');
      }
    } else {
    }
  }

  /// Método helper para obtener use cases de forma segura
  static T? _getUseCaseSafely<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==================== MÉTODOS PARA LIMPIAR CONTROLADORES ====================

  /// ✅ SOLUCIÓN: Limpiar controlador de lista SIN TAG de forma segura
  static void clearListController() {
    if (Get.isRegistered<InvoiceListController>()) {
      try {
        final controller = Get.find<InvoiceListController>();
        // Permitir que el controlador complete su disposal
        Get.delete<InvoiceListController>(force: false);
      } catch (e) {
        // Fallback: limpieza forzada
        Get.delete<InvoiceListController>(force: true);
      }
    }
  }

  /// Limpiar controlador de formulario (OBSOLETO - se maneja en el wrapper)
  static void clearFormController() {
  }

  /// ✅ SOLUCIÓN: Limpiar controlador de detalle SIN TAG de forma segura
  static void clearDetailController() {
    if (Get.isRegistered<InvoiceDetailController>()) {
      try {
        final controller = Get.find<InvoiceDetailController>();

        // Dar tiempo al controlador para completar operaciones pendientes
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            Get.delete<InvoiceDetailController>(force: false);
          } catch (e) {
            Get.delete<InvoiceDetailController>(force: true);
          }
        });

      } catch (e) {
        // Fallback: limpieza forzada
        try {
          Get.delete<InvoiceDetailController>(force: true);
        } catch (e2) {
        }
      }
    }
  }

  /// Limpiar todos los controladores específicos (mantener stats y dependencias base)
  static void clearAllScreenControllers() {
    clearListController();
    clearFormController();
    clearDetailController();
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Verificar si todas las dependencias base están registradas
  static bool areBaseDependenciesRegistered() {
    return Get.isRegistered<InvoiceRepository>() &&
        Get.isRegistered<GetInvoicesUseCase>() &&
        Get.isRegistered<CreateInvoiceUseCase>() &&
        Get.isRegistered<GetInvoiceByIdUseCase>();
  }

  /// Verificar si el controlador de estadísticas está registrado
  static bool isStatsControllerRegistered() {
    return Get.isRegistered<InvoiceStatsController>();
  }

  /// Verificar dependencias externas disponibles
  static Map<String, bool> getExternalDependencies() {
    return {
      'GetCustomersUseCase': Get.isRegistered<GetCustomersUseCase>(),
      'SearchCustomersUseCase': Get.isRegistered<SearchCustomersUseCase>(),
      'GetProductsUseCase': Get.isRegistered<GetProductsUseCase>(),
      'SearchProductsUseCase': Get.isRegistered<SearchProductsUseCase>(),
    };
  }

  /// ✅ SOLUCIÓN: Obtener información de estado del binding (actualizado)
  static String getBindingStatus() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Estado de InvoiceBinding:');
    buffer.writeln(
      '   - Repository: ${Get.isRegistered<InvoiceRepository>() ? "✅" : "❌"}',
    );
    buffer.writeln(
      '   - Stats Controller: ${Get.isRegistered<InvoiceStatsController>() ? "✅" : "❌"}',
    );
    buffer.writeln(
      '   - List Controller: ${Get.isRegistered<InvoiceListController>() ? "✅" : "❌"}',
    );
    buffer.writeln(
      '   - Form Controller: ${Get.isRegistered<InvoiceFormController>() ? "✅" : "❌"}',
    );
    buffer.writeln(
      '   - Detail Controller: ${Get.isRegistered<InvoiceDetailController>() ? "✅" : "❌"}',
    );

    // Mostrar estado de dependencias externas
    buffer.writeln('📋 Dependencias Externas:');
    final externalDeps = getExternalDependencies();
    externalDeps.forEach((name, isRegistered) {
      buffer.writeln('   - $name: ${isRegistered ? "✅" : "❌"}');
    });

    return buffer.toString();
  }

  /// Reinicializar todas las dependencias (útil para desarrollo/testing)
  static void reinitialize() {
    clearAllScreenControllers();

    // Forzar recreación de dependencias base si es necesario
    if (Get.isRegistered<InvoiceRepository>()) {
      Get.delete<InvoiceRepository>(force: true);
    }

    // Re-registrar binding
    InvoiceBinding().dependencies();
  }

  /// Método para verificar e inicializar dependencias externas
  static void checkAndWarnMissingDependencies() {
    final externalDeps = getExternalDependencies();
    final missingDeps =
        externalDeps.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

    if (missingDeps.isNotEmpty) {
      for (final dep in missingDeps) {
      }
    } else {
    }
  }

  /// ✅ NUEVO: Método de utilidad para debug
  static void debugControllerRegistration() {

    // Verificar use cases principales
  }
}
