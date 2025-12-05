// lib/features/purchase_orders/presentation/controllers/purchase_order_detail_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/usecases/get_purchase_order_by_id_usecase.dart';
import '../../domain/usecases/delete_purchase_order_usecase.dart';
import '../../domain/usecases/update_purchase_order_usecase.dart';
import '../../domain/usecases/approve_purchase_order_usecase.dart';
import '../../domain/usecases/send_purchase_order_usecase.dart';
import '../../domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart';
import '../../domain/usecases/cancel_purchase_order_usecase.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../../inventory/domain/usecases/get_warehouses_usecase.dart';
import '../../../inventory/domain/entities/warehouse.dart';
import 'package:collection/collection.dart';
import 'purchase_orders_controller.dart';

class PurchaseOrderDetailController extends GetxController {
  final GetPurchaseOrderByIdUseCase getPurchaseOrderByIdUseCase;
  final DeletePurchaseOrderUseCase deletePurchaseOrderUseCase;
  final UpdatePurchaseOrderUseCase updatePurchaseOrderUseCase;
  final ApprovePurchaseOrderUseCase approvePurchaseOrderUseCase;
  final SendPurchaseOrderUseCase sendPurchaseOrderUseCase;
  final ReceivePurchaseOrderAndUpdateInventoryUseCase
  receivePurchaseOrderAndUpdateInventoryUseCase;
  final CancelPurchaseOrderUseCase cancelPurchaseOrderUseCase;
  final GetWarehousesUseCase getWarehousesUseCase;

