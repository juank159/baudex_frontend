// lib/features/inventory/presentation/screens/inventory_batches_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_batches_controller.dart';
import '../widgets/inventory_batch_card.dart';
import '../widgets/inventory_batches_filters.dart';
import '../../domain/entities/inventory_batch.dart';

class InventoryBatchesScreen extends GetView<InventoryBatchesController> {
  const InventoryBatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.displayTitle)),
        actions: [
          // Refresh button
          IconButton(
            onPressed: controller.refreshBatches,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),

          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _showDownloadOptions();
                  break;
                case 'share':
                  _showShareOptions();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Descargar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Compartir'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && !controller.hasBatches) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando lotes...'),
              ],
            ),
          );
        }

        if (controller.hasError && !controller.hasBatches) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppColors.error),
                SizedBox(height: 16),
                Text(controller.error.value, textAlign: TextAlign.center),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshBatches,
                  child: Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Product info header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    // Product details with sort button
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() => Text(
                            controller.productName.value.isNotEmpty
                                ? controller.productName.value
                                : 'Producto',
                            style: Get.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )),
                        ),
                        // Sort button in top right
                        Obx(() => PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'date_desc':
                                controller.updateSort('purchaseDate', 'desc');
                                break;
                              case 'date_asc':
                                controller.updateSort('purchaseDate', 'asc');
                                break;
                              case 'expiry_asc':
                                controller.updateSort('expirationDate', 'asc');
                                break;
                              case 'expiry_desc':
                                controller.updateSort('expirationDate', 'desc');
                                break;
                              case 'quantity_desc':
                                controller.updateSort('currentQuantity', 'desc');
                                break;
                              case 'quantity_asc':
                                controller.updateSort('currentQuantity', 'asc');
                                break;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: controller.hasCustomSort 
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: controller.hasCustomSort 
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.sortOrder.value == 'asc' 
                                    ? Icons.arrow_upward 
                                    : Icons.arrow_downward,
                                  color: controller.hasCustomSort 
                                    ? AppColors.primary 
                                    : AppColors.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  controller.getCurrentSortLabel(),
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: controller.hasCustomSort 
                                      ? AppColors.primary 
                                      : AppColors.textSecondary,
                                    fontWeight: controller.hasCustomSort 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'date_desc',
                              child: _buildSortMenuItem('Fecha: Más Reciente', 'purchaseDate', 'desc'),
                            ),
                            PopupMenuItem(
                              value: 'date_asc',
                              child: _buildSortMenuItem('Fecha: Más Antiguo', 'purchaseDate', 'asc'),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'expiry_asc',
                              child: _buildSortMenuItem('Vencimiento: Próximo', 'expirationDate', 'asc'),
                            ),
                            PopupMenuItem(
                              value: 'expiry_desc',
                              child: _buildSortMenuItem('Vencimiento: Lejano', 'expirationDate', 'desc'),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'quantity_desc',
                              child: _buildSortMenuItem('Cantidad: Mayor a Menor', 'currentQuantity', 'desc'),
                            ),
                            PopupMenuItem(
                              value: 'quantity_asc',
                              child: _buildSortMenuItem('Cantidad: Menor a Mayor', 'currentQuantity', 'asc'),
                            ),
                          ],
                        )),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Summary
                    Obx(() => Text(
                      controller.summaryText,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    )),
                  ],
                ),
              ),
            ),


            // Search bar only
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Obx(() => TextField(
                  controller: controller.searchTextController,
                  onChanged: controller.updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar por número de lote o proveedor...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: controller.isLoading.value && controller.searchQuery.value.isNotEmpty
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                    suffixIcon: controller.searchQuery.value.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (controller.searchQuery.value.isNotEmpty && !controller.isLoading.value)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${controller.inventoryBatches.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              IconButton(
                                onPressed: controller.clearSearch,
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
              ),
            ),

            // Divider
            const SliverToBoxAdapter(
              child: Divider(height: 1),
            ),

            // Tab bar
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Obx(() {
                  final tabs = controller.tabData;
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;
                  
                  return Container(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 8 : 16, 
                      isMobile ? 8 : 12, 
                      isMobile ? 8 : 16, 
                      isMobile ? 8 : 12
                    ),
                    child: Row(
                      children: List.generate(tabs.length, (index) {
                        final tab = tabs[index];
                        final isSelected = controller.selectedTab.value == index;
                        
                        Color getColor() {
                          switch (index) {
                            case 0: return AppColors.primary;
                            case 1: return Colors.green.shade600;
                            case 2: return Colors.orange.shade600;
                            case 3: return Colors.grey.shade600;
                            default: return AppColors.primary;
                          }
                        }
                        
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => controller.switchTab(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(
                                right: index < tabs.length - 1 ? (isMobile ? 4 : 8) : 0
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : 12, 
                                vertical: isMobile ? 6 : 8
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? getColor() : getColor().withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                              ),
                              child: isMobile ? 
                                // Layout móvil - más compacto
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tab['icon'], 
                                      size: 14,
                                      color: isSelected ? Colors.white : getColor(),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tab['count']}',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : getColor(),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ) :
                                // Layout desktop - normal
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          tab['icon'], 
                                          size: 16,
                                          color: isSelected ? Colors.white : getColor(),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tab['title'],
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : getColor(),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? Colors.white.withValues(alpha: 0.2) 
                                                : getColor().withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${tab['count']}',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : getColor(),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),

            // Batches list - Empty state  
            SliverToBoxAdapter(
              child: Obx(() {
                if (!controller.hasBatches && !controller.isLoading.value) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            controller.searchQuery.value.isNotEmpty 
                              ? Icons.search_off 
                              : Icons.inventory, 
                            size: 64, 
                            color: Colors.grey
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.searchQuery.value.isNotEmpty 
                              ? 'Sin resultados de búsqueda'
                              : 'Sin lotes disponibles', 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.searchQuery.value.isNotEmpty 
                              ? 'No se encontraron lotes que coincidan con "${controller.searchQuery.value}"'
                              : 'No se encontraron lotes que coincidan con los filtros aplicados.',
                            textAlign: TextAlign.center,
                          ),
                          if (controller.searchQuery.value.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => controller.updateSearchQuery(''),
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpiar búsqueda'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ),

            // Batches list - With data
            Obx(() {
              if (!controller.hasBatches) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Loading more indicator
                      if (index >= controller.inventoryBatches.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final batch = controller.inventoryBatches[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InventoryBatchCard(
                          batch: batch,
                          onTap: () {
                            _showBatchDetail(batch);
                          },
                          onPurchaseOrderTap: batch.purchaseOrderId != null
                              ? () => controller.goToPurchaseOrder(batch.purchaseOrderId)
                              : null,
                          onSupplierTap: batch.supplierId != null
                              ? () => controller.goToSupplierDetail(batch.supplierId)
                              : null,
                        ),
                      );
                    },
                    childCount: controller.inventoryBatches.length + 
                        (controller.isLoadingMore.value ? 1 : 0),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildSortMenuItem(String label, String sortBy, String sortOrder) {
    final isSelected = controller.sortBy.value == sortBy && controller.sortOrder.value == sortOrder;
    
    return Row(
      children: [
        Icon(
          sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
          color: isSelected ? AppColors.primary : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(
            Icons.check,
            color: AppColors.primary,
            size: 16,
          ),
        ],
      ],
    );
  }

  void _showDownloadOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Descargar Lotes',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los archivos se guardarán directamente en tu dispositivo',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: Colors.green, size: 20),
              ),
              title: const Text('Descargar como Excel'),
              subtitle: const Text('Archivo .xlsx guardado en tu dispositivo'),
              onTap: () {
                Get.back();
                controller.downloadBatchesToExcel();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              ),
              title: const Text('Descargar como PDF'),
              subtitle: const Text('Archivo .pdf guardado en tu dispositivo'),
              onTap: () {
                Get.back();
                controller.downloadBatchesToPdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showShareOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Compartir Lotes',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte los archivos por WhatsApp, Email, etc.',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: Colors.blue, size: 20),
              ),
              title: const Text('Compartir Excel'),
              subtitle: const Text('Enviar archivo .xlsx por WhatsApp, Email, etc.'),
              onTap: () {
                Get.back();
                controller.exportBatchesToExcel();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.orange, size: 20),
              ),
              title: const Text('Compartir PDF'),
              subtitle: const Text('Enviar reporte .pdf por WhatsApp, Email, etc.'),
              onTap: () {
                Get.back();
                controller.exportBatchesToPdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBatchDetail(InventoryBatch batch) {
    Get.dialog(
      AlertDialog(
        title: Text('Detalles del Lote ${batch.batchNumber}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Producto:', batch.productName),
              _buildDetailRow('SKU:', batch.productSku),
              _buildDetailRow('Número de Lote:', batch.batchNumber),
              _buildDetailRow('Fecha de Entrada:', AppFormatters.formatDate(batch.entryDate)),
              if (batch.hasExpiry)
                _buildDetailRow('Fecha de Vencimiento:', AppFormatters.formatDate(batch.expiryDate!)),
              _buildDetailRow('Cantidad Inicial:', '${batch.originalQuantity} unidades'),
              _buildDetailRow('Cantidad Actual:', '${batch.currentQuantity} unidades'),
              _buildDetailRow('Costo Unitario:', AppFormatters.formatCurrency(batch.unitCost)),
              _buildDetailRow('Valor Total:', AppFormatters.formatCurrency(batch.currentValue)),
              if (batch.supplierName != null)
                _buildDetailRow('Proveedor:', batch.supplierName!),
              if (batch.purchaseOrderNumber != null)
                _buildDetailRow('Orden de Compra:', batch.purchaseOrderNumber!),
              _buildDetailRow('Estado:', controller.getBatchStatusIcon(batch).toString()),
              _buildDetailRow('Días en Stock:', '${batch.daysInStock} días'),
            ],
          ),
        ),
        actions: [
          if (batch.purchaseOrderId != null)
            TextButton(
              onPressed: () {
                Get.back();
                controller.goToPurchaseOrder(batch.purchaseOrderId);
              },
              child: const Text('Ver Orden de Compra'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}