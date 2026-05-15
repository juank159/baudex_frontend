import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../controllers/initial_inventory_controller.dart';
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';

class InitialInventoryScreen extends GetView<InitialInventoryController> {
  const InitialInventoryScreen({super.key});

  static final _listScrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return MainLayout(
      title: 'Inventario Inicial',
      showDrawer: true,
      body: Column(
        children: [
          _buildHeader(context, isMobile),
          _buildSearchAndDuplicatesBar(context, isMobile),
          Obx(() => controller.isSubmitting.value
              ? _buildProgress(context)
              : const SizedBox.shrink()),
          Expanded(
            child: Obx(() {
              if (controller.rows.isEmpty) return _buildEmpty(context);
              return ResponsiveBuilder(
                mobile: _buildExpandableList(context),
                desktop: _buildDesktopTable(context),
              );
            }),
          ),
          _buildFooter(context, isMobile),
        ],
      ),
    );
  }

  // ==========================================================================
  // HEADER - compact, responsive
  // ==========================================================================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final hPad = isMobile ? 10.0 : 16.0;
    final vPad = isMobile ? 10.0 : 16.0;

    return Container(
      margin: EdgeInsets.fromLTRB(hPad, hPad, hPad, 4),
      padding: EdgeInsets.all(vPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 10),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.white, size: isMobile ? 16 : 22),
              ),
              SizedBox(width: isMobile ? 8 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventario Inicial',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 20,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Obx(() {
                      if (!controller.hasDraft.value) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.save_outlined, size: 12, color: ElegantLightTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Borrador: ${controller.draftRowCount.value} productos',
                              style: TextStyle(fontSize: 11, color: ElegantLightTheme.primaryBlue),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Save draft button
              Obx(() {
                if (controller.isSubmitting.value) return const SizedBox.shrink();
                return Tooltip(
                  message: 'Guardar borrador',
                  child: InkWell(
                    onTap: () async {
                      await controller.saveDraft();
                      Get.snackbar(
                        'Guardado',
                        'Borrador guardado correctamente',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: ElegantLightTheme.successGreen,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(8),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.save, size: 20, color: ElegantLightTheme.primaryBlue),
                    ),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 14),
          // Action bar
          Obx(() => _buildActions(context, isMobile, controller.isSubmitting.value)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isMobile, bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category row
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: controller.useGlobalCategory.value,
                onChanged: isSubmitting
                    ? null
                    : (v) => controller.toggleUseGlobalCategory(v ?? false),
                activeColor: ElegantLightTheme.primaryBlue,
                checkColor: Colors.white,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6),
            Text('Cat. global', style: TextStyle(fontSize: 12, color: ElegantLightTheme.textPrimary)),
            if (controller.useGlobalCategory.value) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryDropdown(isSubmitting)),
            ] else
              const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        // Buttons
        Obx(() {
          final canAdd = controller.canAddNewRow;
          final disabledMsg = canAdd
              ? ''
              : 'Completa todos los campos antes de agregar nuevas filas';
          return Row(
            children: [
              Tooltip(
                message: disabledMsg,
                child: _actionChip(
                  Icons.add,
                  'Fila',
                  (isSubmitting || !canAdd)
                      ? null
                      : () {
                          controller.addRow();
                          _scrollToBottom();
                        },
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: disabledMsg,
                child: _actionChip(
                  Icons.playlist_add,
                  '+10',
                  (isSubmitting || !canAdd)
                      ? null
                      : () {
                          controller.addMultipleRows(10);
                          _scrollToBottom();
                        },
                ),
              ),
              if (!isMobile) ...[
                const Spacer(),
                Text(
                  '${controller.rows.length} producto${controller.rows.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 12,
                      color: ElegantLightTheme.textSecondary),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: enabled ? ElegantLightTheme.primaryGradient : null,
          color: enabled ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: enabled ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: enabled ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isSubmitting) {
    final validValue = controller.availableCategories.any((c) => c.id == controller.globalCategoryId.value)
        ? controller.globalCategoryId.value
        : null;
    final hasCategory = validValue != null;
    final selectedName = hasCategory
        ? controller.availableCategories.firstWhere((c) => c.id == validValue).name
        : null;

    return PopupMenuButton<String>(
      enabled: !isSubmitting,
      onSelected: (v) {
        final cat = controller.availableCategories.firstWhere((c) => c.id == v);
        controller.setGlobalCategory(cat.id, cat.name);
      },
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 6,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      itemBuilder: (_) => controller.availableCategories.map((c) {
        final isSelected = c.id == validValue;
        return PopupMenuItem<String>(
          value: c.id,
          height: 40,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ElegantLightTheme.primaryBlue.withOpacity(0.12)
                      : ElegantLightTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.category_outlined,
                  size: 15,
                  color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 32,
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasCategory ? ElegantLightTheme.primaryBlue.withOpacity(0.06) : Colors.white,
          border: Border.all(
            color: hasCategory
                ? ElegantLightTheme.primaryBlue.withOpacity(0.4)
                : ElegantLightTheme.textTertiary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              hasCategory ? Icons.check_circle : Icons.category_outlined,
              size: 14,
              color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selectedName ?? 'Seleccionar categoría',
                style: TextStyle(
                  fontSize: 12,
                  color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
                  fontWeight: hasCategory ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18, color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SEARCH BAR + BANNER DE DUPLICADOS (siempre visibles)
  // ==========================================================================

  Widget _buildSearchAndDuplicatesBar(BuildContext context, bool isMobile) {
    final hPad = isMobile ? 10.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchBar(isMobile),
          Obx(() {
            if (controller.duplicateIndices.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildDuplicatesBanner(),
            );
          }),
          Obx(() {
            if (controller.incompleteRowIndices.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildIncompleteBanner(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIncompleteBanner() {
    final count = controller.incompleteRowIndices.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count fila(s) con campos vacíos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                Text(
                  'Completa nombre, código de barras, costo, precio, stock y mín para continuar: ${controller.incompleteSummary}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF78350F),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Obx(() {
      final query = controller.searchQuery.value;
      final isSearching = query.isNotEmpty;
      final totalRows = controller.rows.length;
      final matched = controller.filteredRowIndices.length;

      return Container(
        height: isMobile ? 42 : 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSearching
                ? ElegantLightTheme.primaryBlue
                : ElegantLightTheme.primaryBlue.withOpacity(0.35),
            width: isSearching ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue
                  .withOpacity(isSearching ? 0.18 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(
              Icons.search,
              size: 20,
              color: isSearching
                  ? ElegantLightTheme.primaryBlue
                  : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: (v) => controller.searchQuery.value = v,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: totalRows > 0
                      ? 'Buscar en $totalRows fila${totalRows == 1 ? '' : 's'} (nombre o código de barras)…'
                      : 'Buscar productos agregados (nombre o código)…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: ElegantLightTheme.textTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (isSearching) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: matched > 0
                      ? ElegantLightTheme.primaryBlue.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$matched',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: matched > 0
                        ? ElegantLightTheme.primaryBlue
                        : Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: controller.clearSearch,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ),
            ] else
              const SizedBox(width: 10),
          ],
        ),
      );
    });
  }

  Widget _buildDuplicatesBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded,
              size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${controller.duplicateIndices.length} producto(s) repetido(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  'No podrás crear hasta eliminarlos: ${controller.duplicatesSummary}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7F1D1D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PROGRESS
  // ==========================================================================

  Widget _buildProgress(BuildContext context) {
    return Obx(() {
      final total = controller.rows.where((r) => !r.isEmpty).length;
      final current = controller.currentProcessingIndex.value;
      final progress = total > 0 ? current / total : 0.0;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Procesando...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary)),
                const Spacer(),
                Icon(Icons.check_circle, size: 13, color: Colors.green[600]),
                Text(' ${controller.successCount.value}', style: TextStyle(fontSize: 11, color: Colors.green[700])),
                const SizedBox(width: 8),
                Icon(Icons.error, size: 13, color: Colors.red[600]),
                Text(' ${controller.failedCount.value}', style: TextStyle(fontSize: 11, color: Colors.red[700])),
                const SizedBox(width: 8),
                Text('$current/$total', style: TextStyle(fontSize: 11, color: ElegantLightTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ElegantProgressIndicator(progress: progress, gradient: ElegantLightTheme.primaryGradient),
          ],
        ),
      );
    });
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: ElegantLightTheme.textTertiary),
          const SizedBox(height: 12),
          Text('Sin productos', style: TextStyle(fontSize: 14, color: ElegantLightTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('Agrega filas para comenzar', style: TextStyle(fontSize: 12, color: ElegantLightTheme.textTertiary)),
        ],
      ),
    );
  }

  // ==========================================================================
  // EXPANDABLE LIST (Mobile + Tablet)
  // ==========================================================================

  Widget _buildExpandableList(BuildContext context) {
    return Obx(() {
      final filteredIndices = controller.filteredRowIndices;
      final isSearching = controller.searchQuery.value.isNotEmpty;

      if (isSearching && filteredIndices.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 40, color: ElegantLightTheme.textTertiary),
                const SizedBox(height: 10),
                Text(
                  'Sin resultados para "${controller.searchQuery.value}"',
                  style: TextStyle(
                      fontSize: 13, color: ElegantLightTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: controller.clearSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Limpiar búsqueda',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        controller: _listScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: filteredIndices.length,
        itemBuilder: (_, listIndex) =>
            _buildExpandableItem(context, filteredIndices[listIndex]),
      );
    });
  }

  Widget _buildExpandableItem(BuildContext context, int index) {
    final row = controller.rows[index];
    final isSubmitting = controller.isSubmitting.value;
    final useGlobal = controller.useGlobalCategory.value;
    final isDuplicate = controller.duplicateIndices.contains(index);

    // Border color by status (duplicate gana prioridad visual)
    Color borderColor = ElegantLightTheme.textTertiary.withOpacity(0.15);
    Color? bgColor;
    double borderWidth = 1;
    if (isDuplicate) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
      borderWidth = 2.5;
    } else if (row.isProcessed && row.isSuccess) {
      borderColor = Colors.green[400]!;
      bgColor = Colors.green[50];
      borderWidth = 1.5;
    } else if (row.isProcessed && row.errorMessage != null) {
      borderColor = Colors.red[400]!;
      bgColor = Colors.red[50];
      borderWidth = 1.5;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 6, top: isDuplicate ? 10 : 0),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isDuplicate
                ? [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // COLLAPSED HEADER (always visible)
          GestureDetector(
            onTap: isSubmitting ? null : () => controller.toggleExpand(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Index badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text('${index + 1}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  // Name + summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.nameController.text.isEmpty ? 'Producto ${index + 1}' : row.nameController.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!row.isExpanded) ...[
                          const SizedBox(height: 1),
                          Text(
                            _buildCollapsedSummary(row),
                            style: TextStyle(fontSize: 11, color: ElegantLightTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status or actions
                  if (row.isProcessed && row.isSuccess)
                    Icon(Icons.check_circle, size: 18, color: Colors.green[500])
                  else if (row.errorMessage != null)
                    Tooltip(
                      message: row.errorMessage!,
                      child: Icon(Icons.error, size: 18, color: Colors.red[500]),
                    )
                  else ...[
                    // Quick delete
                    if (!isSubmitting)
                      InkWell(
                        onTap: () => controller.removeRow(index),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 16, color: Colors.red[300]),
                        ),
                      ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    row.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // EXPANDED CONTENT
          if (row.isExpanded) _buildExpandedContent(context, index, row, isSubmitting, useGlobal),
        ],
      ),
        ),
        if (isDuplicate)
          Positioned(
            top: 0,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_rounded,
                      size: 11, color: Colors.white),
                  const SizedBox(width: 3),
                  const Text(
                    'REPETIDO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: isSubmitting
                        ? null
                        : () => controller.removeRow(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 9,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _buildCollapsedSummary(InitialInventoryRow row) {
    final parts = <String>[];
    final stock = row.stockController.text.trim();
    final cost = row.costPriceController.text.trim();
    final price = row.sellingPriceController.text.trim();
    final barcode = row.barcodeController.text.trim();
    if (stock.isNotEmpty) parts.add('Stock: $stock');
    if (cost.isNotEmpty) parts.add('C: $cost');
    if (price.isNotEmpty) parts.add('P: $price');
    if (barcode.isNotEmpty) parts.add(barcode);
    return parts.isEmpty ? 'Toca para editar' : parts.join(' • ');
  }

  Widget _buildExpandedContent(
      BuildContext context, int index, InitialInventoryRow row, bool isSubmitting, bool useGlobal) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final missing = controller.missingFieldsFor(index);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: ElegantLightTheme.textTertiary.withOpacity(0.15)),
          const SizedBox(height: 8),
          // Row 1: Name
          _inlineField(row.nameController, 'Nombre del producto *',
              isSubmitting,
              isMissing: missing.contains('name')),
          const SizedBox(height: 8),
          // Row 2: Barcode (con escáner en mobile)
          _buildBarcodeField(row, isSubmitting, isMobile,
              isMissing: missing.contains('barcode')),
          const SizedBox(height: 8),
          // Row 3: Cost + Price
          Row(
            children: [
              Expanded(
                child: _inlineNumberField(
                    row.costPriceController, 'Costo *', isSubmitting,
                    isMissing: missing.contains('costPrice')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inlineNumberField(row.sellingPriceController,
                    'Precio venta *', isSubmitting,
                    isMissing: missing.contains('sellingPrice')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 4: Stock + MinStock
          Row(
            children: [
              Expanded(
                child: _inlineNumberField(
                    row.stockController, 'Stock inicial *', isSubmitting,
                    isMissing: missing.contains('stock')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inlineNumberField(
                    row.minStockController, 'Stock mín *', isSubmitting,
                    isMissing: missing.contains('minStock')),
              ),
            ],
          ),
          // Row 5: Category (if not global)
          if (!useGlobal) ...[
            const SizedBox(height: 8),
            _inlineCategorySelector(index, row, isSubmitting),
          ],
          const SizedBox(height: 8),
          // Row 6: Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionChip(Icons.copy, 'Duplicar', isSubmitting ? null : () => controller.duplicateRow(index)),
              const SizedBox(width: 8),
              InkWell(
                onTap: isSubmitting ? null : () => controller.removeRow(index),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.errorGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Eliminar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inlineField(
    TextEditingController ctrl,
    String label,
    bool disabled, {
    bool isMissing = false,
  }) {
    final errorColor = const Color(0xFFEF4444);
    final baseColor = isMissing
        ? errorColor
        : ElegantLightTheme.textTertiary.withOpacity(0.3);
    final focusedColor =
        isMissing ? errorColor : ElegantLightTheme.primaryBlue;
    return TextField(
      controller: ctrl,
      enabled: !disabled,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 11,
          color: isMissing ? errorColor : ElegantLightTheme.textSecondary,
          fontWeight: isMissing ? FontWeight.w700 : FontWeight.w400,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: baseColor, width: isMissing ? 1.5 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: focusedColor, width: 1.8),
        ),
      ),
    );
  }

  Widget _inlineNumberField(
    TextEditingController ctrl,
    String label,
    bool disabled, {
    bool isMissing = false,
  }) {
    final errorColor = const Color(0xFFEF4444);
    final baseColor = isMissing
        ? errorColor
        : ElegantLightTheme.textTertiary.withOpacity(0.3);
    final focusedColor =
        isMissing ? errorColor : ElegantLightTheme.primaryBlue;
    return TextField(
      controller: ctrl,
      enabled: !disabled,
      style: const TextStyle(fontSize: 13),
      keyboardType: TextInputType.number,
      inputFormatters: [PriceInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 11,
          color: isMissing ? errorColor : ElegantLightTheme.textSecondary,
          fontWeight: isMissing ? FontWeight.w700 : FontWeight.w400,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: baseColor, width: isMissing ? 1.5 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: focusedColor, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildBarcodeField(
    InitialInventoryRow row,
    bool isSubmitting,
    bool isMobile, {
    bool isMissing = false,
  }) {
    final errorColor = const Color(0xFFEF4444);
    final baseColor = isMissing
        ? errorColor
        : ElegantLightTheme.textTertiary.withOpacity(0.3);
    final focusedColor =
        isMissing ? errorColor : ElegantLightTheme.primaryBlue;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: row.barcodeController,
            enabled: !isSubmitting,
            style: const TextStyle(fontSize: 13),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Código de barras *',
              labelStyle: TextStyle(
                fontSize: 11,
                color: isMissing
                    ? errorColor
                    : ElegantLightTheme.textSecondary,
                fontWeight:
                    isMissing ? FontWeight.w700 : FontWeight.w400,
              ),
              prefixIcon: Icon(Icons.barcode_reader,
                  size: 18,
                  color: isMissing ? errorColor : null),
              prefixIconConstraints: const BoxConstraints(minWidth: 36),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                    color: baseColor, width: isMissing ? 1.5 : 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: focusedColor, width: 1.8),
              ),
            ),
          ),
        ),
        if (isMobile) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'Escanear código',
            child: InkWell(
              onTap: isSubmitting
                  ? null
                  : () async {
                      final scannedCode = await Get.to<String>(
                        () => const BarcodeScannerScreen(),
                      );
                      if (scannedCode != null && scannedCode.isNotEmpty) {
                        row.barcodeController.text = scannedCode;
                      }
                    },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _inlineCategorySelector(int index, InitialInventoryRow row, bool isSubmitting) {
    final validValue = controller.availableCategories.any((c) => c.id == row.categoryId)
        ? row.categoryId
        : null;
    final hasCategory = validValue != null;
    final selectedName = hasCategory
        ? controller.availableCategories.firstWhere((c) => c.id == validValue).name
        : null;

    return PopupMenuButton<String>(
      enabled: !isSubmitting,
      onSelected: (v) {
        final cat = controller.availableCategories.firstWhere((c) => c.id == v);
        controller.setRowCategory(index, cat.id, cat.name);
      },
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 6,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      itemBuilder: (_) => controller.availableCategories.map((c) {
        final isSelected = c.id == validValue;
        return PopupMenuItem<String>(
          value: c.id,
          height: 40,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ElegantLightTheme.primaryBlue.withOpacity(0.12)
                      : ElegantLightTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.category_outlined,
                  size: 15,
                  color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasCategory ? ElegantLightTheme.primaryBlue.withOpacity(0.06) : Colors.white,
          border: Border.all(
            color: hasCategory
                ? ElegantLightTheme.primaryBlue.withOpacity(0.4)
                : ElegantLightTheme.textTertiary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              hasCategory ? Icons.check_circle : Icons.category_outlined,
              size: 15,
              color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedName ?? 'Categoría',
                style: TextStyle(
                  fontSize: 12,
                  color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
                  fontWeight: hasCategory ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DESKTOP TABLE
  // ==========================================================================

  Widget _buildDesktopTable(BuildContext context) {
    return ElegantContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(() => _buildDataTable()),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final isSubmitting = controller.isSubmitting.value;
    final useGlobal = controller.useGlobalCategory.value;
    final filteredIndices = controller.filteredRowIndices;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(ElegantLightTheme.scaffoldBackground.withOpacity(0.5)),
      columnSpacing: 12,
      horizontalMargin: 10,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 48,
      columns: [
        _col('#', 36),
        _col('Nombre', 190),
        _col('Cód. Barras', 140),
        _col('Costo', 100),
        _col('Precio', 100),
        _col('Stock', 80),
        _col('Mín', 70),
        if (!useGlobal) _col('Categoría', 140),
        _col('', 80),
      ],
      rows: filteredIndices
          .map((i) => _desktopRow(i, isSubmitting, useGlobal))
          .toList(),
    );
  }

  DataColumn _col(String text, double width) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ElegantLightTheme.textPrimary)),
      ),
    );
  }

  DataRow _desktopRow(int index, bool isSubmitting, bool useGlobal) {
    final row = controller.rows[index];
    final isDuplicate = controller.duplicateIndices.contains(index);
    Color? color;
    if (isDuplicate) {
      color = const Color(0xFFFEF2F2); // rojo claro — duplicado
    } else if (row.isProcessed && row.isSuccess) {
      color = Colors.green[50];
    } else if (row.isProcessed && row.errorMessage != null) {
      color = Colors.red[50];
    }

    return DataRow(
      color: WidgetStateProperty.all(color),
      cells: [
        DataCell(Container(
          width: 36,
          alignment: Alignment.center,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: isDuplicate
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                    )
                  : ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: isDuplicate
                ? const Tooltip(
                    message: 'Producto repetido — elimínalo para continuar',
                    child: Icon(Icons.warning_rounded,
                        size: 12, color: Colors.white),
                  )
                : Text('${index + 1}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        )),
        DataCell(_dtField(row.nameController, 190, isSubmitting,
            isMissing: controller.missingFieldsFor(index).contains('name'))),
        DataCell(_dtField(row.barcodeController, 140, isSubmitting,
            isMissing: controller.missingFieldsFor(index).contains('barcode'))),
        DataCell(_dtNumField(row.costPriceController, 100, isSubmitting,
            isMissing: controller.missingFieldsFor(index).contains('costPrice'))),
        DataCell(_dtNumField(row.sellingPriceController, 100, isSubmitting,
            isMissing:
                controller.missingFieldsFor(index).contains('sellingPrice'))),
        DataCell(_dtNumField(row.stockController, 80, isSubmitting,
            isMissing: controller.missingFieldsFor(index).contains('stock'))),
        DataCell(_dtNumField(row.minStockController, 70, isSubmitting,
            isMissing:
                controller.missingFieldsFor(index).contains('minStock'))),
        if (!useGlobal) DataCell(_dtCatCell(index, row, isSubmitting)),
        DataCell(_dtActions(index, row, isSubmitting)),
      ],
    );
  }

  Widget _dtField(TextEditingController ctrl, double w, bool disabled,
      {bool isMissing = false}) {
    return SizedBox(
      width: w,
      child: TextField(
        controller: ctrl,
        enabled: !disabled,
        style: const TextStyle(fontSize: 12),
        decoration: _dtDecoration(isMissing: isMissing),
      ),
    );
  }

  Widget _dtNumField(TextEditingController ctrl, double w, bool disabled,
      {bool isMissing = false}) {
    return SizedBox(
      width: w,
      child: TextField(
        controller: ctrl,
        enabled: !disabled,
        style: const TextStyle(fontSize: 12),
        keyboardType: TextInputType.number,
        inputFormatters: [PriceInputFormatter()],
        decoration: _dtDecoration(isMissing: isMissing),
      ),
    );
  }

  InputDecoration _dtDecoration({bool isMissing = false}) {
    const errorColor = Color(0xFFEF4444);
    final baseColor = isMissing
        ? errorColor
        : ElegantLightTheme.textTertiary.withOpacity(0.25);
    final focusedColor =
        isMissing ? errorColor : ElegantLightTheme.primaryBlue;
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      filled: isMissing,
      fillColor: isMissing ? const Color(0xFFFEF2F2) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide:
            BorderSide(color: baseColor, width: isMissing ? 1.5 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: focusedColor, width: 1.8),
      ),
    );
  }

  Widget _dtCatCell(int index, InitialInventoryRow row, bool isSubmitting) {
    final validValue = controller.availableCategories.any((c) => c.id == row.categoryId)
        ? row.categoryId
        : null;
    final hasCategory = validValue != null;
    final selectedName = hasCategory
        ? controller.availableCategories.firstWhere((c) => c.id == validValue).name
        : null;

    return SizedBox(
      width: 140,
      child: PopupMenuButton<String>(
        enabled: !isSubmitting,
        onSelected: (v) {
          final cat = controller.availableCategories.firstWhere((c) => c.id == v);
          controller.setRowCategory(index, cat.id, cat.name);
        },
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        itemBuilder: (_) => controller.availableCategories.map((c) {
          final isSelected = c.id == validValue;
          return PopupMenuItem<String>(
            value: c.id,
            height: 36,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.category_outlined,
                  size: 14,
                  color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: hasCategory ? ElegantLightTheme.primaryBlue.withOpacity(0.06) : null,
            border: Border.all(
              color: hasCategory
                  ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                  : ElegantLightTheme.textTertiary.withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedName ?? 'Categoría',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary,
                    fontWeight: hasCategory ? FontWeight.w500 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 14, color: hasCategory ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dtActions(int index, InitialInventoryRow row, bool isSubmitting) {
    if (row.isProcessed && row.isSuccess) {
      return SizedBox(
        width: 80,
        child: Row(children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
          const SizedBox(width: 3),
          Text('OK', style: TextStyle(fontSize: 11, color: Colors.green[700])),
        ]),
      );
    }
    if (row.errorMessage != null) {
      return SizedBox(
        width: 80,
        child: Tooltip(
          message: row.errorMessage!,
          child: Row(children: [
            Icon(Icons.error, size: 14, color: Colors.red[600]),
            const SizedBox(width: 3),
            Expanded(child: Text('Error', style: TextStyle(fontSize: 11, color: Colors.red[700]), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
    }
    return SizedBox(
      width: 80,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            tooltip: 'Duplicar',
            onPressed: isSubmitting ? null : () => controller.duplicateRow(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 14, color: Colors.red[400]),
            tooltip: 'Eliminar',
            onPressed: isSubmitting ? null : () => controller.removeRow(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FOOTER
  // ==========================================================================

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 8 : 12),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(() {
        final isSubmitting = controller.isSubmitting.value;
        final count = controller.rows.length;

        return Row(
          children: [
            // Clear button
            InkWell(
              onTap: isSubmitting ? null : controller.confirmResetAll,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: ElegantLightTheme.errorRed.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all, size: 16, color: ElegantLightTheme.errorRed),
                    if (!isMobile) ...[
                      const SizedBox(width: 4),
                      Text('Limpiar', style: TextStyle(fontSize: 12, color: ElegantLightTheme.errorRed, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
            if (isMobile)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ElegantLightTheme.textSecondary),
                ),
              ),
            const Spacer(),
            // Submit button (se bloquea si hay duplicados o filas incompletas)
            Obx(() {
              final hasDupes = controller.duplicateIndices.isNotEmpty;
              final hasIncomplete = controller.incompleteRowIndices.isNotEmpty;
              final blocked = hasDupes || hasIncomplete;
              final tooltipMsg = hasDupes
                  ? 'Hay productos repetidos. Elimínalos para continuar.'
                  : hasIncomplete
                      ? 'Hay filas con campos vacíos. Complétalos para continuar.'
                      : '';
              return Tooltip(
                message: tooltipMsg,
                child: ElegantButton(
                  text: isSubmitting
                      ? 'Procesando...'
                      : (isMobile ? 'Crear' : 'Crear Productos'),
                  icon: isSubmitting ? null : Icons.check,
                  gradient: blocked
                      ? ElegantLightTheme.errorGradient
                      : ElegantLightTheme.successGradient,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting || count == 0 || blocked
                      ? null
                      : controller.submitAll,
                  height: isMobile ? 38 : 40,
                  padding:
                      EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}
