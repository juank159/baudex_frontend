// lib/features/products/presentation/controllers/product_waste_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/isar/isar_product.dart';
import '../../data/models/register_product_waste_request_model.dart';

/// Controller del flujo de **Registrar Merma** — offline-first.
///
/// - Si hay red: llama al endpoint del backend (que descuenta del FIFO real).
/// - Si NO hay red: encola en `SyncQueue` con entityType `ProductWaste` y
///   descuenta el stock local del producto en ISAR para que el cambio se
///   vea inmediato. Cuando vuelva la conexión, `_syncProductWasteOperation`
///   en el sync_service reproduce la operación contra el backend.
class ProductWasteController extends GetxController {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProductWasteController({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  // ==================== OBSERVABLE STATE ====================

  final isLoading = false.obs;
  final productId = ''.obs;
  final productName = ''.obs;
  final currentStock = 0.0.obs;

  final quantityCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    final params = Get.parameters;

    productId.value = params['productId'] ?? '';
    productName.value = (args?['productName'] as String?) ?? '';
    currentStock.value =
        ((args?['currentStock'] as num?)?.toDouble()) ?? 0.0;
  }

  @override
  void onClose() {
    quantityCtrl.dispose();
    reasonCtrl.dispose();
    super.onClose();
  }

  // ==================== SUBMIT ====================

  Future<void> submit() async {
    final quantityText = quantityCtrl.text.trim();
    final reason = reasonCtrl.text.trim();

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _showError('Cantidad inválida', 'Ingresa una cantidad mayor a cero.');
      return;
    }

    if (reason.length < 3) {
      _showError(
        'Razón requerida',
        'La razón debe tener al menos 3 caracteres.',
      );
      return;
    }

    if (quantity > currentStock.value) {
      _showError(
        'Stock insuficiente',
        'Solo hay ${currentStock.value.toStringAsFixed(2)} disponibles. No puedes mermar más de lo que tienes.',
      );
      return;
    }

    isLoading.value = true;
    try {
      final connected = await networkInfo.isConnected;

      if (connected) {
        await _registerWasteOnline(quantity, reason);
      } else {
        await _registerWasteOffline(quantity, reason);
      }

      Get.back();
    } catch (e) {
      AppLogger.e(
        'Error al registrar merma: $e',
        tag: 'ProductWasteController',
      );
      _showError(
        'Error al registrar merma',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _registerWasteOnline(double quantity, String reason) async {
    final request = RegisterProductWasteRequestModel(
      quantity: quantity,
      reason: reason,
    );
    await remoteDataSource.registerWaste(productId.value, request);

    // Reflejar el descuento localmente para que el detalle del producto se
    // vea actualizado sin esperar al próximo PULL.
    await _decrementLocalStock(quantity);

    AppLogger.i(
      'Merma registrada online: producto=${productId.value} qty=$quantity',
      tag: 'ProductWasteController',
    );
    Get.snackbar(
      'Merma registrada',
      'Se descontaron $quantity del stock.',
      backgroundColor: Colors.green.shade100,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _registerWasteOffline(double quantity, String reason) async {
    // 1. Encolar en SyncQueue para reproducirla al volver la conexión.
    final tempId =
        'waste_offline_${DateTime.now().millisecondsSinceEpoch}_${quantity.hashCode}';

    final syncService = Get.find<SyncService>();
    await syncService.addOperationForCurrentUser(
      entityType: 'ProductWaste',
      entityId: tempId,
      operationType: SyncOperationType.create,
      data: {
        'productId': productId.value,
        'quantity': quantity,
        'reason': reason,
      },
      priority: 1,
    );

    // 2. Descuento local de stock para feedback inmediato al usuario.
    await _decrementLocalStock(quantity);

    AppLogger.i(
      'Merma encolada offline: producto=${productId.value} qty=$quantity tempId=$tempId',
      tag: 'ProductWasteController',
    );
    Get.snackbar(
      'Merma guardada offline',
      'Se descontaron $quantity del stock localmente. Se enviará al servidor cuando recuperes conexión.',
      backgroundColor: Colors.orange.shade100,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Baja `quantity` del stock local del IsarProduct correspondiente.
  /// No falla si el producto no está cacheado — el próximo PULL lo
  /// reconciliará. Tampoco actualiza batches FIFO: backend lo hace al
  /// procesar la operación encolada y el siguiente PULL trae los batches.
  Future<void> _decrementLocalStock(double quantity) async {
    try {
      final Isar isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        final isarProduct = await isar.isarProducts
            .filter()
            .serverIdEqualTo(productId.value)
            .findFirst();
        if (isarProduct == null) {
          AppLogger.w(
            'Producto ${productId.value} no en cache local — skip update de stock',
            tag: 'ProductWasteController',
          );
          return;
        }
        final newStock = (isarProduct.stock - quantity).clamp(0, double.infinity);
        isarProduct.stock = newStock.toDouble();
        isarProduct.isSynced = false;
        isarProduct.updatedAt = DateTime.now();
        await isar.isarProducts.put(isarProduct);
      });
      currentStock.value = (currentStock.value - quantity).clamp(0, double.infinity).toDouble();
    } catch (e) {
      AppLogger.w(
        'No se pudo actualizar stock local tras merma: $e',
        tag: 'ProductWasteController',
      );
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.shade100,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}
