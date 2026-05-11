// lib/features/settings/presentation/screens/organization_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../../../../core/network/tenant_interceptor.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/models/active_session_model.dart';
import '../../../subscriptions/domain/entities/plan_limits.dart';
import '../../../subscriptions/domain/entities/subscription_enums.dart';
import '../../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../controllers/organization_controller.dart';
import '../widgets/edit_organization_dialog.dart';
import '../widgets/main_warehouse_selector.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  State<OrganizationSettingsScreen> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<OrganizationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _shimmerController;

  // Device sessions state
  List<ActiveSessionModel> _sessions = [];
  bool _sessionsLoading = false;
  String? _sessionsError;
  bool _sessionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: ElegantLightTheme.elasticCurve),
    );
    _animationController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    Future.microtask(() {
      _loadDeviceSessions();
      // Si la organización no está cargada, forzar recarga
      final orgController = Get.find<OrganizationController>();
      if (orgController.currentOrganization == null) {
        orgController.loadCurrentOrganization();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: MainLayout(
              title: _getResponsiveTitle(context),
              showBackButton: false,
              showDrawer: true,
              actions: _buildAppBarActions(context),
              body: Obx(
                () => controller.isLoading
                    ? _buildSkeletonContent(context)
                    : _buildFuturisticContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getResponsiveTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return 'Configuración';
    } else if (screenWidth < 800) {
      return 'Config. Organización';
    } else {
      return 'Configuración de Organización';
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => Get.find<OrganizationController>().forceRefreshFromServer(),
        tooltip: 'Actualizar',
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildSkeletonContent(BuildContext context) {
    return Container(
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
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton: Organization info card
            _buildSkeletonCard(
              headerIcon: Icons.apartment,
              headerWidth: 220,
              children: [
                // Subscription card skeleton
                _buildShimmerBox(height: 180, radius: 20),
                const SizedBox(height: 24),
                // Devices skeleton
                _buildShimmerBox(height: 120, radius: 16),
                const SizedBox(height: 24),
                // Details skeleton
                _buildSkeletonDetailRows(),
              ],
            ),
            const SizedBox(height: 32),
            // Skeleton: Warehouse selector
            _buildSkeletonCard(
              headerIcon: Icons.warehouse,
              headerWidth: 180,
              children: [
                _buildShimmerBox(height: 52, radius: 12),
              ],
            ),
            const SizedBox(height: 32),
            // Skeleton: Multi-currency
            _buildSkeletonCard(
              headerIcon: Icons.currency_exchange,
              headerWidth: 140,
              children: [
                _buildShimmerBox(height: 52, radius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({
    required IconData headerIcon,
    required double headerWidth,
    required List<Widget> children,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final pulse = ((_shimmerController.value * 2.0 - 1.0).abs() * 0.4) + 0.3;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300.withValues(alpha: pulse),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(headerIcon, color: Colors.grey.shade400, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: headerWidth,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300.withValues(alpha: pulse),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonDetailRows() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final pulse = ((_shimmerController.value * 2.0 - 1.0).abs() * 0.4) + 0.3;
        return Column(
          children: List.generate(5, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300.withValues(alpha: pulse),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200.withValues(alpha: pulse),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300.withValues(alpha: pulse),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
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
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: 24),
          const MainWarehouseSelector(),
          const SizedBox(height: 24),
          _buildMultiCurrencyCard(),
          const SizedBox(height: 24),
          _buildCashRegisterModuleCard(),
          const SizedBox(height: 24),
          _buildQuickActionsCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: 32),
          const MainWarehouseSelector(),
          const SizedBox(height: 32),
          _buildMultiCurrencyCard(),
          const SizedBox(height: 32),
          _buildCashRegisterModuleCard(),
          const SizedBox(height: 32),
          _buildQuickActionsCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: 32),
          const MainWarehouseSelector(),
          const SizedBox(height: 32),
          _buildMultiCurrencyCard(),
          const SizedBox(height: 32),
          _buildCashRegisterModuleCard(),
          const SizedBox(height: 32),
          _buildQuickActionsCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }



  // ==================== MULTI-CURRENCY SECTION ====================

  /// Lista de monedas disponibles para agregar
  static const _availableCurrencies = [
    {'code': 'USD', 'name': 'Dólar Estadounidense', 'symbol': 'US\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'Libra Esterlina', 'symbol': '£'},
    {'code': 'MXN', 'name': 'Peso Mexicano', 'symbol': 'MX\$'},
    {'code': 'BRL', 'name': 'Real Brasileño', 'symbol': 'R\$'},
    {'code': 'ARS', 'name': 'Peso Argentino', 'symbol': 'AR\$'},
    {'code': 'PEN', 'name': 'Sol Peruano', 'symbol': 'S/'},
    {'code': 'CLP', 'name': 'Peso Chileno', 'symbol': 'CL\$'},
    {'code': 'BOB', 'name': 'Boliviano', 'symbol': 'Bs'},
    {'code': 'VES', 'name': 'Bolívar Digital', 'symbol': 'Bs.D'},
    {'code': 'DOP', 'name': 'Peso Dominicano', 'symbol': 'RD\$'},
    {'code': 'GTQ', 'name': 'Quetzal', 'symbol': 'Q'},
    {'code': 'HNL', 'name': 'Lempira', 'symbol': 'L'},
    {'code': 'NIO', 'name': 'Córdoba', 'symbol': 'C\$'},
    {'code': 'PAB', 'name': 'Balboa', 'symbol': 'B/.'},
    {'code': 'PYG', 'name': 'Guaraní', 'symbol': '₲'},
    {'code': 'UYU', 'name': 'Peso Uruguayo', 'symbol': '\$U'},
    {'code': 'CRC', 'name': 'Colón Costarricense', 'symbol': '₡'},
    {'code': 'COP', 'name': 'Peso Colombiano', 'symbol': '\$'},
  ];

  Widget _buildMultiCurrencyCard() {
    final controller = Get.find<OrganizationController>();

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.currency_exchange,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Multi-Moneda',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Permite aceptar pagos en monedas diferentes a ${controller.baseCurrency}',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Toggle switch
          Obx(() {
            final enabled = controller.isMultiCurrencyEnabled;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: enabled
                    ? ElegantLightTheme.successGradient.colors.first
                        .withValues(alpha: 0.1)
                    : ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? ElegantLightTheme.successGradient.colors.first
                          .withValues(alpha: 0.3)
                      : ElegantLightTheme.textSecondary
                          .withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    enabled ? Icons.check_circle : Icons.toggle_off_outlined,
                    color: enabled
                        ? ElegantLightTheme.successGradient.colors.first
                        : ElegantLightTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aceptar pagos en múltiples monedas',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (val) => controller.toggleMultiCurrency(val),
                    activeColor:
                        ElegantLightTheme.successGradient.colors.first,
                  ),
                ],
              ),
            );
          }),

          // Lista de monedas aceptadas (solo si está habilitado)
          Obx(() {
            if (!controller.isMultiCurrencyEnabled) {
              return const SizedBox.shrink();
            }

            final currencies = controller.acceptedCurrencies;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monedas aceptadas (${currencies.length})',
                      style: const TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddCurrencyDialog(controller),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                      style: TextButton.styleFrom(
                        foregroundColor: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (currencies.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.backgroundColor
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ElegantLightTheme.textSecondary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          color: ElegantLightTheme.textSecondary,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay monedas configuradas',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Agrega monedas para aceptar pagos en diferentes divisas',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...currencies.map((currency) => _buildCurrencyTile(
                        currency,
                        controller,
                      )),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Toggle del módulo de caja registradora — habilita/deshabilita
  /// para el tenant completo. Confirma con un dialog antes de apagar
  /// (para evitar accidentes), ya que apagarlo oculta banners, badge,
  /// item del drawer, guard de facturas y la opción "Caja del día" en
  /// gastos.
  Widget _buildCashRegisterModuleCard() {
    final controller = Get.find<OrganizationController>();

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Caja Registradora',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Si tu negocio maneja caja del día (efectivo físico con '
            'apertura/cierre diario), mantenlo activo. Si vendes solo '
            'por transferencia o no usas caja como concepto, apágalo y '
            'desaparece todo el módulo.',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final enabled = controller.isCashRegisterEnabled;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: enabled
                    ? ElegantLightTheme.successGradient.colors.first
                        .withValues(alpha: 0.1)
                    : ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? ElegantLightTheme.successGradient.colors.first
                          .withValues(alpha: 0.3)
                      : ElegantLightTheme.textSecondary
                          .withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    enabled ? Icons.check_circle : Icons.toggle_off_outlined,
                    color: enabled
                        ? ElegantLightTheme.successGradient.colors.first
                        : ElegantLightTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      enabled
                          ? 'Módulo de caja activo'
                          : 'Módulo de caja desactivado',
                      style: const TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (val) async {
                      if (!val) {
                        // Confirmar antes de apagar — un toggle accidental
                        // oculta TODO el módulo y al usuario podría
                        // parecerle que perdió funcionalidad.
                        final ok = await Get.dialog<bool>(
                          AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient:
                                    ElegantLightTheme.warningGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: const Text(
                              'Desactivar caja registradora',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            content: const Text(
                              'Esto ocultará el badge del AppBar, los '
                              'recordatorios del dashboard, el ítem '
                              '"Caja" del menú y dejará de exigir caja '
                              'abierta para facturar.\n\n'
                              'Los datos históricos de cajas anteriores '
                              'se conservan. Puedes reactivarlo desde '
                              'aquí cuando quieras.',
                              textAlign: TextAlign.center,
                              style: TextStyle(height: 1.4),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Get.back<bool>(result: false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Get.back<bool>(result: true),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      ElegantLightTheme.warningOrange,
                                ),
                                child: const Text('Desactivar'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                      }
                      await controller.toggleCashRegister(val);
                    },
                    activeColor:
                        ElegantLightTheme.successGradient.colors.first,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurrencyTile(
    Map<String, dynamic> currency,
    OrganizationController controller,
  ) {
    final code = currency['code'] as String? ?? '';
    final name = currency['name'] as String? ?? code;
    final symbol = currency['symbol'] as String? ?? code;
    final defaultRate = (currency['defaultRate'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code - $name',
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  defaultRate > 0
                      ? AppFormatters.formatExchangeInfo(
                          code, defaultRate, controller.baseCurrency)
                      : 'Sin tasa por defecto',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Editar tasa
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: ElegantLightTheme.primaryBlue,
            tooltip: 'Editar tasa',
            onPressed: () =>
                _showEditRateDialog(controller, code, name, defaultRate),
          ),
          // Eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: ElegantLightTheme.errorGradient.colors.first,
            tooltip: 'Eliminar moneda',
            onPressed: () => _confirmRemoveCurrency(controller, code, name),
          ),
        ],
      ),
    );
  }

  void _showAddCurrencyDialog(OrganizationController controller) {
    final baseCurrency = controller.baseCurrency;
    final existing =
        controller.acceptedCurrencies.map((c) => c['code']).toSet();

    // Filtrar monedas: excluir la moneda base y las ya agregadas
    final available = _availableCurrencies
        .where((c) =>
            c['code'] != baseCurrency && !existing.contains(c['code']))
        .toList();

    if (available.isEmpty) {
      Get.snackbar(
        'Sin monedas disponibles',
        'Ya has agregado todas las monedas disponibles',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.info, color: Colors.orange),
      );
      return;
    }

    final rateController = TextEditingController();
    String? selectedCode;
    String previewText = '';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = selectedCode != null
              ? available.firstWhere((c) => c['code'] == selectedCode)
              : null;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Agregar Moneda',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona la moneda:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    hint: const Text('Seleccionar moneda'),
                    value: selectedCode,
                    items: available
                        .map((c) => DropdownMenuItem<String>(
                              value: c['code'] as String,
                              child: Text(
                                  '${c['symbol']} ${c['code']} - ${c['name']}'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCode = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tasa de cambio (1 ${selectedCode ?? '...'} = ? $baseCurrency):',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresa la tasa tal como la encuentras en internet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'Ej: 4.000 o 8,27',
                      prefixText: '1 ${selectedCode ?? '...'} = ',
                      suffixText: baseCurrency,
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        final parsed = AppFormatters.parseRate(val);
                        if (parsed != null && selected != null) {
                          previewText = AppFormatters.formatExchangeInfo(
                            selected['code'] as String,
                            parsed,
                            baseCurrency,
                          );
                        } else {
                          previewText = '';
                        }
                      });
                    },
                  ),
                  if (selected != null && previewText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.infoGradient.colors.first
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              previewText,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selectedCode == null
                    ? null
                    : () async {
                        final rate =
                            AppFormatters.parseRate(rateController.text) ?? 0;
                        final sel = available.firstWhere(
                            (c) => c['code'] == selectedCode);
                        final success = await controller.addAcceptedCurrency({
                          'code': sel['code'],
                          'name': sel['name'],
                          'symbol': sel['symbol'],
                          'defaultRate': rate,
                        });
                        if (success) {
                          Get.back();
                          Get.snackbar(
                            'Moneda agregada',
                            '${sel['code']} ha sido agregada exitosamente',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.green.shade800,
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElegantLightTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRateDialog(
    OrganizationController controller,
    String code,
    String name,
    double currentRate,
  ) {
    final rateController = TextEditingController(
      text: currentRate > 0 ? AppFormatters.formatRate(currentRate) : '',
    );

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final parsed = AppFormatters.parseRate(rateController.text);
          final previewText = parsed != null && parsed > 0
              ? AppFormatters.formatExchangeInfo(
                  code, parsed, controller.baseCurrency)
              : '';

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Editar tasa $code',
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasa de cambio para $name (1 $code = ? ${controller.baseCurrency}):',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresa la tasa tal como la encuentras en internet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Ej: 4.000 o 8,27',
                    prefixText: '1 $code = ',
                    suffixText: controller.baseCurrency,
                  ),
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (previewText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.infoGradient.colors.first
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            previewText,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final rate =
                      AppFormatters.parseRate(rateController.text) ?? 0;
                  final success =
                      await controller.updateCurrencyRate(code, rate);
                  if (success) {
                    Get.back();
                    Get.snackbar(
                      'Tasa actualizada',
                      'La tasa de $code ha sido actualizada',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green.shade100,
                      colorText: Colors.green.shade800,
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green),
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: ElegantLightTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemoveCurrency(
    OrganizationController controller,
    String code,
    String name,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar moneda',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar $code ($name) de las monedas aceptadas?\n\nLos pagos existentes en esta moneda no se verán afectados.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await controller.removeAcceptedCurrency(code);
              if (success) {
                Get.back();
                Get.snackbar(
                  'Moneda eliminada',
                  '$code ha sido removida de las monedas aceptadas',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade800,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ElegantLightTheme.errorGradient.colors.first,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ==================== ORGANIZATION CARD ====================

  Widget _buildCurrentOrganizationCard() {
    final controller = Get.find<OrganizationController>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double iconPadding = isMobile ? 10 : isTablet ? 11 : 12;
        double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
        double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
        double spacing = isMobile ? 12 : isTablet ? 14 : 16;
        double verticalSpacing = isMobile ? 18 : isTablet ? 21 : 24;
        
        return FuturisticContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.apartment,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      isMobile 
                        ? 'Información\nde la Organización'
                        : 'Información de la Organización',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              Obx(() {
                final organization = controller.currentOrganization;
                if (organization == null) {
                  // Si está cargando, mostrar skeleton en vez de "Sin Organización"
                  if (controller.isLoading) {
                    return _buildSkeletonCard(
                      headerIcon: Icons.apartment,
                      headerWidth: 200,
                      children: [
                        _buildShimmerBox(height: 120, radius: 16),
                        const SizedBox(height: 16),
                        _buildShimmerBox(height: 80, radius: 12),
                      ],
                    );
                  }
                  return _buildNoOrganizationWidget();
                }
                return _buildOrganizationDetails(organization);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoOrganizationWidget() {
    final controller = Get.find<OrganizationController>();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin Organización',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu usuario no tiene una organización asignada. Esto puede causar problemas de acceso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FuturisticButton(
            text: 'Recargar',
            icon: Icons.refresh,
            onPressed: controller.forceRefreshFromServer,
            gradient: ElegantLightTheme.primaryGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationDetails(organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de suscripción
        _buildFuturisticSubscriptionCard(organization),
        const SizedBox(height: 24),

        // Dispositivos conectados
        _buildDeviceSessionsCard(),
        const SizedBox(height: 24),

        // Detalles de organización
        _buildFuturisticDetailsSection(organization),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FuturisticButton(
            text: 'Editar Organización',
            icon: Icons.edit,
            onPressed: () => _showEditOrganizationDialog(organization),
            gradient: ElegantLightTheme.primaryGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticDetailsSection(organization) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double containerPadding = isMobile ? 16 : isTablet ? 18 : 20;
        double iconPadding = isMobile ? 6 : isTablet ? 7 : 8;
        double iconSize = isMobile ? 14 : isTablet ? 15 : 16;
        double titleFontSize = isMobile ? 14 : isTablet ? 15 : 16;
        double spacing = isMobile ? 10 : isTablet ? 11 : 12;
        double verticalSpacing = isMobile ? 16 : isTablet ? 18 : 20;
        
        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      isMobile 
                        ? 'Detalles de\nla Organización'
                        : 'Detalles de la Organización',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              
              _buildFuturisticDetailRow('Nombre', organization.name, Icons.business),
              _buildFuturisticDetailRow('Slug', organization.slug, Icons.link),
              _buildFuturisticDetailRow('Moneda', organization.currency, Icons.currency_exchange),
              _buildFuturisticDetailRow('Idioma', organization.locale, Icons.language),
              _buildFuturisticDetailRow('Zona Horaria', organization.timezone, Icons.access_time),
              _buildFuturisticDetailRow(
                'Estado',
                organization.isActive ? 'Activa' : 'Inactiva',
                organization.isActive ? Icons.check_circle : Icons.cancel,
                statusColor: organization.isActive 
                  ? ElegantLightTheme.successGradient.colors.first
                  : ElegantLightTheme.errorGradient.colors.first,
              ),
              if (organization.domain != null)
                _buildFuturisticDetailRow('Dominio', organization.domain!, Icons.domain),
              if (organization.taxId.isNotEmpty)
                _buildFuturisticDetailRow('NIT', organization.taxId, Icons.badge),
              if (organization.address.isNotEmpty)
                _buildFuturisticDetailRow('Dirección', organization.address, Icons.location_on),
              if (organization.phone.isNotEmpty)
                _buildFuturisticDetailRow('Teléfono', organization.phone, Icons.phone),
              if (organization.email.isNotEmpty)
                _buildFuturisticDetailRow('Email', organization.email, Icons.email),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticDetailRow(
    String label, 
    String value, 
    IconData icon, {
    Color? statusColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double margin = isMobile ? 8 : isTablet ? 10 : 12;
        double padding = isMobile ? 10 : isTablet ? 11 : 12;
        double iconSize = isMobile ? 16 : isTablet ? 17 : 18;
        double labelFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double valueFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double spacing = isMobile ? 8 : isTablet ? 10 : 12;
        double labelWidth = isMobile ? 80 : isTablet ? 90 : 100;
        
        return Container(
          margin: EdgeInsets.only(bottom: margin),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: statusColor?.withValues(alpha: 0.2) ?? 
                     ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: statusColor ?? ElegantLightTheme.textSecondary,
                size: iconSize,
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: labelWidth,
                child: Text(
                  '$label:',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: statusColor ?? ElegantLightTheme.textPrimary,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSubscriptionCard(organization) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: _buildSubscriptionCardContent(organization),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCardContent(organization) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double containerPadding = isMobile ? 16 : isTablet ? 20 : 24;
        double iconPadding = isMobile ? 8 : isTablet ? 10 : 12;
        double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
        double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
        double subtitleFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double statusFontSize = isMobile ? 10 : isTablet ? 11 : 12;
        double spacing = isMobile ? 12 : isTablet ? 14 : 16;
        double verticalSpacing = isMobile ? 18 : isTablet ? 21 : 24;
        double statusPadding = isMobile ? 8 : isTablet ? 10 : 12;
        
        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getSubscriptionColor(organization.subscriptionPlan),
                _getSubscriptionColor(organization.subscriptionPlan).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getSubscriptionColor(organization.subscriptionPlan).withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubscriptionIcon(organization.subscriptionPlan),
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMobile 
                            ? 'Plan ${organization.subscriptionPlan.displayName}'
                            : 'Plan ${organization.subscriptionPlan.displayName}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 2 : 4),
                        Text(
                          isMobile ? 'Activa' : 'Suscripción activa',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: statusPadding, 
                      vertical: statusPadding / 2
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      organization.subscriptionStatus.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: statusFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              
              // Barra de progreso futurista
              _buildFuturisticSubscriptionProgress(organization),
              
              SizedBox(height: verticalSpacing),
              
              // Información de fechas
              Row(
                children: [
                  Expanded(
                    child: _buildFuturisticSubscriptionInfo(
                      isMobile ? 'Días' : 'Días restantes',
                      '${organization.remainingDays}',
                      Icons.access_time,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildFuturisticSubscriptionInfo(
                      organization.isTrialPlan 
                        ? (isMobile ? 'Fin trial' : 'Fecha fin trial')
                        : (isMobile ? 'Renovación' : 'Renovación'),
                      _formatDate(organization.isTrialPlan 
                        ? organization.trialEndDate 
                        : organization.subscriptionEndDate),
                      Icons.event,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSubscriptionProgress(organization) {
    final progress = organization.subscriptionProgress;
    final remainingDays = organization.remainingDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              organization.isTrialPlan ? 'Progreso del trial' : 'Progreso de suscripción',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween<double>(begin: 0.0, end: progress),
          builder: (context, animatedValue, child) {
            return Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    remainingDays <= 3 
                      ? Colors.red.shade300
                      : remainingDays <= 7
                        ? Colors.orange.shade300
                        : Colors.white,
                  ),
                  minHeight: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFuturisticSubscriptionInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor(subscriptionPlan) {
    switch (subscriptionPlan.toString()) {
      case 'SubscriptionPlan.trial':
        return Colors.orange;
      case 'SubscriptionPlan.basic':
        return Colors.blue;
      case 'SubscriptionPlan.premium':
        return Colors.purple;
      case 'SubscriptionPlan.enterprise':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubscriptionIcon(subscriptionPlan) {
    switch (subscriptionPlan.toString()) {
      case 'SubscriptionPlan.trial':
        return Icons.access_time;
      case 'SubscriptionPlan.basic':
        return Icons.business;
      case 'SubscriptionPlan.premium':
        return Icons.star;
      case 'SubscriptionPlan.enterprise':
        return Icons.corporate_fare;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditOrganizationDialog(organization) {
    Get.dialog(EditOrganizationDialog(organization: organization));
  }

  // ==================== DEVICE SESSIONS SECTION ====================

  Future<void> _loadDeviceSessions() async {
    if (_sessionsLoading) return;
    if (!mounted) return;

    // Verificar que el tenant esté disponible antes de hacer el API call
    if (TenantInterceptor.cachedSlug == null || TenantInterceptor.cachedSlug!.isEmpty) {
      // Forzar re-lectura del storage por si el cache no se inicializó aún
      TenantInterceptor.invalidateCache();
      try {
        final storage = Get.find<SecureStorageService>();
        final slug = await storage.getTenantSlug();
        if (slug != null && slug.isNotEmpty) {
          TenantInterceptor.updateCachedSlug(slug);
        } else {
          // Tenant no disponible — no intentar el API call
          if (!mounted) return;
          setState(() {
            _sessionsError = 'offline';
            _sessionsLoading = false;
          });
          return;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _sessionsError = 'offline';
          _sessionsLoading = false;
        });
        return;
      }
    }

    setState(() {
      _sessionsLoading = true;
      _sessionsError = null;
    });

    try {
      final AuthRemoteDataSource remoteDS;
      if (Get.isRegistered<AuthRemoteDataSource>()) {
        remoteDS = Get.find<AuthRemoteDataSource>();
      } else {
        remoteDS = AuthRemoteDataSourceImpl(dioClient: Get.find<DioClient>());
      }
      final sessions = await remoteDS.getActiveSessions();
      if (!mounted) return;

      // Deduplicar por ID
      final seen = <String>{};
      final uniqueSessions = sessions.where((s) => seen.add(s.id)).toList();

      setState(() {
        _sessions = uniqueSessions;
        _sessionsLoading = false;
        _sessionsLoaded = true;
      });
    } on ConnectionException {
      if (!mounted) return;
      setState(() {
        _sessionsError = 'offline';
        _sessionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _sessionsError = msg.contains('conexión') || msg.contains('Socket') || msg.contains('Organización')
            ? 'offline'
            : 'Error al cargar dispositivos';
        _sessionsLoading = false;
      });
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      final remoteDS = Get.find<AuthRemoteDataSource>();
      await remoteDS.revokeSession(sessionId);
      setState(() {
        _sessions.removeWhere((s) => s.id == sessionId);
      });
      Get.snackbar(
        'Sesión cerrada',
        'El dispositivo ha sido desconectado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cerrar la sesión',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _revokeAllOtherSessions() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Confirmar'),
          ],
        ),
        content: const Text(
          'Se cerrarán todas las sesiones excepto la actual. '
          'Los demás dispositivos deberán iniciar sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar todas'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final remoteDS = Get.find<AuthRemoteDataSource>();
      final count = await remoteDS.revokeAllOtherSessions();
      await _loadDeviceSessions();
      Get.snackbar(
        'Sesiones cerradas',
        '$count dispositivo(s) desconectado(s)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cerrar las sesiones',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  int get _maxDevices {
    if (Get.isRegistered<SubscriptionController>()) {
      return Get.find<SubscriptionController>().limits?.maxDevices ?? 2;
    }
    return 2;
  }

  Widget _buildDeviceSessionsCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1000;
        final containerPadding = isMobile ? 16.0 : isTablet ? 20.0 : 24.0;
        final iconPadding = isMobile ? 6.0 : isTablet ? 7.0 : 8.0;
        final iconSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
        final titleFontSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
        final spacing = isMobile ? 10.0 : isTablet ? 11.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.devices, color: Colors.white, size: iconSize),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      'Dispositivos Conectados',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_sessionsLoaded)
                    IconButton(
                      icon: _sessionsLoading
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: ElegantLightTheme.textSecondary,
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              size: iconSize,
                              color: ElegantLightTheme.textSecondary,
                            ),
                      onPressed: _sessionsLoading ? null : () => _loadDeviceSessions(),
                      tooltip: 'Actualizar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_sessionsLoading && !_sessionsLoaded)
                _buildSessionsSkeletonLoading()
              else if (_sessionsError == 'offline')
                _buildOfflineDevicesPlaceholder()
              else if (_sessionsError != null && _sessions.isEmpty)
                _buildSessionsErrorState()
              else
                _buildSessionsList(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineDevicesPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, color: ElegantLightTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sin conexión al servidor. Verifica tu red e intenta de nuevo.',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _loadDeviceSessions(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: ElegantLightTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _sessionsError ?? 'Error desconocido',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _loadDeviceSessions(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSkeletonLoading() {
    return Column(
      children: [
        // Counter skeleton
        _buildShimmerBox(height: 56, radius: 12),
        const SizedBox(height: 12),
        // Session tile skeletons
        _buildSessionSkeletonTile(),
        const SizedBox(height: 8),
        _buildSessionSkeletonTile(),
      ],
    );
  }

  Widget _buildSessionSkeletonTile() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final pulse = ((_shimmerController.value * 2.0 - 1.0).abs() * 0.4) + 0.3;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Icon placeholder
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300.withValues(alpha: pulse),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300.withValues(alpha: pulse),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 190,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withValues(alpha: pulse),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withValues(alpha: pulse),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200.withValues(alpha: pulse),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({required double height, double? width, double radius = 8}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final pulse = ((_shimmerController.value * 2.0 - 1.0).abs() * 0.4) + 0.3;
        return Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: pulse),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }

  String get _currentPlanName {
    if (Get.isRegistered<SubscriptionController>()) {
      return Get.find<SubscriptionController>().currentPlan.displayName;
    }
    return 'Plan de Prueba';
  }

  String get _upgradePlanName {
    if (Get.isRegistered<SubscriptionController>()) {
      final current = Get.find<SubscriptionController>().currentPlan;
      switch (current) {
        case SubscriptionPlan.trial:
        case SubscriptionPlan.basic:
          return 'Plan Premium';
        case SubscriptionPlan.premium:
          return 'Plan Empresarial';
        case SubscriptionPlan.enterprise:
          return '';
      }
    }
    return 'Plan Premium';
  }

  int get _upgradeMaxDevices {
    if (Get.isRegistered<SubscriptionController>()) {
      final current = Get.find<SubscriptionController>().currentPlan;
      switch (current) {
        case SubscriptionPlan.trial:
        case SubscriptionPlan.basic:
          return PlanLimits.premium.maxDevices;
        case SubscriptionPlan.premium:
          return PlanLimits.enterprise.maxDevices;
        case SubscriptionPlan.enterprise:
          return -1;
      }
    }
    return PlanLimits.premium.maxDevices;
  }

  Widget _buildSessionsList(bool isMobile) {
    final maxDevices = _maxDevices;
    final activeCount = _sessions.length;
    final isAtLimit = maxDevices > 0 && activeCount >= maxDevices;
    final isNearLimit = maxDevices > 0 && activeCount >= (maxDevices * 0.8);

    final Color barColor;
    if (isAtLimit) {
      barColor = const Color(0xFFE53935);
    } else if (isNearLimit) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = ElegantLightTheme.primaryGradient.colors.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Device count header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAtLimit
                  ? const Color(0xFFE53935).withValues(alpha: 0.2)
                  : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.devices,
                    color: barColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$activeCount de $maxDevices dispositivos',
                      style: const TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _currentPlanName,
                      style: TextStyle(
                        color: barColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxDevices > 0
                      ? (activeCount / maxDevices).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              ),
              if (isAtLimit) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Límite alcanzado. Cierra sesión en uno de tus dispositivos para poder conectar otro.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_upgradePlanName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Actualiza a $_upgradePlanName para $_upgradeMaxDevices dispositivos',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Session list
        if (_sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay sesiones activas',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          )
        else
          ..._sessions.map((session) => _buildSessionTile(session, isMobile)),

        // Revoke all button
        if (_sessions.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _revokeAllOtherSessions,
              icon: Icon(Icons.logout, size: 16, color: Colors.red.shade600),
              label: Text(
                'Cerrar todas las demás sesiones',
                style: TextStyle(color: Colors.red.shade600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSessionTile(ActiveSessionModel session, bool isMobile) {
    final statusColor = session.activityStatusColor;
    final isActive = session.isRecentlyActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? statusColor.withValues(alpha: 0.25)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Device icon with status indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryGradient.colors.first.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  session.deviceIcon,
                  color: ElegantLightTheme.primaryGradient.colors.first,
                  size: 22,
                ),
              ),
              // Status dot overlay
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceDisplayName,
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  session.deviceSubtitle,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.activityStatusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              size: 18,
              color: Colors.red.shade400,
            ),
            onPressed: () => _revokeSession(session.id),
            tooltip: 'Cerrar sesión',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildQuickActionButton(
            'Exportar Datos',
            'Funcionalidad en desarrollo',
            Icons.download,
            ElegantLightTheme.primaryGradient,
            _showDevelopmentDialog,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Generar Reporte',
            'Funcionalidad en desarrollo',
            Icons.analytics,
            ElegantLightTheme.infoGradient,
            _showDevelopmentDialog,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Configurar API',
            'Funcionalidad en desarrollo',
            Icons.key,
            ElegantLightTheme.warningGradient,
            _showDevelopmentDialog,
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Soporte Técnico',
            'Funcionalidad en desarrollo',
            Icons.support_agent,
            ElegantLightTheme.successGradient,
            _showDevelopmentDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showDevelopmentDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.construction,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'En Desarrollo',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Esta funcionalidad está actualmente en desarrollo y estará disponible en futuras versiones.',
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: ElegantLightTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
