// lib/features/inventory/presentation/widgets/inventory_quick_actions.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../screens/inventory_dashboard_screen.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';
import '../../../products/domain/entities/product.dart';

class InventoryQuickActions extends StatelessWidget {
  const InventoryQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      {
        'title': 'Nuevo Movimiento',
        'subtitle': 'Registrar entrada/salida',
        'icon': Icons.add_circle,
        'color': Colors.green,
        'onTap': () => Get.toNamed('/inventory/movements/create'),
      },
      {
        'title': 'Ajuste de Stock',
        'subtitle': 'Corregir inventario',
        'icon': Icons.tune,
        'color': Colors.orange,
        'onTap': () => Get.toNamed('/inventory/adjustments/create'),
      },
      {
        'title': 'Ajustes Masivos',
        'subtitle': 'Múltiples productos',
        'icon': Icons.playlist_add_check,
        'color': Colors.deepOrange,
        'onTap': () => Get.toNamed('/inventory/bulk-adjustments'),
      },
      {
        'title': 'Ver Balances',
        'subtitle': 'Stock actual',
        'icon': Icons.account_balance_wallet,
        'color': Colors.blue,
        'onTap': () => Get.toNamed('/inventory/balances'),
      },
      {
        'title': 'Buscar Producto',
        'subtitle': 'Kardex y lotes',
        'icon': Icons.search,
        'color': ElegantLightTheme.primaryBlue,
        'onTap': () => _showProductSearchDialog(),
      },
    ];

    // For mobile, show in a more compact grid layout
    if (MediaQuery.of(context).size.width < 600) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.3,
        ),
        itemCount: quickActions.length,
        itemBuilder: (context, index) {
          final action = quickActions[index];
          return _buildActionCard(
            context: context,
            title: action['title'] as String,
            subtitle: action['subtitle'] as String,
            icon: action['icon'] as IconData,
            color: action['color'] as Color,
            onTap: action['onTap'] as VoidCallback,
          );
        },
      );
    }

    // For tablet/desktop, show in column layout with fixed height
    return Container(
      height: 400, // Altura fija para todas las pantallas tablet/desktop
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: quickActions.map((action) => Expanded(
            child: _buildActionTile(
              context: context,
              title: action['title'] as String,
              subtitle: action['subtitle'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: UnifiedTypography.getListItemTitleSize(MediaQuery.of(context).size.width),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: UnifiedTypography.getListItemSubtitleSize(MediaQuery.of(context).size.width),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: UnifiedTypography.getListItemTitleSize(MediaQuery.of(context).size.width),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: UnifiedTypography.getListItemSubtitleSize(MediaQuery.of(context).size.width),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showProductSearchDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(Get.context!).size.width > 600 ? 520 : 
                MediaQuery.of(Get.context!).size.width * 0.95,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ElegantLightTheme.elevatedShadow,
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: const _ProductSearchWidget(),
        ),
      ),
      barrierDismissible: true,
    );
  }

}

class _ProductSearchWidget extends StatefulWidget {
  const _ProductSearchWidget();

