// lib/features/suppliers/presentation/controllers/supplier_detail_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/get_supplier_by_id_usecase.dart';
import '../../domain/usecases/delete_supplier_usecase.dart';
import '../../domain/usecases/update_supplier_usecase.dart';

class SupplierDetailController extends GetxController {
  final GetSupplierByIdUseCase getSupplierByIdUseCase;
  final DeleteSupplierUseCase deleteSupplierUseCase;
  final UpdateSupplierUseCase updateSupplierUseCase;

  SupplierDetailController({
    required this.getSupplierByIdUseCase,
    required this.deleteSupplierUseCase,
    required this.updateSupplierUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final Rx<Supplier?> supplier = Rx<Supplier?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdatingStatus = false.obs;
  final RxBool isDeleting = false.obs;
  final RxString error = ''.obs;
  final RxString supplierId = ''.obs;

  // UI State
  final RxInt selectedTab = 0.obs; // 0: General, 1: Comercial, 2: Historial
  final RxBool showAllDetails = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    // Obtener el ID del proveedor desde los argumentos o parámetros de ruta
    final args = Get.arguments as Map<String, dynamic>?;
    final paramId = Get.parameters['id'];

    if (args != null && args.containsKey('supplierId')) {
      supplierId.value = args['supplierId'] as String;
    } else if (paramId != null) {
      supplierId.value = paramId;
    }

    if (supplierId.value.isNotEmpty) {
      loadSupplier();
    } else {
      error.value = 'ID de proveedor no válido';
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadSupplier() async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await getSupplierByIdUseCase(supplierId.value);

      result.fold(
        (failure) {
          error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (loadedSupplier) {
          supplier.value = loadedSupplier;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshSupplier() async {
    await loadSupplier();
  }

  // ==================== SUPPLIER ACTIONS ====================

  Future<void> toggleSupplierStatus() async {
    if (supplier.value == null) return;

    try {
      isUpdatingStatus.value = true;

      final newStatus =
          supplier.value!.status == SupplierStatus.active
              ? SupplierStatus.inactive
              : SupplierStatus.active;

      final params = UpdateSupplierParams(
        id: supplier.value!.id,
        status: newStatus,
      );

      final result = await updateSupplierUseCase(params);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (updatedSupplier) {
          supplier.value = updatedSupplier;

          final statusText =
              updatedSupplier.status == SupplierStatus.active
                  ? 'activado'
                  : 'desactivado';

          Get.snackbar(
            'Éxito',
            'Proveedor $statusText correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  Future<void> deleteSupplier() async {
    if (supplier.value == null) return;

    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar el proveedor "${supplier.value!.name}"?\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (result == true) {
        isDeleting.value = true;

        final deleteResult = await deleteSupplierUseCase(supplier.value!.id);

        deleteResult.fold(
          (failure) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
            );
          },
          (_) {
            Get.snackbar(
              'Éxito',
              'Proveedor eliminado correctamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
            );

            // Volver a la lista
            Get.back(result: true);
          },
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  // ==================== NAVIGATION ====================

  void goToEdit() {
    if (supplier.value != null) {
      Get.toNamed(
        '/suppliers/edit/${supplier.value!.id}',
        arguments: {'supplierId': supplier.value!.id},
      );
    }
  }

  void goToCreatePurchaseOrder() {
    if (supplier.value != null) {
      Get.toNamed(
        '/purchase-orders/create',
        arguments: {'supplierId': supplier.value!.id},
      );
    }
  }

  void goToPurchaseHistory() {
    if (supplier.value != null) {
      Get.toNamed(
        '/purchase-orders',
        arguments: {'supplierId': supplier.value!.id},
      );
    }
  }

  // ==================== UI HELPERS ====================

  void switchTab(int index) {
    selectedTab.value = index;
  }

  void toggleDetails() {
    showAllDetails.value = !showAllDetails.value;
  }

  String getStatusText(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return 'Activo';
      case SupplierStatus.inactive:
        return 'Inactivo';
      case SupplierStatus.blocked:
        return 'Bloqueado';
    }
  }

  Color getStatusColor(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Colors.green;
      case SupplierStatus.inactive:
        return Colors.orange;
      case SupplierStatus.blocked:
        return Colors.red;
    }
  }

  IconData getStatusIcon(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Icons.check_circle;
      case SupplierStatus.inactive:
        return Icons.pause_circle;
      case SupplierStatus.blocked:
        return Icons.block;
    }
  }

  String getDocumentTypeText(DocumentType? type) {
    if (type == null) return 'Sin documento';

    switch (type) {
      case DocumentType.nit:
        return 'NIT';
      case DocumentType.cc:
        return 'Cédula de Ciudadanía';
      case DocumentType.ce:
        return 'Cédula de Extranjería';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.rut:
        return 'RUT';
      case DocumentType.other:
        return 'Otro';
    }
  }

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  String formatDateTime(DateTime dateTime) {
    return AppFormatters.formatDateTime(dateTime);
  }

  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // ==================== CONTACT HELPERS ====================

  void callPhone(String phone) {
    // TODO: Implementar llamada telefónica
    Get.snackbar(
      'Función no disponible',
      'La función de llamadas será implementada próximamente',
      snackPosition: SnackPosition.TOP,
    );
  }

  void sendEmail(String email) {
    // TODO: Implementar envío de email
    Get.snackbar(
      'Función no disponible',
      'La función de email será implementada próximamente',
      snackPosition: SnackPosition.TOP,
    );
  }

  void openWebsite(String website) {
    // TODO: Implementar apertura de sitio web
    Get.snackbar(
      'Función no disponible',
      'La función de navegador será implementada próximamente',
      snackPosition: SnackPosition.TOP,
    );
  }

  void copyToClipboard(String text) {
    // TODO: Implementar copia al portapapeles
    Get.snackbar(
      'Copiado',
      'Texto copiado al portapapeles',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasSupplier => supplier.value != null;

  bool get canEdit => hasSupplier && !isLoading.value;

  bool get canDelete => hasSupplier && !isLoading.value && !isDeleting.value;

  bool get canToggleStatus =>
      hasSupplier && !isLoading.value && !isUpdatingStatus.value;

  bool get hasContactInfo =>
      hasSupplier &&
      (supplier.value!.hasEmail ||
          supplier.value!.hasPhone ||
          supplier.value!.hasMobile ||
          supplier.value!.hasAddress);

  bool get hasCommercialInfo =>
      hasSupplier &&
      (supplier.value!.hasCreditLimit ||
          supplier.value!.hasDiscount ||
          supplier.value!.paymentTermsDays != 30);

  String get displayTitle =>
      hasSupplier ? supplier.value!.displayName : 'Proveedor';

  List<Map<String, dynamic>> get supplierSummary {
    if (!hasSupplier) return [];

    return [
      {
        'label': 'Estado',
        'value': getStatusText(supplier.value!.status),
        'color': getStatusColor(supplier.value!.status),
        'icon': getStatusIcon(supplier.value!.status),
      },
      if (supplier.value!.documentType != null &&
          supplier.value!.documentNumber != null)
        {
          'label': getDocumentTypeText(supplier.value!.documentType),
          'value': supplier.value!.documentNumber,
          'icon': Icons.badge,
        },
      if (supplier.value!.hasEmail)
        {
          'label': 'Email',
          'value': supplier.value!.email,
          'icon': Icons.email,
          'action': () => sendEmail(supplier.value!.email!),
        },
      if (supplier.value!.hasPhone)
        {
          'label': 'Teléfono',
          'value': supplier.value!.phone,
          'icon': Icons.phone,
          'action': () => callPhone(supplier.value!.phone!),
        },
      if (supplier.value!.hasMobile)
        {
          'label': 'Móvil',
          'value': supplier.value!.mobile,
          'icon': Icons.smartphone,
          'action': () => callPhone(supplier.value!.mobile!),
        },
      {
        'label': 'Moneda',
        'value': supplier.value!.currency,
        'icon': Icons.monetization_on,
      },
      {
        'label': 'Términos de pago',
        'value': '${supplier.value!.paymentTermsDays} días',
        'icon': Icons.schedule,
      },
      if (supplier.value!.hasCreditLimit)
        {
          'label': 'Límite de crédito',
          'value': formatCurrency(supplier.value!.creditLimit),
          'icon': Icons.credit_card,
        },
      if (supplier.value!.hasDiscount)
        {
          'label': 'Descuento',
          'value': formatPercentage(supplier.value!.discountPercentage),
          'icon': Icons.discount,
        },
    ];
  }
}
