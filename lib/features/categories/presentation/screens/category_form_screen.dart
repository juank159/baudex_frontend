// lib/features/categories/presentation/screens/category_form_screen.dart
import 'package:baudex_desktop/features/categories/domain/entities/category_tree.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../controllers/category_form_controller.dart';
import '../../domain/entities/category.dart';

class CategoryFormScreen extends GetView<CategoryFormController> {
  const CategoryFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildFuturisticAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fondo con patrón de partículas
            Positioned.fill(
              child: CustomPaint(
                painter: FuturisticParticlesPainter(),
              ),
            ),
            // Contenido principal
            SafeArea(
              child: Obx(() {
                // Mostrar loading específico cuando carga categoría para editar
                if (controller.isLoadingCategory) {
                  return _buildFuturisticLoadingState();
                }

                // Mostrar loading general en modo edición si no hay categoría cargada
                if (controller.isLoading &&
                    controller.isEditMode &&
                    !controller.hasCategory) {
                  return _buildFuturisticLoadingState();
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isDesktop = screenWidth >= 1200;
                    final isTablet = screenWidth >= 600 && screenWidth < 1200;
                    
                    if (isDesktop) {
                      return _buildFuturisticDesktopLayout(context, screenWidth);
                    } else if (isTablet) {
                      return _buildFuturisticTabletLayout(context, screenWidth);
                    } else {
                      return _buildFuturisticMobileLayout(context, screenWidth);
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
      // FloatingActionButton removido - botón ahora está en AppBar
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar(BuildContext context) {
    return AppBar(
      title: Obx(() => Text(
        controller.formTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      )),
      automaticallyImplyLeading: true,
      actions: [
        // Botón crear/guardar para todas las pantallas
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _buildAppBarCreateButton(),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ElegantLightTheme.primaryGradient.colors.first,
              ElegantLightTheme.primaryGradient.colors.last,
              ElegantLightTheme.primaryBlue,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.5),
    );
  }

  Widget _buildFuturisticLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                controller.isEditMode ? Icons.edit : Icons.add,
                color: ElegantLightTheme.textPrimary,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              controller.isEditMode ? 'Cargando categoría...' : 'Preparando formulario...',
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Configurando la experiencia futurista',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticMobileLayout(BuildContext context, double screenWidth) {
    final padding = 20.0;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header con progreso
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: _buildProgressHeader(screenWidth),
          ),
        ),

        // Formulario principal
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  _buildFuturisticCard(
                    title: 'Información Básica',
                    icon: Icons.info,
                    gradient: ElegantLightTheme.primaryGradient,
                    child: _buildBasicFields(context, screenWidth),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFuturisticCard(
                    title: 'Configuración',
                    icon: Icons.settings,
                    gradient: ElegantLightTheme.infoGradient,
                    child: _buildConfigurationFields(context),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFuturisticCard(
                    title: 'SEO Avanzado',
                    icon: Icons.search,
                    gradient: ElegantLightTheme.warningGradient,
                    child: _buildSeoFields(context),
                  ),
                  const SizedBox(height: 20),
                  
                  // Acciones en móvil
                  _buildFuturisticActions(screenWidth),
                  const SizedBox(height: 20), // Espacio final
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticTabletLayout(BuildContext context, double screenWidth) {
    final padding = 24.0;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: EdgeInsets.all(padding),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                // Header con progreso
                _buildProgressHeader(screenWidth),
                const SizedBox(height: 24),
                
                // Dos columnas para tablet
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda
                    Expanded(
                      child: Column(
                        children: [
                          _buildFuturisticCard(
                            title: 'Información Básica',
                            icon: Icons.info,
                            gradient: ElegantLightTheme.primaryGradient,
                            child: _buildBasicFields(context, screenWidth),
                          ),
                          const SizedBox(height: 20),
                          
                          _buildFuturisticCard(
                            title: 'SEO Avanzado',
                            icon: Icons.search,
                            gradient: ElegantLightTheme.warningGradient,
                            child: _buildSeoFields(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Columna derecha
                    Expanded(
                      child: Column(
                        children: [
                          _buildFuturisticCard(
                            title: 'Configuración',
                            icon: Icons.settings,
                            gradient: ElegantLightTheme.infoGradient,
                            child: _buildConfigurationFields(context),
                          ),
                          const SizedBox(height: 20),
                          
                          // Acciones
                          _buildFuturisticActions(screenWidth),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticDesktopLayout(BuildContext context, double screenWidth) {
    final padding = 32.0;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: controller.formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulario principal - columna izquierda
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    // Header con progreso
                    _buildProgressHeader(screenWidth),
                    const SizedBox(height: 32),
                    
                    _buildFuturisticCard(
                      title: 'Información Básica',
                      icon: Icons.info,
                      gradient: ElegantLightTheme.primaryGradient,
                      child: _buildBasicFields(context, screenWidth),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildFuturisticCard(
                      title: 'SEO Avanzado',
                      icon: Icons.search,
                      gradient: ElegantLightTheme.warningGradient,
                      child: _buildSeoFields(context),
                    ),
                  ],
                ),
              ),
            ),

            // Panel lateral derecho
            Container(
              width: 380,
              padding: EdgeInsets.fromLTRB(0, padding, padding, padding),
              child: Column(
                children: [
                  const SizedBox(height: 80), // Espacio para header
                  
                  _buildFuturisticCard(
                    title: 'Configuración',
                    icon: Icons.settings,
                    gradient: ElegantLightTheme.infoGradient,
                    child: _buildConfigurationFields(context),
                  ),
                  const SizedBox(height: 24),
                  
                  // Panel de acciones
                  _buildFuturisticActions(screenWidth),
                  const SizedBox(height: 24),
                  
                  // Panel de ayuda
                  _buildHelpPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBasicFields(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        _buildFuturisticTextField(
          controller: controller.nameController,
          label: 'Nombre de la Categoría *',
          hint: 'Ej: Electrónicos, Ropa, etc.',
          icon: Icons.category,
          validator: controller.validateName,
        ),

        const SizedBox(height: 20),

        // Slug con botón
        Row(
          children: [
            Expanded(
              child: _buildFuturisticTextField(
                controller: controller.slugController,
                label: 'Slug (URL) *',
                hint: 'electronica, ropa-deportiva',
                icon: Icons.link,
                validator: controller.validateSlug,
                onChanged: (_) => controller.markSlugAsManuallyEdited(),
              ),
            ),
            const SizedBox(width: 12),
            _buildFuturisticIconButton(
              icon: Icons.auto_fix_high,
              onPressed: controller.generateSlug,
              gradient: ElegantLightTheme.infoGradient,
              tooltip: 'Generar automáticamente',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Descripción
        _buildFuturisticTextField(
          controller: controller.descriptionController,
          label: 'Descripción',
          hint: 'Describe brevemente esta categoría...',
          icon: Icons.description,
          maxLines: 3,
          validator: controller.validateDescription,
        ),

        const SizedBox(height: 20),

        // Imagen URL
        _buildFuturisticTextField(
          controller: controller.imageController,
          label: 'URL de Imagen',
          hint: 'https://ejemplo.com/imagen.jpg',
          icon: Icons.image,
          validator: controller.validateImageUrl,
        ),
      ],
    );
  }


  Widget _buildConfigurationFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado
        Text(
          'Estado',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: RadioListTile<CategoryStatus>(
                  title: const Text('Activa'),
                  value: CategoryStatus.active,
                  groupValue: controller.selectedStatus,
                  onChanged: (value) => controller.changeStatus(value!),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<CategoryStatus>(
                  title: const Text('Inactiva'),
                  value: CategoryStatus.inactive,
                  groupValue: controller.selectedStatus,
                  onChanged: (value) => controller.changeStatus(value!),
                  dense: true,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.verticalSpacing),

        // Categoría padre
        Text(
          'Categoría Padre',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          print(
            '🎭 Building parent dropdown. Loading: ${controller.isLoadingParents}, Categories: ${controller.parentCategories.length}',
          );

          if (controller.isLoadingParents) {
            return const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // Si no hay categorías padre disponibles
          if (controller.parentCategories.isEmpty) {
            return Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_tree, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'No hay categorías padre disponibles',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ✅ CORRECCIÓN CRÍTICA: Manejo seguro del dropdown
          final selectedValue = controller.selectedParentId; // String? o null
          print('🔍 Selected value: $selectedValue');

          return DropdownButtonFormField<String?>(
            key: ValueKey(
              'parent_dropdown_${selectedValue ?? "null"}',
            ), // ✅ Key único
            value: selectedValue, // ✅ Puede ser null o String
            decoration: const InputDecoration(
              hintText: 'Seleccionar categoría padre (opcional)',
              prefixIcon: Icon(Icons.account_tree),
              border: OutlineInputBorder(),
            ),
            isExpanded: true, // Evitar overflow
            items: [
              // ✅ Opción null explícita
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Sin categoría padre'),
              ),
              // ✅ Opciones de categorías (filtrando la actual si existe)
              ...controller.parentCategories
                  .where(
                    (category) => category.id != controller.currentCategory?.id,
                  ) // Filtrar categoría actual
                  .map(
                    (category) => DropdownMenuItem<String?>(
                      value: category.id, // String
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis, // Prevenir overflow
                      ),
                    ),
                  ),
            ],
            onChanged: (String? value) {
              print('🔄 Dropdown changed to: $value');

              // ✅ Búsqueda segura
              CategoryTree? parent;
              if (value != null) {
                try {
                  parent = controller.parentCategories.firstWhere(
                    (cat) => cat.id == value,
                  );
                  print('✅ Parent found: ${parent.name}');
                } catch (e) {
                  print('⚠️ Parent not found for ID: $value');
                  parent = null;
                }
              } else {
                print('🚫 No parent selected (null)');
              }

              controller.changeParent(parent);
            },
            validator: (value) {
              // Validación opcional
              return null;
            },
          );
        }),

        SizedBox(height: context.verticalSpacing),

        // Orden
        CustomTextField(
          controller: TextEditingController(
            text: controller.sortOrder.toString(),
          ),
          label: 'Orden de Clasificación',
          hint: '0',
          prefixIcon: Icons.sort,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final order = int.tryParse(value) ?? 0;
            controller.changeSortOrder(order);
          },
        ),
      ],
    );
  }


  Widget _buildSeoFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!Responsive.isDesktop(context)) ...[
          Text(
            'SEO (Opcional)',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
        ],

        CustomTextField(
          controller: controller.metaTitleController,
          label: 'Meta Título',
          hint: 'Título para SEO (máx. 60 caracteres)',
          prefixIcon: Icons.title,
        ),

        SizedBox(height: context.verticalSpacing),

        CustomTextField(
          controller: controller.metaDescriptionController,
          label: 'Meta Descripción',
          hint: 'Descripción para SEO (máx. 160 caracteres)',
          prefixIcon: Icons.description,
          maxLines: 2,
        ),

        SizedBox(height: context.verticalSpacing),

        CustomTextField(
          controller: controller.metaKeywordsController,
          label: 'Palabras Clave',
          hint: 'palabra1, palabra2, palabra3',
          prefixIcon: Icons.tag,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              type: ButtonType.outline,
              onPressed: controller.cancel,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: controller.submitButtonText,
              icon: Icons.save,
              onPressed: controller.isLoading ? null : controller.saveCategory,
              isLoading: controller.isLoading,
            ),
          ),
        ],
      ),
    );
  }


  // ==================== FUTURISTIC METHODS ====================

  Widget _buildProgressHeader(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  controller.isEditMode ? Icons.edit : Icons.add_circle,
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
                      controller.isEditMode ? 'Editando Categoría' : 'Nueva Categoría',
                      style: const TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.isEditMode 
                        ? 'Modifica los campos y guarda los cambios'
                        : 'Completa la información para crear una categoría',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: controller.isEditMode 
                    ? ElegantLightTheme.warningGradient
                    : ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isEditMode ? Icons.edit : Icons.fiber_new,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.isEditMode ? 'Edición' : 'Nuevo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildFuturisticCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withValues(alpha: 0.1),
                  gradient.colors.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: gradient.colors.first,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required LinearGradient gradient,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticButton({
    required String text,
    required IconData icon,
    required LinearGradient gradient,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticActions(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Acciones',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Obx(() => Column(
            children: [
              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: _buildFuturisticButton(
                  text: controller.submitButtonText,
                  icon: Icons.save,
                  gradient: ElegantLightTheme.successGradient,
                  onPressed: controller.isLoading ? null : controller.saveCategory,
                  isLoading: controller.isLoading,
                ),
              ),
              const SizedBox(height: 12),
              
              // Botón cancelar
              SizedBox(
                width: double.infinity,
                child: _buildFuturisticButton(
                  text: 'Cancelar',
                  icon: Icons.close,
                  gradient: ElegantLightTheme.errorGradient,
                  onPressed: controller.cancel,
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildHelpPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
            ElegantLightTheme.infoGradient.colors.last.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ayuda',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildHelpTip(
            icon: Icons.category,
            text: 'El nombre debe ser único y descriptivo',
          ),
          const SizedBox(height: 12),
          
          _buildHelpTip(
            icon: Icons.link,
            text: 'El slug se usa en las URLs del sitio web',
          ),
          const SizedBox(height: 12),
          
          _buildHelpTip(
            icon: Icons.account_tree,
            text: 'Las categorías padre permiten crear jerarquías',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTip({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: ElegantLightTheme.infoGradient.colors.first,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarCreateButton() {
    return Obx(() => Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: controller.isLoading ? null : controller.saveCategory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  controller.submitButtonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

// ==================== FUTURISTIC PARTICLES PAINTER ====================

class FuturisticParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ElegantLightTheme.textSecondary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Dibujar partículas flotantes en patrón diagonal
    for (int i = 0; i < 30; i++) {
      final x = (i * 80.0 + 40) % size.width;
      final y = (i * 60.0 + 30) % size.height;
      final radius = (i % 3) + 1.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Líneas conectoras sutiles
    final linePaint = Paint()
      ..color = ElegantLightTheme.primaryBlue.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final startX = (i * 120.0) % size.width;
      final startY = (i * 80.0) % size.height;
      final endX = ((i + 1) * 120.0) % size.width;
      final endY = ((i + 1) * 80.0) % size.height;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
