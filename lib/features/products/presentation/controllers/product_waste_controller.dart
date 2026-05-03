// lib/features/products/presentation/controllers/product_waste_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/register_product_waste_request_model.dart';

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

    // Validate quantity
    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'Cantidad inválida',
        'Ingresa una cantidad mayor a cero.',
        backgroundColor: Colors.red.shade100,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Validate reason
    if (reason.length < 3) {
      Get.snackbar(
        'Razón requerida',
        'La razón debe tener al menos 3 caracteres.',
        backgroundColor: Colors.red.shade100,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Online-only check
    final connected = await networkInfo.isConnected;
    if (!connected) {
      Get.snackbar(
        'Sin conexión',
        'El registro de merma requiere internet para validar el FIFO en el servidor.',
        backgroundColor: Colors.orange.shade100,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final request = RegisterProductWasteRequestModel(
        quantity: quantity,
        reason: reason,
      );

      await remoteDataSource.registerWaste(productId.value, request);

      AppLogger.i('Merma registrada exitosamente para producto ${productId.value}');

      Get.snackbar(
        'Merma registrada',
        'Se descontaron $quantity unidades del stock correctamente.',
        backgroundColor: Colors.green.shade100,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      Get.back();
    } catch (e) {
      AppLogger.e('Error al registrar merma: $e', tag: 'ProductWasteController');
      Get.snackbar(
        'Error al registrar merma',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade100,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