  @override
  State<_ProductSearchWidget> createState() => _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends State<_ProductSearchWidget> {
  final searchController = TextEditingController();
  final RxList<Product> searchResults = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final padding = isDesktop ? 24.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header elegante
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.search, 
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
                        'Buscar Producto',
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: isDesktop ? 20 : 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Encuentra productos para ver kardex y lotes',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isDesktop ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cerrar',
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  // Campo de búsqueda mejorado
                  Container(
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nombre, SKU o código del producto...',
                        hintStyle: TextStyle(
                          color: ElegantLightTheme.textSecondary.withOpacity(0.6),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.infoGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2, 
                            color: Colors.white, 
                            size: 18,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: isDesktop ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Resultados
                  Expanded(
                    child: Obx(() => _buildSearchResults()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchQuery.value.isEmpty) {
      return _buildEmptyState();
    }
    
    if (isLoading.value) {
      return _buildLoadingState();
    }
    
    if (searchResults.isEmpty) {
      return _buildNoResultsState();
    }
    
    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.search,
              size: 56,
              color: ElegantLightTheme.primaryBlue.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Escribe para buscar productos',
            style: Get.textTheme.titleMedium?.copyWith(
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Podrás ver kardex, lotes y movimientos',
            style: Get.textTheme.bodySmall?.copyWith(
              color: ElegantLightTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ElegantLightTheme.primaryBlue,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Buscando productos...',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ElegantLightTheme.warningGradient.colors.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ElegantLightTheme.warningGradient.colors.first.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.search_off,
              size: 56,
              color: ElegantLightTheme.warningGradient.colors.first.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No se encontraron productos',
            style: Get.textTheme.titleMedium?.copyWith(
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda',
            style: Get.textTheme.bodySmall?.copyWith(
              color: ElegantLightTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    // Responsive padding and spacing
    final cardPadding = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
    final iconSize = isMobile ? 48.0 : isTablet ? 52.0 : 56.0;
    final borderRadius = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
            Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: isMobile ? 6 : 8,
                        offset: Offset(0, isMobile ? 3 : 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: isMobile ? 24 : isTablet ? 26 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        ),
                        maxLines: isMobile ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      if (product.stock != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 12, 
                            vertical: isMobile ? 5 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.successGradient.colors.first.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                            border: Border.all(
                              color: ElegantLightTheme.successGradient.colors.first.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: isMobile ? 12 : 14,
                                color: ElegantLightTheme.successGradient.colors.first,
                              ),
                              SizedBox(width: isMobile ? 4 : 6),
                              Text(
                                'Stock: ${product.stock}',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: ElegantLightTheme.successGradient.colors.first,
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 16 : 20),
            
            // Action buttons - layout adaptable
            isMobile ? _buildMobileActionButtons(product) : _buildDesktopActionButtons(product),
          ],
        ),
      ),
    );
  }

  // Botones para móvil - diseño vertical más compacto
  Widget _buildMobileActionButtons(Product product) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.analytics,
                label: 'Kardex',
                gradient: ElegantLightTheme.primaryGradient,
                isMobile: true,
                onTap: () {
                  Get.back();
                  Get.toNamed(
                    '/inventory/product/${product.id}/kardex',
                    arguments: {'productId': product.id},
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.inventory,
                label: 'Lotes',
                gradient: ElegantLightTheme.warningGradient,
                isMobile: true,
                onTap: () {
                  Get.back();
                  Get.toNamed(
                    '/inventory/product/${product.id}/batches',
                    arguments: {'productId': product.id},
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.swap_horiz,
          label: 'Ver Movimientos',
          gradient: ElegantLightTheme.successGradient,
          isMobile: true,
          fullWidth: true,
          onTap: () {
            Get.back();
            Get.toNamed(
              '/inventory/movements',
              arguments: {'productId': product.id},
            );
          },
        ),
      ],
    );
  }

  // Botones para tablet/desktop - diseño horizontal
  Widget _buildDesktopActionButtons(Product product) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.analytics,
            label: 'Kardex',
            gradient: ElegantLightTheme.primaryGradient,
            isMobile: false,
            onTap: () {
              Get.back();
              Get.toNamed(
                '/inventory/product/${product.id}/kardex',
                arguments: {'productId': product.id},
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.inventory,
            label: 'Lotes',
            gradient: ElegantLightTheme.warningGradient,
            isMobile: false,
            onTap: () {
              Get.back();
              Get.toNamed(
                '/inventory/product/${product.id}/batches',
                arguments: {'productId': product.id},
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.swap_horiz,
            label: 'Movimientos',
            gradient: ElegantLightTheme.successGradient,
            isMobile: false,
            onTap: () {
              Get.back();
              Get.toNamed(
                '/inventory/movements',
                arguments: {'productId': product.id},
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required bool isMobile,
    bool fullWidth = false,
  }) {
    final buttonRadius = isMobile ? 10.0 : 12.0;
    final iconSize = isMobile ? 18.0 : 22.0;
    final fontSize = isMobile ? 10.0 : 11.0;
    final verticalPadding = isMobile ? 10.0 : 12.0;
    final horizontalPadding = isMobile ? 6.0 : 8.0;
    
    Widget buttonContent = Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(buttonRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(isMobile ? 0.25 : 0.3),
            blurRadius: isMobile ? 4 : 6,
            offset: Offset(0, isMobile ? 2 : 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(buttonRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding, 
              horizontal: horizontalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                SizedBox(height: isMobile ? 4 : 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isMobile ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    return fullWidth ? buttonContent : buttonContent;
  }

  void _onSearchChanged(String value) {
    searchQuery.value = value;
    
    if (value.isEmpty) {
      searchResults.clear();
      return;
    }
    
    if (value.length < 2) {
      return;
    }
    
    _searchProducts(value);
  }

  void _searchProducts(String query) async {
    isLoading.value = true;
    
    try {
      // Simular delay de búsqueda
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Realizar búsqueda real de productos
      final results = await _searchProductsReal(query);
      
      searchResults.value = results;
    } catch (e) {
      print('Error searching products: $e');
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> _searchProductsReal(String query) async {
    try {
      // Usar el SearchProductsUseCase real
      final searchUseCase = Get.find<SearchProductsUseCase>();
      
      // Crear parámetros de búsqueda
      final params = SearchProductsParams(
        searchTerm: query,
        limit: 10,
      );
      
      // Realizar búsqueda real
      final result = await searchUseCase(params);
      
      return result.fold(
        (failure) {
          print('Error searching products: ${failure.message}');
          return <Product>[];
        },
        (products) => products,
      );
    } catch (e) {
      print('Error finding SearchProductsUseCase: $e');
      return <Product>[];
    }
  }
}