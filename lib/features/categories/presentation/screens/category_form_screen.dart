// lib/features/categories/presentation/screens/category_form_screen.dart
import 'package:baudex_desktop/features/categories/domain/entities/category_tree.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/category_form_controller.dart';
import '../../domain/entities/category.dart';

class CategoryFormScreen extends GetView<CategoryFormController> {
  const CategoryFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        // Mostrar loading específico cuando carga categoría para editar
        if (controller.isLoadingCategory) {
          return const LoadingWidget(message: 'Cargando categoría...');
        }

        // Mostrar loading general en modo edición si no hay categoría cargada
        if (controller.isLoading &&
            controller.isEditMode &&
            !controller.hasCategory) {
          return const LoadingWidget(message: 'Cargando datos...');
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(() => Text(controller.formTitle)),
      elevation: 0,
      actions: [
        // Guardar desde AppBar en desktop
        if (Responsive.isDesktop(context))
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Obx(
              () => CustomButton(
                text: controller.submitButtonText,
                icon: Icons.save,
                onPressed:
                    controller.isLoading ? null : controller.saveCategory,
                isLoading: controller.isLoading,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: _buildForm(context),
          ),
        ),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 600,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),
            CustomCard(child: _buildForm(context)),
            SizedBox(height: context.verticalSpacing),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulario principal
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información Básica',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildBasicFields(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración Avanzada',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildAdvancedFields(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel lateral
          Container(
            width: 350,
            padding: const EdgeInsets.fromLTRB(0, 32, 32, 32),
            child: Column(
              children: [
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildConfigurationFields(context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSeoFields(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!Responsive.isDesktop(context)) ...[
            _buildBasicFields(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildConfigurationFields(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildAdvancedFields(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildSeoFields(context),
          ] else
            _buildBasicFields(context),
        ],
      ),
    );
  }

  Widget _buildBasicFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        CustomTextField(
          controller: controller.nameController,
          label: 'Nombre de la Categoría *',
          hint: 'Ej: Electrónicos, Ropa, etc.',
          prefixIcon: Icons.category,
          validator: controller.validateName,
        ),

        SizedBox(height: context.verticalSpacing),

        // Slug
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller.slugController,
                label: 'Slug (URL) *',
                hint: 'electronica, ropa-deportiva',
                prefixIcon: Icons.link,
                validator: controller.validateSlug,
                onChanged: (_) => controller.markSlugAsManuallyEdited(),
              ),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: 'Generar',
              type: ButtonType.outline,
              onPressed: controller.generateSlug,
            ),
          ],
        ),

        SizedBox(height: context.verticalSpacing),

        // Descripción
        CustomTextField(
          controller: controller.descriptionController,
          label: 'Descripción',
          hint: 'Describe brevemente esta categoría...',
          prefixIcon: Icons.description,
          maxLines: 3,
          validator: controller.validateDescription,
        ),

        SizedBox(height: context.verticalSpacing),

        // Imagen URL
        CustomTextField(
          controller: controller.imageController,
          label: 'URL de Imagen',
          hint: 'https://ejemplo.com/imagen.jpg',
          prefixIcon: Icons.image,
          validator: controller.validateImageUrl,
        ),
      ],
    );
  }

  // Widget _buildConfigurationFields(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Estado
  //       Text(
  //         'Estado',
  //         style: TextStyle(
  //           fontSize: Responsive.getFontSize(context),
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Obx(
  //         () => Row(
  //           children: [
  //             Expanded(
  //               child: RadioListTile<CategoryStatus>(
  //                 title: const Text('Activa'),
  //                 value: CategoryStatus.active,
  //                 groupValue: controller.selectedStatus,
  //                 onChanged: (value) => controller.changeStatus(value!),
  //                 dense: true,
  //               ),
  //             ),
  //             Expanded(
  //               child: RadioListTile<CategoryStatus>(
  //                 title: const Text('Inactiva'),
  //                 value: CategoryStatus.inactive,
  //                 groupValue: controller.selectedStatus,
  //                 onChanged: (value) => controller.changeStatus(value!),
  //                 dense: true,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Categoría padre
  //       Text(
  //         'Categoría Padre',
  //         style: TextStyle(
  //           fontSize: Responsive.getFontSize(context),
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Obx(() {
  //         if (controller.isLoadingParents) {
  //           return const SizedBox(
  //             height: 56,
  //             child: Center(child: CircularProgressIndicator()),
  //           );
  //         }

  //         // Si no hay categorías padre disponibles
  //         if (controller.parentCategories.isEmpty) {
  //           return Container(
  //             height: 56,
  //             padding: const EdgeInsets.symmetric(horizontal: 12),
  //             decoration: BoxDecoration(
  //               border: Border.all(color: Colors.grey.shade300),
  //               borderRadius: BorderRadius.circular(4),
  //             ),
  //             child: const Row(
  //               children: [
  //                 Icon(Icons.account_tree, color: Colors.grey),
  //                 SizedBox(width: 8),
  //                 Text(
  //                   'No hay categorías padre disponibles',
  //                   style: TextStyle(color: Colors.grey),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }

  //         return DropdownButtonFormField<String?>(
  //           value: controller.selectedParent?.id,
  //           decoration: const InputDecoration(
  //             hintText: 'Seleccionar categoría padre (opcional)',
  //             prefixIcon: Icon(Icons.account_tree),
  //             border: OutlineInputBorder(),
  //           ),
  //           isExpanded: true, // Evitar overflow
  //           items: [
  //             const DropdownMenuItem<String?>(
  //               value: null,
  //               child: Text('Sin categoría padre'),
  //             ),
  //             ...controller.parentCategories
  //                 .where(
  //                   (category) => category.id != controller.currentCategory?.id,
  //                 ) // Filtrar categoría actual
  //                 .map(
  //                   (category) => DropdownMenuItem<String?>(
  //                     value: category.id,
  //                     child: Text(
  //                       category.name,
  //                       overflow: TextOverflow.ellipsis, // Prevenir overflow
  //                     ),
  //                   ),
  //                 ),
  //           ],
  //           onChanged: (String? value) {
  //             final parent =
  //                 value != null
  //                     ? controller.parentCategories.firstWhereOrNull(
  //                       (cat) => cat.id == value,
  //                     )
  //                     : null;
  //             controller.changeParent(parent);
  //           },
  //         );
  //       }),

  //       SizedBox(height: context.verticalSpacing),

  //       // Orden
  //       CustomTextField(
  //         controller: TextEditingController(
  //           text: controller.sortOrder.toString(),
  //         ),
  //         label: 'Orden de Clasificación',
  //         hint: '0',
  //         prefixIcon: Icons.sort,
  //         keyboardType: TextInputType.number,
  //         onChanged: (value) {
  //           final order = int.tryParse(value) ?? 0;
  //           controller.changeSortOrder(order);
  //         },
  //       ),
  //     ],
  //   );
  // }

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

  Widget _buildAdvancedFields(BuildContext context) {
    if (Responsive.isMobile(context) || Responsive.isTablet(context)) {
      return _buildSeoFields(context);
    }
    return const SizedBox.shrink();
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

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.left),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(child: _buildActions(context)),
    );
  }
}
