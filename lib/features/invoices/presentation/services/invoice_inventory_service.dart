//lib/features/invoices/presentation/services/invoice_inventory_service.dart
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../settings/presentation/controllers/user_preferences_controller.dart';
import '../../../inventory/domain/usecases/process_outbound_movement_fifo_usecase.dart';
import '../../../inventory/domain/entities/inventory_movement.dart';
import '../../domain/entities/invoice.dart';

class InvoiceInventoryService extends GetxService {
  final ProcessOutboundMovementFifoUseCase _processOutboundMovementFifoUseCase;

  InvoiceInventoryService({
    required ProcessOutboundMovementFifoUseCase
    processOutboundMovementFifoUseCase,
  }) : _processOutboundMovementFifoUseCase = processOutboundMovementFifoUseCase;

  /// Procesa el descuento de inventario para una factura si está habilitado en preferencias
  Future<bool> processInventoryForInvoice(Invoice invoice) async {
    try {
      // Obtener controlador de preferencias de usuario
      final userPrefsController = Get.find<UserPreferencesController>();

      // Verificar si el descuento automático está habilitado
      if (!userPrefsController.autoDeductInventory) {
        print('ℹ️ Descuento automático de inventario deshabilitado');
        return false;
      }

      bool allItemsProcessed = true;

      // Procesar cada item de la factura
      for (final item in invoice.items) {
        // Solo procesar productos registrados (no temporales)
        if (item.productId != null && item.productId!.isNotEmpty) {
          final success = await _processItemInventory(item, invoice);
          if (!success) {
            allItemsProcessed = false;
            print(
              '❌ Error procesando inventario para producto ${item.productId}',
            );
          }
        }
      }

      if (allItemsProcessed) {
        print(
          '✅ Inventario procesado exitosamente para factura ${invoice.number}',
        );

        // Mostrar notificación de éxito
        Get.snackbar(
          'Inventario Actualizado',
          'Stock descontado automáticamente según configuración FIFO',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        print('⚠️ Algunos items no pudieron ser procesados en inventario');

        // Mostrar notificación de advertencia
        Get.snackbar(
          'Inventario Parcialmente Procesado',
          'Algunos productos no pudieron ser descontados del stock',
          snackPosition: SnackPosition.TOP,
        );
      }

      return allItemsProcessed;
    } catch (e) {
      print('❌ Error procesando inventario para factura: $e');

      // Mostrar error al usuario
      Get.snackbar(
        'Error en Inventario',
        'No se pudo procesar el descuento de inventario: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }

  /// Procesa el inventario para un item específico de la factura
  Future<bool> _processItemInventory(InvoiceItem item, Invoice invoice) async {
    try {
      final params = ProcessFifoMovementParams(
        productId: item.productId!,
        quantity: item.quantity.toInt(),
        reason: InventoryMovementReason.sale,
        referenceType: 'invoice',
        referenceId: invoice.id,
        notes: 'Venta automática - Factura ${invoice.number}',
      );

      final result = await _processOutboundMovementFifoUseCase(params);

      return result.fold(
        (failure) {
          print(
            '❌ Error procesando FIFO para producto ${item.productId}: ${failure.message}',
          );
          return false;
        },
        (movement) {
          print(
            '✅ Movimiento FIFO creado para producto ${item.productId}: ${movement.id}',
          );
          return true;
        },
      );
    } catch (e) {
      print('❌ Error inesperado procesando item ${item.productId}: $e');
      return false;
    }
  }

  /// Verifica si el descuento automático está habilitado
  bool get isAutoDeductEnabled {
    try {
      final userPrefsController = Get.find<UserPreferencesController>();
      return userPrefsController.autoDeductInventory;
    } catch (e) {
      print('❌ Error obteniendo preferencias de usuario: $e');
      return true; // Por defecto habilitado si no se puede obtener
    }
  }

  /// Muestra diálogo para procesar inventario manualmente
  Future<void> showManualProcessDialog(Invoice invoice) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Procesar Inventario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El descuento automático de inventario está deshabilitado en tus preferencias.',
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas procesar el descuento de inventario manualmente para esta factura?',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se utilizará el método FIFO para descontar del stock',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No procesar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Procesar ahora'),
          ),
        ],
      ),
    );

    if (result == true) {
      await processInventoryForInvoice(invoice);
    }
  }

  /// Obtiene información de configuración para mostrar al usuario
  Map<String, dynamic> getInventoryConfigInfo() {
    try {
      final userPrefsController = Get.find<UserPreferencesController>();

      return {
        'autoDeductEnabled': userPrefsController.autoDeductInventory,
        'useFifoCosting': userPrefsController.useFifoCosting,
        'validateStock': userPrefsController.validateStockBeforeInvoice,
        'allowOverselling': userPrefsController.allowOverselling,
      };
    } catch (e) {
      return {
        'autoDeductEnabled': true,
        'useFifoCosting': true,
        'validateStock': true,
        'allowOverselling': false,
      };
    }
  }
}
