// lib/features/inventory/presentation/screens/inventory_transfers_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/inventory_transfers_controller.dart';
import '../widgets/futuristic_transfer_form_widget.dart';
import '../widgets/futuristic_transfers_list_widget.dart';

class InventoryTransfersScreen extends GetView<InventoryTransfersController> {
  const InventoryTransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isLoading.value
        ? _buildLoadingState()
        : controller.hasError
            ? _buildErrorState()
            : MainLayout(
                title: controller.displayTitle,
                showBackButton: true,
                showDrawer: false,
                actions: _buildAppBarActions(context),
                body: _buildFuturisticContent(context),
              ));
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.refreshTransfers,
        tooltip: 'Actualizar',
      ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => Get.toNamed(AppRoutes.inventoryTransfersCreate),
        tooltip: 'Nueva Transferencia',
      ),
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
                Icon(Icons.download, color: ElegantLightTheme.primaryBlue),
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
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.backgroundColor.withOpacity(0.95),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        'Cargando transferencias...',
                        style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        'Preparando gestión',
                        style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                          color: ElegantLightTheme.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: FuturisticContainer(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              controller.error.value,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 20),
            FuturisticButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              onPressed: controller.refreshTransfers,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con estadísticas
            _buildFuturisticHeader(),
            const SizedBox(height: 24),
            
            // Form section (collapsible)
            Obx(() => AnimatedContainer(
              duration: ElegantLightTheme.normalAnimation,
              height: controller.showForm.value ? null : 0,
              child: controller.showForm.value
                  ? Column(
                      children: [
                        const FuturisticTransferFormWidget(),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox.shrink(),
            )),
            
            // Tabs futuristas para filtros
            _buildFuturisticFilterTabs(),
            const SizedBox(height: 24),
            
            // Lista de transferencias o estado vacío
            Obx(() {
              if (!controller.hasTransfers) {
                return _buildEmptyState();
              }
              return const FuturisticTransfersListWidget();
            }),
            
            // Espacio adicional al final
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticHeader() {
    return FuturisticContainer(
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transferencias de Inventario',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestiona el movimiento entre almacenes',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFuturisticFilterTabs() {
    return FuturisticContainer(
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterTab('Todas', 'all', Icons.list),
              _buildFilterTab('Hoy', 'today', Icons.today),
              _buildFilterTab('Esta Semana', 'week', Icons.date_range),
              _buildFilterTab('Este Mes', 'month', Icons.calendar_month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String filterKey, IconData icon) {
    return Obx(() {
      final isSelected = controller.currentFilter.value == filterKey;
      
      // Obtener el conteo según el filtro
      String count = '0';
      Color iconColor = ElegantLightTheme.textSecondary;
      
      switch (filterKey) {
        case 'all':
          count = '${controller.totalTransfers}';
          iconColor = isSelected ? Colors.white : ElegantLightTheme.infoGradient.colors.first;
          break;
        case 'today':
          count = '${controller.todayTransfers}';
          iconColor = isSelected ? Colors.white : ElegantLightTheme.successGradient.colors.first;
          break;
        case 'week':
          count = '${controller.weekTransfers}';
          iconColor = isSelected ? Colors.white : ElegantLightTheme.primaryGradient.colors.first;
          break;
        case 'month':
          count = '${controller.monthTransfers}';
          iconColor = isSelected ? Colors.white : ElegantLightTheme.warningGradient.colors.first;
          break;
      }
      
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.setFilter(filterKey),
          child: AnimatedContainer(
            duration: ElegantLightTheme.normalAnimation,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
              border: !isSelected ? Border.all(
                color: ElegantLightTheme.textSecondary.withOpacity(0.2),
              ) : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }


  Widget _buildEmptyState() {
    return FuturisticContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.swap_horiz,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin transferencias',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No se han registrado transferencias entre almacenes.\nComienza creando tu primera transferencia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          FuturisticButton(
            text: 'Nueva Transferencia',
            icon: Icons.add,
            onPressed: () => Get.toNamed(AppRoutes.inventoryTransfersCreate),
          ),
        ],
      ),
    );
  }

  void _showDownloadOptions() {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(Get.context!).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 10),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  offset: const Offset(0, 0),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header elegante
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ElegantLightTheme.primaryBlue.withOpacity(0.1),
                          ElegantLightTheme.primaryBlue.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.cloud_download,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Descargar Archivo',
                            style: TextStyle(
                              color: ElegantLightTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.close,
                            color: ElegantLightTheme.textSecondary,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: ElegantLightTheme.textSecondary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Opciones de descarga
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildModernDownloadOption(
                          'Excel',
                          'Hoja de cálculo (.xlsx)',
                          'Perfecto para análisis de datos',
                          Icons.table_chart,
                          ElegantLightTheme.successGradient,
                          controller.downloadTransfersToExcel,
                        ),
                        const SizedBox(height: 16),
                        _buildModernDownloadOption(
                          'PDF',
                          'Documento portátil (.pdf)',
                          'Ideal para reportes e impresión',
                          Icons.picture_as_pdf,
                          ElegantLightTheme.errorGradient,
                          controller.downloadTransfersToPdf,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernDownloadOption(
    String title,
    String format,
    String description,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Get.back();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient.colors.first.withOpacity(0.05),
              gradient.colors.last.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient.colors.first.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format,
                    style: TextStyle(
                      color: gradient.colors.first,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradient.colors.first.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.download,
                color: gradient.colors.first,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Compartir Transferencias',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte los archivos por WhatsApp, Email, etc.',
              style: Get.textTheme.bodySmall?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildShareOption(
              'Compartir Excel',
              'Enviar archivo .xlsx por WhatsApp, Email, etc.',
              Icons.table_chart,
              Colors.blue,
              () {
                Get.back();
                controller.exportTransfersToExcel();
              },
            ),
            _buildShareOption(
              'Compartir PDF',
              'Enviar reporte .pdf por WhatsApp, Email, etc.',
              Icons.picture_as_pdf,
              Colors.orange,
              () {
                Get.back();
                controller.exportTransfersToPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: Get.textTheme.titleSmall?.copyWith(
            color: ElegantLightTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Get.textTheme.bodySmall?.copyWith(
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
}