  PurchaseOrderDetailController({
    required this.getPurchaseOrderByIdUseCase,
    required this.deletePurchaseOrderUseCase,
    required this.updatePurchaseOrderUseCase,
    required this.approvePurchaseOrderUseCase,
    required this.sendPurchaseOrderUseCase,
    required this.receivePurchaseOrderAndUpdateInventoryUseCase,
    required this.cancelPurchaseOrderUseCase,
    required this.getWarehousesUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final Rx<PurchaseOrder?> purchaseOrder = Rx<PurchaseOrder?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdatingStatus = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isReceiving = false.obs;
  final RxBool isSending = false.obs;
  final RxString error = ''.obs;
  final RxString purchaseOrderId = ''.obs;

  // UI State
  final RxInt selectedTab =
      0.obs; // 0: General, 1: Items, 2: Workflow, 3: Actividad
  final RxBool showAllDetails = false.obs;

  // Receiving state
  final RxList<ReceivePurchaseOrderItemParams> receivingItems =
      <ReceivePurchaseOrderItemParams>[].obs;

  // Warehouse selection
  final RxList<Warehouse> availableWarehouses = <Warehouse>[].obs;
  final Rx<Warehouse?> selectedWarehouse = Rx<Warehouse?>(null);
  final RxBool isLoadingWarehouses = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    // Obtener el ID de la orden desde los argumentos o parámetros de ruta
    final args = Get.arguments as Map<String, dynamic>?;
    final paramId = Get.parameters['id'];

    if (args != null && args.containsKey('purchaseOrderId')) {
      purchaseOrderId.value = args['purchaseOrderId'] as String;
    } else if (paramId != null) {
      purchaseOrderId.value = paramId;
    }

    if (purchaseOrderId.value.isNotEmpty) {
      loadPurchaseOrder();
      // Load warehouses for future receiving operations
      loadAvailableWarehouses();
    } else {
      error.value = 'ID de orden de compra no válido';
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadPurchaseOrder() async {
    try {
      isLoading.value = true;
      error.value = '';
      print(
        '🔍 PurchaseOrderDetailController: Cargando orden ${purchaseOrderId.value}',
      );

      final result = await getPurchaseOrderByIdUseCase(purchaseOrderId.value);

      result.fold(
        (failure) {
          print('❌ PurchaseOrderDetailController: Error - ${failure.message}');
          error.value = failure.message;
          Get.snackbar(
            'Error al cargar orden',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (loadedPurchaseOrder) {
          print(
            '✅ PurchaseOrderDetailController: Orden cargada exitosamente - ${loadedPurchaseOrder.orderNumber}',
          );
          print('🔍 DEBUG - Supplier info:');
          print('   supplierId: ${loadedPurchaseOrder.supplierId}');
          print('   supplierName: ${loadedPurchaseOrder.supplierName}');
          print('🔍 DEBUG - Items info:');
          for (int i = 0; i < loadedPurchaseOrder.items.length; i++) {
            final item = loadedPurchaseOrder.items[i];
            print(
              '   Item $i: quantity=${item.quantity}, unitPrice=${item.unitPrice}, totalAmount=${item.totalAmount}',
            );
          }
          purchaseOrder.value = loadedPurchaseOrder;
          _initializeReceivingItems();
          print(
            '✅ PurchaseOrderDetailController: UI actualizada con datos de la orden',
          );
        },
      );
    } catch (e) {
      print('❌ PurchaseOrderDetailController: Exception - $e');
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error al cargar orden',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      print(
        '🔍 PurchaseOrderDetailController: Loading finalizado. HasOrder: ${purchaseOrder.value != null}',
      );
    }
  }

  Future<void> refreshPurchaseOrder() async {
    await loadPurchaseOrder();
  }

  void _initializeReceivingItems() {
    if (purchaseOrder.value != null) {
      receivingItems.value =
          purchaseOrder.value!.items
              .map(
                (item) => ReceivePurchaseOrderItemParams(
                  itemId: item.id,
                  receivedQuantity:
                      item.quantity, // Use full quantity as default to receive
                  damagedQuantity: 0,
                  missingQuantity: 0,
                  actualUnitCost: null,
                  supplierLotNumber: null,
                  expirationDate: null,
                  notes: null,
                ),
              )
              .toList();
    }
  }

  // ==================== PURCHASE ORDER ACTIONS ====================

  Future<void> approvePurchaseOrder({String? notes}) async {
    if (purchaseOrder.value == null) return;

    try {
      isUpdatingStatus.value = true;

      final params = ApprovePurchaseOrderParams(
        id: purchaseOrder.value!.id,
        approvalNotes: notes,
      );

      final result = await approvePurchaseOrderUseCase(params);

      result.fold(
        (failure) {
          // Cerrar cualquier diálogo abierto
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (updatedPurchaseOrder) {
          purchaseOrder.value = updatedPurchaseOrder;

          // Cerrar cualquier diálogo abierto
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          // Navegar de vuelta a la lista de órdenes de compra y refrescar
          Future.delayed(const Duration(milliseconds: 500), () {
            if (Get.isRegistered<PurchaseOrderDetailController>()) {
              // Refrescar el controlador de la lista si existe
              try {
                final listController = Get.find<PurchaseOrdersController>();
                listController.refreshAfterOrderChange(
                  purchaseOrder.value!.id,
                  isUpdate: true,
                );
              } catch (e) {
                print('⚠️ No se pudo refrescar la lista: $e');
              }
              Get.offAllNamed('/purchase-orders');
            }
          });
        },
      );
    } catch (e) {
      // Cerrar cualquier diálogo abierto
      if (Get.isDialogOpen == true) {
        Get.back();
      }

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

  Future<void> submitForReview({String? notes}) async {
    if (purchaseOrder.value == null) return;

    try {
      isUpdatingStatus.value = true;

      // Cambiar de draft a pending
      await updatePurchaseOrderStatus(PurchaseOrderStatus.pending);
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

  Future<void> sendPurchaseOrder({String? notes}) async {
    if (purchaseOrder.value == null) return;

    try {
      isSending.value = true;

      final params = SendPurchaseOrderParams(
        id: purchaseOrder.value!.id,
        sendNotes: notes,
      );

      final result = await sendPurchaseOrderUseCase(params);

      result.fold(
        (failure) {
          // Cerrar cualquier diálogo abierto
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (updatedPurchaseOrder) {
          purchaseOrder.value = updatedPurchaseOrder;

          // Refrescar el controlador de la lista si existe
          try {
            final listController = Get.find<PurchaseOrdersController>();
            listController.refreshAfterOrderChange(
              purchaseOrder.value!.id,
              isUpdate: true,
            );
          } catch (e) {
            print('⚠️ No se pudo refrescar la lista: $e');
          }

          // Cerrar cualquier diálogo abierto
          if (Get.isDialogOpen == true) {
            Get.back();
          }
        },
      );
    } catch (e) {
      // Cerrar cualquier diálogo abierto
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> receivePurchaseOrder({String? notes}) async {
    if (purchaseOrder.value == null) return;

    try {
      isReceiving.value = true;

      // Ensure warehouse is selected before receiving
      if (selectedWarehouse.value == null) {
        if (availableWarehouses.isEmpty) {
          await loadAvailableWarehouses();
        }

        if (availableWarehouses.length > 1) {
          await showWarehouseSelectionDialog();
        }

        // If still no warehouse selected, show error
        if (selectedWarehouse.value == null) {
          Get.snackbar(
            'Selección Requerida',
            'Debe seleccionar un almacén para recibir la mercancía',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
          );
          return;
        }
      }

      final params = ReceivePurchaseOrderParams(
        id: purchaseOrder.value!.id,
        items: receivingItems,
        receivedDate: DateTime.now(),
        notes: notes,
        warehouseId: selectedWarehouse.value!.id, // Add warehouse ID
      );

      final result = await receivePurchaseOrderAndUpdateInventoryUseCase(
        params,
      );

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
        (updatedPurchaseOrder) {
          purchaseOrder.value = updatedPurchaseOrder;
          _initializeReceivingItems();

          final statusMessage =
              updatedPurchaseOrder.isReceived
                  ? 'Orden de compra recibida completamente'
                  : 'Recepción parcial procesada correctamente';

          Get.snackbar(
            'Éxito',
            statusMessage,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          // Si la orden está completamente recibida, mostrar mensaje adicional
          if (updatedPurchaseOrder.isReceived) {
            Future.delayed(const Duration(milliseconds: 2000), () {
              Get.snackbar(
                'Estado Actualizado',
                'La orden ha sido marcada como completamente recibida',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.blue.shade100,
                colorText: Colors.blue.shade800,
                duration: const Duration(seconds: 3),
              );
            });
          }

          // Refrescar el controlador de la lista si existe
          try {
            final listController = Get.find<PurchaseOrdersController>();
            listController.refreshAfterOrderChange(
              updatedPurchaseOrder.id,
              isUpdate: true,
            );
          } catch (e) {
            print('⚠️ No se pudo refrescar la lista: $e');
          }

          // Refrescar la orden actual para obtener el estado más reciente del servidor
          Future.delayed(const Duration(milliseconds: 500), () async {
            await refreshPurchaseOrder();
          });

          // Navegar de vuelta al listado de órdenes de compra con un pequeño delay
          // para asegurar que los snackbars se muestren correctamente
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (Get.isRegistered<PurchaseOrderDetailController>()) {
              Get.offAllNamed('/purchase-orders');
            }
          });
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
      isReceiving.value = false;
    }
  }

  // ==================== WAREHOUSE MANAGEMENT ====================

  Future<void> loadAvailableWarehouses() async {
    try {
      isLoadingWarehouses.value = true;

      final result = await getWarehousesUseCase();

      result.fold(
        (failure) {
          print('❌ Error loading warehouses: ${failure.message}');
          availableWarehouses.clear();
        },
        (warehouses) {
          availableWarehouses.value =
              warehouses.where((w) => w.isActive).toList();

          // Auto-select logic
          if (availableWarehouses.length == 1) {
            // If only one warehouse, auto-select it
            selectedWarehouse.value = availableWarehouses.first;
            print(
              '🏢 Auto-selected single warehouse: ${selectedWarehouse.value!.name}',
            );
          } else if (availableWarehouses.isNotEmpty) {
            // If multiple warehouses, try to find "principal" or first one
            final principalWarehouse = availableWarehouses.firstWhereOrNull(
              (w) =>
                  w.name.toLowerCase().contains('principal') ||
                  w.code.toLowerCase().contains('main'),
            );
            selectedWarehouse.value =
                principalWarehouse ?? availableWarehouses.first;
            print(
              '🏢 Auto-selected warehouse: ${selectedWarehouse.value!.name}',
            );
          }
        },
      );
    } catch (e) {
      print('❌ Exception loading warehouses: $e');
      availableWarehouses.clear();
    } finally {
      isLoadingWarehouses.value = false;
    }
  }

  void selectWarehouse(Warehouse warehouse) {
    selectedWarehouse.value = warehouse;
    print('🏢 Warehouse selected: ${warehouse.name}');
  }

  Future<void> showWarehouseSelectionDialog() async {
    if (availableWarehouses.isEmpty) {
      await loadAvailableWarehouses();
    }

    if (availableWarehouses.length <= 1) {
      // No need to show dialog if only one or no warehouses
      return;
    }

    await Get.dialog(
      AlertDialog(
        title: const Text('Seleccionar Almacén'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿A qué almacén llega esta mercancía?'),
              const SizedBox(height: 16),
              ...availableWarehouses.map(
                (warehouse) => ListTile(
                  title: Text(warehouse.name),
                  subtitle: Text(warehouse.code),
                  leading: Radio<String>(
                    value: warehouse.id,
                    groupValue: selectedWarehouse.value?.id,
                    onChanged: (value) {
                      if (value != null) {
                        selectWarehouse(warehouse);
                        Get.back();
                      }
                    },
                  ),
                  onTap: () {
                    selectWarehouse(warehouse);
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> updatePurchaseOrderStatus(PurchaseOrderStatus newStatus) async {
    if (purchaseOrder.value == null) return;

    try {
      isUpdatingStatus.value = true;

      final params = UpdatePurchaseOrderParams(
        id: purchaseOrder.value!.id,
        status: newStatus,
      );

      final result = await updatePurchaseOrderUseCase(params);

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
        (updatedPurchaseOrder) {
          purchaseOrder.value = updatedPurchaseOrder;

          // Refrescar el controlador de la lista si existe
          try {
            final listController = Get.find<PurchaseOrdersController>();
            listController.refreshAfterOrderChange(
              purchaseOrder.value!.id,
              isUpdate: true,
            );
          } catch (e) {
            print('⚠️ No se pudo refrescar la lista: $e');
          }

          Get.snackbar(
            'Éxito',
            'Estado actualizado correctamente',
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

  Future<void> deletePurchaseOrder() async {
    if (purchaseOrder.value == null) return;

    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar la orden de compra "${purchaseOrder.value!.orderNumber}"?\n\n'
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

        final deleteResult = await deletePurchaseOrderUseCase(
          purchaseOrder.value!.id,
        );

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
              'Orden de compra eliminada correctamente',
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

  Future<void> cancelPurchaseOrder({String? cancellationReason}) async {
    if (purchaseOrder.value == null) return;

    try {
      final reason =
          cancellationReason?.isNotEmpty == true
              ? cancellationReason!
              : 'Orden cancelada por el usuario';

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar cancelación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Está seguro de que desea cancelar la orden de compra "${purchaseOrder.value!.orderNumber}"?',
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Motivo de cancelación (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // Se puede implementar si se necesita capturar el motivo
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancelar Orden'),
            ),
          ],
        ),
      );

      if (result == true) {
        isUpdatingStatus.value = true;

        final params = CancelPurchaseOrderParams(
          id: purchaseOrder.value!.id,
          cancellationReason: reason,
        );

        final cancelResult = await cancelPurchaseOrderUseCase(params);

        cancelResult.fold(
          (failure) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
            );
          },
          (cancelledOrder) {
            purchaseOrder.value = cancelledOrder;

            // Refrescar el controlador de la lista si existe
            try {
              final listController = Get.find<PurchaseOrdersController>();
              listController.refreshAfterOrderChange(
                purchaseOrder.value!.id,
                isUpdate: true,
              );
            } catch (e) {
              print('⚠️ No se pudo refrescar la lista: $e');
            }

            Get.snackbar(
              'Orden Cancelada',
              'La orden de compra ha sido cancelada correctamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange.shade100,
              colorText: Colors.orange.shade800,
            );
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
      isUpdatingStatus.value = false;
    }
  }

  // ==================== RECEIVING MANAGEMENT ====================

  void updateReceivedQuantity(String itemId, int quantity) {
    final index = receivingItems.indexWhere((item) => item.itemId == itemId);
    if (index != -1) {
      final currentItem = receivingItems[index];
      receivingItems[index] = ReceivePurchaseOrderItemParams(
        itemId: itemId,
        receivedQuantity: quantity,
        damagedQuantity: currentItem.damagedQuantity,
        missingQuantity: currentItem.missingQuantity,
        actualUnitCost: currentItem.actualUnitCost,
        supplierLotNumber: currentItem.supplierLotNumber,
        expirationDate: currentItem.expirationDate,
        notes: currentItem.notes,
      );
    }
  }

  void updateReceivingNotes(String itemId, String notes) {
    final index = receivingItems.indexWhere((item) => item.itemId == itemId);
    if (index != -1) {
      final currentItem = receivingItems[index];
      receivingItems[index] = ReceivePurchaseOrderItemParams(
        itemId: itemId,
        receivedQuantity: currentItem.receivedQuantity,
        damagedQuantity: currentItem.damagedQuantity,
        missingQuantity: currentItem.missingQuantity,
        actualUnitCost: currentItem.actualUnitCost,
        supplierLotNumber: currentItem.supplierLotNumber,
        expirationDate: currentItem.expirationDate,
        notes: notes.isNotEmpty ? notes : null,
      );
    }
  }

  // ==================== NAVIGATION ====================

  void goToEdit() {
    if (purchaseOrder.value != null) {
      Get.toNamed(
        '/purchase-orders/edit/${purchaseOrder.value!.id}',
        arguments: {'purchaseOrderId': purchaseOrder.value!.id},
      );
    }
  }

  void goToSupplierDetail() {
    if (purchaseOrder.value != null) {
      Get.toNamed(
        '/suppliers/detail/${purchaseOrder.value!.supplierId}',
        arguments: {'supplierId': purchaseOrder.value!.supplierId},
      );
    }
  }

  void goToInventoryMovements() {
    if (purchaseOrder.value != null) {
      Get.toNamed(
        '/inventory/movements',
        arguments: {'purchaseOrderId': purchaseOrder.value!.id},
      );
    }
  }

  void goToGeneratedBatches() {
    if (purchaseOrder.value != null && purchaseOrder.value!.isReceived) {
      // Si la orden tiene múltiples productos, ir a la pantalla general de inventario
      if (purchaseOrder.value!.items.length > 1) {
        Get.toNamed(
          '/inventory/balances',
          arguments: {'purchaseOrderId': purchaseOrder.value!.id},
        );
      } else if (purchaseOrder.value!.items.isNotEmpty) {
        // Si solo tiene un producto, ir directamente a sus lotes
        final productId = purchaseOrder.value!.items.first.productId;
        Get.toNamed(
          '/inventory/product/$productId/batches',
          arguments: {
            'productId': productId,
            'purchaseOrderId': purchaseOrder.value!.id,
          },
        );
      }
    }
  }

  void goToProductKardex(String productId) {
    Get.toNamed(
      '/inventory/product/$productId/kardex',
      arguments: {'productId': productId},
    );
  }

  void goToProductBatches(String productId) {
    Get.toNamed(
      '/inventory/product/$productId/batches',
      arguments: {
        'productId': productId,
        'purchaseOrderId': purchaseOrder.value?.id,
      },
    );
  }

  // ==================== UI HELPERS ====================

  void switchTab(int index) {
    selectedTab.value = index;
  }

  void toggleDetails() {
    showAllDetails.value = !showAllDetails.value;
  }

  String getStatusText(PurchaseOrderStatus status) {
    return status.displayStatus;
  }

  Color getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.pending:
        return Colors.orange;
      case PurchaseOrderStatus.approved:
        return Colors.blue;
      case PurchaseOrderStatus.rejected:
        return Colors.red;
      case PurchaseOrderStatus.sent:
        return Colors.purple;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.amber;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return Icons.edit_note;
      case PurchaseOrderStatus.pending:
        return Icons.schedule;
      case PurchaseOrderStatus.approved:
        return Icons.check_circle;
      case PurchaseOrderStatus.rejected:
        return Icons.cancel;
      case PurchaseOrderStatus.sent:
        return Icons.send;
      case PurchaseOrderStatus.partiallyReceived:
        return Icons.pending_actions;
      case PurchaseOrderStatus.received:
        return Icons.inventory;
      case PurchaseOrderStatus.cancelled:
        return Icons.block;
    }
  }

  String getPriorityText(PurchaseOrderPriority priority) {
    return priority.displayPriority;
  }

  Color getPriorityColor(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Colors.green;
      case PurchaseOrderPriority.medium:
        return Colors.orange;
      case PurchaseOrderPriority.high:
        return Colors.red;
      case PurchaseOrderPriority.urgent:
        return Colors.deepPurple;
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

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasPurchaseOrder => purchaseOrder.value != null;

  bool get canEdit =>
      hasPurchaseOrder && purchaseOrder.value!.canEdit && !isLoading.value;

  bool get canDelete =>
      hasPurchaseOrder &&
      purchaseOrder.value!.canEdit &&
      !isLoading.value &&
      !isDeleting.value;

  bool get canSubmitForReview =>
      hasPurchaseOrder &&
      purchaseOrder.value!.canSubmitForReview &&
      !isLoading.value &&
      !isUpdatingStatus.value;

  bool get canApprove =>
      hasPurchaseOrder &&
      purchaseOrder.value!.canApprove &&
      purchaseOrder.value!.status == PurchaseOrderStatus.pending &&
      !isLoading.value &&
      !isUpdatingStatus.value;

  bool get canSend =>
      hasPurchaseOrder &&
      purchaseOrder.value!.canSend &&
      !isLoading.value &&
      !isSending.value;

  bool get canReceive =>
      hasPurchaseOrder &&
      purchaseOrder.value!.canReceive &&
      !isLoading.value &&
      !isReceiving.value;

  bool get canCancel =>
      hasPurchaseOrder &&
      purchaseOrder.value!.canCancel &&
      !isLoading.value &&
      !isUpdatingStatus.value;

  bool get hasDeliveryInfo =>
      hasPurchaseOrder && purchaseOrder.value!.hasDeliveryInfo;

  bool get hasAttachments =>
      hasPurchaseOrder && purchaseOrder.value!.hasAttachments;

  bool get isOverdue => hasPurchaseOrder && purchaseOrder.value!.isOverdue;

  bool get canViewBatches =>
      hasPurchaseOrder && purchaseOrder.value!.isReceived;

  bool get hasGeneratedBatches =>
      canViewBatches &&
      purchaseOrder.value!.items.any(
        (item) => item.receivedQuantity != null && item.receivedQuantity! > 0,
      );

  String get displayTitle =>
      hasPurchaseOrder
          ? (purchaseOrder.value!.orderNumber ?? 'Sin número')
          : 'Orden de Compra';

  String get progressPercentage {
    if (!hasPurchaseOrder) return '0%';

    final order = purchaseOrder.value!;
    if (order.isReceived) return '100%';
    if (order.isSent) return '75%';
    if (order.isApproved) return '50%';
    if (order.isPending) return '25%';
    return '0%';
  }

  int get totalItemsReceived {
    if (!hasPurchaseOrder) return 0;
    return purchaseOrder.value!.items
        .where((item) => item.isFullyReceived)
        .length;
  }

  int get totalItemsPending {
    if (!hasPurchaseOrder) return 0;
    return purchaseOrder.value!.items
        .where((item) => item.isPendingDelivery)
        .length;
  }

  double get totalReceivedValue {
    if (!hasPurchaseOrder) return 0.0;
    return purchaseOrder.value!.items
        .where((item) => item.receivedQuantity != null)
        .fold(
          0.0,
          (sum, item) => sum + (item.unitPrice * (item.receivedQuantity ?? 0)),
        );
  }

  double get totalPendingValue {
    if (!hasPurchaseOrder) return 0.0;
    return purchaseOrder.value!.items.fold(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.pendingQuantity),
    );
  }

  int get totalQuantityReceived {
    if (!hasPurchaseOrder) return 0;
    return purchaseOrder.value!.items.fold(
      0,
      (sum, item) => sum + (item.receivedQuantity ?? 0),
    );
  }

  List<Map<String, dynamic>> get purchaseOrderSummary {
    if (!hasPurchaseOrder) return [];

    final order = purchaseOrder.value!;
    print('🔍 Debug purchaseOrderSummary:');
    print('   - supplierName: ${order.supplierName}');
    print('   - priority: ${order.priority}');
    print('   - status: ${order.status}');

    return [
      {
        'label': 'Estado',
        'value': getStatusText(order.status),
        'color': getStatusColor(order.status),
        'icon': getStatusIcon(order.status),
      },
      {
        'label': 'Prioridad',
        'value': getPriorityText(order.priority),
        'color': getPriorityColor(order.priority),
        'icon': Icons.priority_high,
      },
      {
        'label': 'Proveedor',
        'value':
            order.supplierName?.isNotEmpty == true
                ? order.supplierName!
                : 'Sin proveedor asignado',
        'icon': Icons.business,
        'color':
            (order.supplierName?.isNotEmpty == true)
                ? null
                : Colors.grey.shade600,
      },
      {
        'label': 'Fecha de Orden',
        'value':
            order.orderDate != null
                ? formatDate(order.orderDate!)
                : 'Sin fecha',
        'icon': Icons.calendar_today,
      },
      {
        'label': 'Entrega Esperada',
        'value':
            order.expectedDeliveryDate != null
                ? formatDate(order.expectedDeliveryDate!)
                : 'Sin fecha',
        'icon': Icons.schedule,
        'color': isOverdue ? Colors.red : null,
      },
      if (order.deliveredDate != null)
        {
          'label': 'Fecha de Entrega',
          'value': formatDate(order.deliveredDate!),
          'icon': Icons.check_circle,
          'color': Colors.green,
        },
      {
        'label': 'Total Items',
        'value': '${order.itemsCount} productos',
        'icon': Icons.inventory_2,
      },
      {
        'label': 'Cantidad Solicitada',
        'value': '${order.totalQuantity} unidades',
        'icon': Icons.format_list_numbered,
      },
      {
        'label': 'Cantidad Recibida',
        'value': '$totalQuantityReceived unidades',
        'icon': Icons.check_circle,
        'color':
            totalQuantityReceived == order.totalQuantity
                ? Colors.green
                : totalQuantityReceived > 0
                ? Colors.orange
                : Colors.grey,
      },
      {
        'label': 'Valor Total',
        'value': formatCurrency(order.totalAmount),
        'icon': Icons.monetization_on,
      },
    ];
  }
}
