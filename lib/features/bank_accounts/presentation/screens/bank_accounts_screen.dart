// lib/features/bank_accounts/presentation/screens/bank_accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../domain/entities/bank_account.dart';
import '../controllers/bank_accounts_controller.dart';
import '../widgets/bank_account_card.dart';
import '../widgets/bank_account_form_dialog.dart';

/// Pantalla principal de gestión de cuentas bancarias con tema elegante
class BankAccountsScreen extends GetView<BankAccountsController> {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Cuentas Bancarias',
        style: TextStyle(
          color: ElegantLightTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      backgroundColor: ElegantLightTheme.surfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.1),
      iconTheme: const IconThemeData(color: ElegantLightTheme.textPrimary),
      actions: [
        // Filtro por tipo
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: PopupMenuButton<BankAccountType?>(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
            tooltip: 'Filtrar por tipo',
            onSelected: controller.setFilterType,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: ElegantLightTheme.surfaceColor,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 20,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Todos los tipos',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ...BankAccountType.values.map(
                (type) => PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        size: 20,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.displayName,
                        style: const TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Mostrar inactivos
        Obx(() => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: controller.showInactive.value
                    ? ElegantLightTheme.primaryBlue.withOpacity(0.1)
                    : ElegantLightTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(
                  controller.showInactive.value
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: controller.showInactive.value
                      ? ElegantLightTheme.primaryBlue
                      : ElegantLightTheme.textSecondary,
                ),
                tooltip: controller.showInactive.value
                    ? 'Ocultar inactivas'
                    : 'Mostrar inactivas',
                onPressed: () =>
                    controller.setShowInactive(!controller.showInactive.value),
              ),
            )),
        const SizedBox(width: 8),

