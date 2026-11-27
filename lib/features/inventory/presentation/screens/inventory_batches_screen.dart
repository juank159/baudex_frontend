// lib/features/inventory/presentation/screens/inventory_batches_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../controllers/inventory_batches_controller.dart';
import '../widgets/inventory_batch_card.dart';
import '../widgets/inventory_states.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class InventoryBatchesScreen extends GetView<InventoryBatchesController> {
  const InventoryBatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MainLayout(
        title: controller.displayTitle,
        showBackButton: true,
        showDrawer: false,
        actions: [
          const SyncStatusIcon(),
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
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text('Descargar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: ElegantLightTheme.primaryBlue),
                        const SizedBox(width: 8),
                        const Text('Compartir'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        body: ColoredBox(
          color: ElegantLightTheme.backgroundColor,
          child: Obx(() {
            if (controller.isLoading.value && !controller.hasBatches) {
              return const InventoryLoadingState('Cargando lotes...');
            }

            if (controller.hasError && !controller.hasBatches) {
              return InventoryErrorState(
                title: 'No se pudieron cargar los lotes',
                message: friendlyInventoryError(
                  controller.error.value,
                  what: 'los lotes',
                ),
                onRetry: controller.refreshBatches,
              );
            }

            return CustomScrollView(
              slivers: [
                // Product info header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: ElegantLightTheme.surfaceColor,
                    child: Column(
                      children: [
                        // Product details with sort button
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: ElegantLightTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Obx(
                                () => Text(
                                  controller.productName.value.isNotEmpty
                                      ? controller.productName.value
                                      : 'Producto',
                                  style: Get.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            // Sort button in top right
                            Obx(
                              () => PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'date_desc':
                                      controller.updateSort(
                                        'purchaseDate',
                                        'desc',
                                      );
                                      break;
                                    case 'date_asc':
                                      controller.updateSort(
                                        'purchaseDate',
                                        'asc',
                                      );
                                      break;
                                    case 'expiry_asc':
                                      controller.updateSort(
                                        'expirationDate',
                                        'asc',
                                      );
                                      break;
                                    case 'expiry_desc':
                                      controller.updateSort(
                                        'expirationDate',
                                        'desc',
                                      );
                                      break;
                                    case 'quantity_desc':
                                      controller.updateSort(
                                        'currentQuantity',
                                        'desc',
                                      );
                                      break;
                                    case 'quantity_asc':
                                      controller.updateSort(
                                        'currentQuantity',
                                        'asc',
                                      );
                                      break;
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        controller.hasCustomSort
                                            ? ElegantLightTheme.primaryBlue
                                                .withValues(alpha: 0.1)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          controller.hasCustomSort
                                              ? ElegantLightTheme.primaryBlue
                                                  .withValues(alpha: 0.3)
                                              : ElegantLightTheme.textTertiary
                                                  .withOpacity(0.3),
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
                                        color:
                                            controller.hasCustomSort
                                                ? ElegantLightTheme.primaryBlue
                                                : ElegantLightTheme
                                                    .textSecondary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        controller.getCurrentSortLabel(),
                                        style: Get.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 12,
                                              color:
                                                  controller.hasCustomSort
                                                      ? ElegantLightTheme
                                                          .primaryBlue
                                                      : ElegantLightTheme
                                                          .textSecondary,
                                              fontWeight:
                                                  controller.hasCustomSort
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'date_desc',
                                        child: _buildSortMenuItem(
                                          'Fecha: Más Reciente',
                                          'purchaseDate',
                                          'desc',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'date_asc',
                                        child: _buildSortMenuItem(
                                          'Fecha: Más Antiguo',
                                          'purchaseDate',
                                          'asc',
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'expiry_asc',
                                        child: _buildSortMenuItem(
                                          'Vencimiento: Próximo',
                                          'expirationDate',
                                          'asc',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'expiry_desc',
                                        child: _buildSortMenuItem(
                                          'Vencimiento: Lejano',
                                          'expirationDate',
                                          'desc',
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'quantity_desc',
                                        child: _buildSortMenuItem(
                                          'Cantidad: Mayor a Menor',
                                          'currentQuantity',
                                          'desc',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'quantity_asc',
                                        child: _buildSortMenuItem(
                                          'Cantidad: Menor a Mayor',
                                          'currentQuantity',
                                          'asc',
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Summary
                        Obx(
                          () => Text(
                            controller.summaryText,
                            style: Get.textTheme.bodyMedium?.copyWith(
                              color: ElegantLightTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search bar only
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Obx(
                      () => TextField(
                        controller: controller.searchTextController,
                        onChanged: controller.updateSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Buscar por número de lote o proveedor...',
                          filled: true,
                          fillColor: ElegantLightTheme.surfaceColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ElegantLightTheme.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon:
                              controller.isLoading.value &&
                                      controller.searchQuery.value.isNotEmpty
                                  ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: const EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ElegantLightTheme.primaryBlue,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: ElegantLightTheme.primaryBlue,
                                  ),
                          suffixIcon:
                              controller.searchQuery.value.isNotEmpty
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (controller
                                              .searchQuery
                                              .value
                                              .isNotEmpty &&
                                          !controller.isLoading.value)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ElegantLightTheme.primaryBlue
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${controller.inventoryBatches.length}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  ElegantLightTheme.primaryBlue,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Divider
                const SliverToBoxAdapter(child: Divider(height: 1)),

                // Tab bar
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: ElegantLightTheme.textTertiary.withOpacity(
                            0.3,
                          ),
                          width: 1,
                        ),
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
                          isMobile ? 8 : 12,
                        ),
                        child: Row(
                          children: List.generate(tabs.length, (index) {
                            final tab = tabs[index];
                            final isSelected =
                                controller.selectedTab.value == index;

                            Color getColor() {
                              switch (index) {
                                case 0:
                                  return ElegantLightTheme.primaryBlue;
                                case 1:
                                  return ElegantLightTheme.successGreen;
                                case 2:
                                  return ElegantLightTheme.warningOrange;
                                case 3:
                                  return ElegantLightTheme.textSecondary;
                                default:
                                  return ElegantLightTheme.primaryBlue;
                              }
                            }

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => controller.switchTab(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: EdgeInsets.only(
                                    right:
                                        index < tabs.length - 1
                                            ? (isMobile ? 4 : 8)
                                            : 0,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : 12,
                                    vertical: isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? getColor()
                                            : getColor().withValues(
                                              alpha: 0.08,
                                            ),
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 6 : 8,
                                    ),
                                  ),
                                  child:
                                      isMobile
                                          ?
                                          // Layout móvil - compacto, con nombre
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    tab['icon'],
                                                    size: 13,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : getColor(),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${tab['count']}',
                                                    style: TextStyle(
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : getColor(),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                tab['title'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : getColor(),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          )
                                          :
                                          // Layout desktop - normal
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    tab['icon'],
                                                    size: 16,
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : getColor(),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tab['title'],
                                                    style: TextStyle(
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : getColor(),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Column(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  )
                                                              : getColor()
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${tab['count']}',
                                                      style: TextStyle(
                                                        color:
                                                            isSelected
                                                                ? Colors.white
                                                                : getColor(),
                                                        fontWeight:
                                                            FontWeight.w700,
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
                      final searching = controller.searchQuery.value.isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: InventoryEmptyState(
                          icon:
                              searching
                                  ? Icons.search_off
                                  : Icons.inventory_2_outlined,
                          title:
                              searching
                                  ? 'Sin resultados de búsqueda'
                                  : 'Sin lotes disponibles',
                          message:
                              searching
                                  ? 'No se encontraron lotes que coincidan con "${controller.searchQuery.value}"'
                                  : 'No se encontraron lotes que coincidan con los filtros aplicados.',
                          actionLabel: searching ? 'Limpiar búsqueda' : null,
                          actionIcon: Icons.clear,
                          onAction:
                              searching
                                  ? () => controller.updateSearchQuery('')
                                  : null,
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
                              child: BrebInlineLoading('Cargando más lotes...'),
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
                              onPurchaseOrderTap:
                                  batch.purchaseOrderId != null
                                      ? () => controller.goToPurchaseOrder(
                                        batch.purchaseOrderId,
                                      )
                                      : null,
                              onSupplierTap:
                                  batch.supplierId != null
                                      ? () => controller.goToSupplierDetail(
                                        batch.supplierId,
                                      )
                                      : null,
                            ),
                          );
                        },
                        childCount:
                            controller.inventoryBatches.length +
                            (controller.isLoadingMore.value ? 1 : 0),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String sortBy, String sortOrder) {
    final isSelected =
        controller.sortBy.value == sortBy &&
        controller.sortOrder.value == sortOrder;

    return Row(
      children: [
        Icon(
          sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
          color:
              isSelected
                  ? ElegantLightTheme.primaryBlue
                  : ElegantLightTheme.textTertiary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? ElegantLightTheme.primaryBlue : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(Icons.check, color: ElegantLightTheme.primaryBlue, size: 16),
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
                color: ElegantLightTheme.textTertiary.withOpacity(0.3),
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
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart,
                  color: ElegantLightTheme.successGreen,
                  size: 20,
                ),
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
                  color: ElegantLightTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: ElegantLightTheme.errorRed,
                  size: 20,
                ),
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
                color: ElegantLightTheme.textTertiary.withOpacity(0.3),
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
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart,
                  color: ElegantLightTheme.primaryBlue,
                  size: 20,
                ),
              ),
              title: const Text('Compartir Excel'),
              subtitle: const Text(
                'Enviar archivo .xlsx por WhatsApp, Email, etc.',
              ),
              onTap: () {
                Get.back();
                controller.exportBatchesToExcel();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: ElegantLightTheme.warningOrange,
                  size: 20,
                ),
              ),
              title: const Text('Compartir PDF'),
              subtitle: const Text(
                'Enviar reporte .pdf por WhatsApp, Email, etc.',
              ),
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
              _buildDetailRow(
                'Fecha de Entrada:',
                AppFormatters.formatDate(batch.entryDate),
              ),
              if (batch.hasExpiry)
                _buildDetailRow(
                  'Fecha de Vencimiento:',
                  AppFormatters.formatDate(batch.expiryDate!),
                ),
              _buildDetailRow(
                'Cantidad Inicial:',
                '${batch.originalQuantity} unidades',
              ),
              _buildDetailRow(
                'Cantidad Actual:',
                '${batch.currentQuantity} unidades',
              ),
              _buildDetailRow(
                'Costo Unitario:',
                AppFormatters.formatCurrency(batch.unitCost),
              ),
              _buildDetailRow(
                'Valor Total:',
                AppFormatters.formatCurrency(batch.currentValue),
              ),
              if (batch.supplierName != null)
                _buildDetailRow('Proveedor:', batch.supplierName!),
              if (batch.purchaseOrderNumber != null)
                _buildDetailRow('Orden de Compra:', batch.purchaseOrderNumber!),
              _buildDetailRow(
                'Estado:',
                controller.getBatchStatusIcon(batch).toString(),
              ),
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
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
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
          Expanded(child: Text(value, style: Get.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