        // Refrescar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
            tooltip: 'Refrescar',
            onPressed: () => controller.loadBankAccounts(refresh: true),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.bankAccounts.isEmpty) {
        return const LoadingWidget(message: 'Cargando cuentas bancarias...');
      }

      if (controller.hasError.value && controller.bankAccounts.isEmpty) {
        return _buildErrorState(context);
      }

      if (!controller.hasAccounts) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadBankAccounts(refresh: true),
        color: ElegantLightTheme.primaryBlue,
        backgroundColor: ElegantLightTheme.surfaceColor,
        child: _buildAccountsList(context),
      );
    });
  }

  Widget _buildAccountsList(BuildContext context) {
    return Obx(() {
      final accounts = controller.filteredAccounts;

      if (accounts.isEmpty) {
        return _buildNoResultsState(context);
      }

      return ListView.builder(
        padding: ResponsiveHelper.getPadding(context),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveHelper.getVerticalSpacing(
                context,
                size: SpacingSize.small,
              ),
            ),
            child: BankAccountCard(
              account: account,
              onTap: () => _showAccountDetails(context, account),
              onEdit: () => _showEditDialog(context, account),
              onDelete: () => _confirmDelete(context, account),
              onSetDefault: account.isDefault
                  ? null
                  : () => _setAsDefault(context, account),
              onToggleActive: () => _toggleActive(context, account),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.responsiveValue(
            context,
            mobile: 320,
            tablet: 420,
            desktop: 500,
          ),
        ),
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container con gradiente
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 64,
                  tablet: 80,
                  desktop: 96,
                ),
                color: ElegantLightTheme.primaryBlue.withOpacity(0.6),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
            Text(
              'No hay cuentas bancarias',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                  fontContext: FontContext.title,
                ),
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ResponsiveHelper.getVerticalSpacing(
                context,
                size: SpacingSize.small,
              ),
            ),
            Text(
              'Crea tu primera cuenta bancaria para gestionar tus metodos de pago',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ResponsiveHelper.getVerticalSpacing(
                context,
                size: SpacingSize.large,
              ),
            ),
            ElegantButton(
              text: 'Crear Primera Cuenta',
              icon: Icons.add_rounded,
              onPressed: () => _showCreateDialog(context),
              gradient: ElegantLightTheme.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ElegantLightTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 56,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No se encontraron cuentas',
            style: TextStyle(
              fontSize: 18,
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              controller.setFilterType(null);
              controller.setShowInactive(false);
            },
            icon: const Icon(Icons.clear_rounded),
            label: const Text('Limpiar filtros'),
            style: TextButton.styleFrom(
              foregroundColor: ElegantLightTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.errorGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Error al cargar las cuentas',
            style: TextStyle(
              fontSize: 18,
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: ElegantLightTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )),
          const SizedBox(height: 24),
          ElegantButton(
            text: 'Reintentar',
            icon: Icons.refresh_rounded,
            onPressed: () => controller.loadBankAccounts(refresh: true),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.glowShadow,
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nueva Cuenta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showCreateDialog(BuildContext context) {
    Get.dialog(
      BankAccountFormDialog(
        onSave: (data) async {
          final success = await controller.createBankAccount(
            name: data['name'],
            type: data['type'],
            bankName: data['bankName'],
            accountNumber: data['accountNumber'],
            holderName: data['holderName'],
            icon: data['icon'],
            description: data['description'],
            isDefault: data['isDefault'] ?? false,
          );
          if (success) {
            Get.back();
            _showSuccessSnackbar('Cuenta creada correctamente');
          } else {
            _showErrorSnackbar(controller.errorMessage.value);
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showEditDialog(BuildContext context, BankAccount account) {
    Get.dialog(
      BankAccountFormDialog(
        account: account,
        onSave: (data) async {
          final success = await controller.updateBankAccount(
            id: account.id,
            name: data['name'],
            type: data['type'],
            bankName: data['bankName'],
            accountNumber: data['accountNumber'],
            holderName: data['holderName'],
            icon: data['icon'],
            description: data['description'],
            isDefault: data['isDefault'],
          );
          if (success) {
            Get.back();
            _showSuccessSnackbar('Cuenta actualizada correctamente');
          } else {
            _showErrorSnackbar(controller.errorMessage.value);
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showAccountDetails(BuildContext context, BankAccount account) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    account.type.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.type.displayName,
                        style: TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (account.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Principal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Details container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ElegantLightTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withOpacity(0.15),
                ),
              ),
              child: Column(
                children: [
                  if (account.bankName != null)
                    _buildDetailRow(
                        Icons.business_rounded, 'Banco', account.bankName!),
                  if (account.accountNumber != null)
                    _buildDetailRow(Icons.numbers_rounded, 'Numero de cuenta',
                        account.accountNumber!),
                  if (account.holderName != null)
                    _buildDetailRow(
                        Icons.person_rounded, 'Titular', account.holderName!),
                  if (account.description != null &&
                      account.description!.isNotEmpty)
                    _buildDetailRow(Icons.description_rounded, 'Descripcion',
                        account.description!),
                  _buildDetailRow(Icons.toggle_on_rounded, 'Estado',
                      account.isActive ? 'Activa' : 'Inactiva'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: _buildElegantOutlinedButton(
                    icon: Icons.edit_rounded,
                    label: 'Editar',
                    onPressed: () {
                      Get.back();
                      _showEditDialog(context, account);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElegantButton(
                    text: 'Cerrar',
                    icon: Icons.close_rounded,
                    onPressed: () => Get.back(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: ElegantLightTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: ElegantLightTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: ElegantLightTheme.primaryBlue,
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

  void _confirmDelete(BuildContext context, BankAccount account) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 400,
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 14 : 16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: isMobile ? 28 : 32,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Text(
                'Eliminar Cuenta',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 12),
              Text(
                '¿Eliminar "${account.name}"?\n\nEsta acción no se puede deshacer.',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: isMobile ? 13 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 20 : 24),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactOutlinedButton(
                      icon: Icons.close_rounded,
                      label: 'No',
                      onPressed: () => Get.back(),
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: _buildCompactFilledButton(
                      icon: Icons.delete_rounded,
                      label: 'Sí',
                      gradient: ElegantLightTheme.errorGradient,
                      onPressed: () async {
                        Get.back();
                        final success =
                            await controller.deleteBankAccount(account.id);
                        if (success) {
                          _showSuccessSnackbar('Cuenta eliminada correctamente');
                        } else {
                          _showErrorSnackbar(controller.errorMessage.value);
                        }
                      },
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 12 : 14,
              horizontal: isMobile ? 12 : 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 16 : 18,
                  color: ElegantLightTheme.textSecondary,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFilledButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 12 : 14,
              horizontal: isMobile ? 12 : 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 16 : 18,
                  color: Colors.white,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setAsDefault(BuildContext context, BankAccount account) async {
    final success = await controller.setDefaultAccount(account.id);
    if (success) {
      _showSuccessSnackbar('"${account.name}" es ahora tu cuenta principal');
    } else {
      _showErrorSnackbar(controller.errorMessage.value);
    }
  }

  void _toggleActive(BuildContext context, BankAccount account) async {
    final success = await controller.toggleAccountActive(account.id);
    if (success) {
      _showSuccessSnackbar(account.isActive
          ? '"${account.name}" desactivada'
          : '"${account.name}" activada');
    } else {
      _showErrorSnackbar(controller.errorMessage.value);
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Exito',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
}
