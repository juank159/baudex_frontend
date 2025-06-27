// lib/features/customers/presentation/widgets/customer_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/entities/customer.dart';

class CustomerCardWidget extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const CustomerCardWidget({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con avatar y estado
          Row(
            children: [
              // Avatar del cliente
              _buildCustomerAvatar(context),
              const SizedBox(width: 12),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.displayName,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 14),
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Estado
              _buildStatusBadge(context),
            ],
          ),

          const SizedBox(height: 12),

          // Información adicional
          if (!isCompact) ...[
            _buildCustomerInfo(context),
            const SizedBox(height: 12),
          ],

          // Acciones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Avatar
          _buildCustomerAvatar(context),
          const SizedBox(width: 16),

          // Información principal
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.displayName,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, tablet: 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  customer.email,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, tablet: 14),
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  customer.formattedDocument,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, tablet: 12),
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Información adicional
          if (!isCompact) Expanded(flex: 2, child: _buildCustomerInfo(context)),

          const SizedBox(width: 16),

          // Estado y acciones
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(context),
              const SizedBox(height: 8),
              _buildActionButtons(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Avatar
          _buildCustomerAvatar(context),
          const SizedBox(width: 20),

          // Información principal
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.displayName,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            desktop: 20,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(context),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            desktop: 14,
                          ),
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      customer.formattedDocument,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, desktop: 14),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Información adicional
          if (!isCompact) Expanded(flex: 2, child: _buildCustomerInfo(context)),

          const SizedBox(width: 20),

          // Acciones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCustomerAvatar(BuildContext context) {
    final iconSize = context.isMobile ? 40.0 : (context.isTablet ? 48.0 : 56.0);

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color:
            customer.isActive
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(iconSize / 2),
        border: Border.all(
          color:
              customer.isActive
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Icon(
        customer.companyName != null ? Icons.business : Icons.person,
        size: iconSize * 0.5,
        color:
            customer.isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.shade500,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String text;

    switch (customer.status) {
      case CustomerStatus.active:
        color = Colors.green;
        text = 'ACTIVO';
        break;
      case CustomerStatus.inactive:
        color = Colors.orange;
        text = 'INACTIVO';
        break;
      case CustomerStatus.suspended:
        color = Colors.red;
        text = 'SUSPENDIDO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: context.isMobile ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customer.city != null)
          _buildInfoItem(
            context,
            'Ciudad',
            customer.city!,
            Icons.location_city,
          ),

        if (customer.phone != null)
          _buildInfoItem(context, 'Teléfono', customer.phone!, Icons.phone),

        _buildInfoItem(
          context,
          'Crédito',
          _formatCurrency(customer.creditLimit),
          Icons.credit_card,
        ),

        if (customer.currentBalance > 0)
          _buildInfoItem(
            context,
            'Balance',
            _formatCurrency(customer.currentBalance),
            Icons.account_balance_wallet,
            valueColor:
                customer.currentBalance > customer.creditLimit * 0.8
                    ? Colors.red
                    : Colors.orange,
          ),

        if (customer.totalOrders > 0)
          _buildInfoItem(
            context,
            'Órdenes',
            '${customer.totalOrders}',
            Icons.shopping_cart,
          ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: context.isMobile ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
      return Row(
        children: [
          if (onEdit != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          if (onEdit != null && onDelete != null) const SizedBox(width: 8),
          if (onDelete != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar cliente',
            iconSize: context.isDesktop ? 24 : 20,
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar cliente',
            color: Colors.red,
            iconSize: context.isDesktop ? 24 : 20,
          ),
      ],
    );
  }

  // String _formatCurrency(double amount) {
  //   return '\${amount.toStringAsFixed(0).replaceAllMapped(
  //     RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  //     (Match m) => '${m[1]},',
  //   )}';
  // }

  String _formatCurrency(
    double? amount, {
    String symbol = '\$',
    int decimals = 0,
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
    bool showSymbol = true,
  }) {
    // Manejar casos nulos o NaN
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return '${showSymbol ? symbol : ''}0';
    }

    // Determinar si es negativo
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();

    // Formatear con decimales especificados
    final formattedNumber = absoluteAmount.toStringAsFixed(decimals);

    // Separar parte entera y decimal
    final parts = formattedNumber.split('.');
    String integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Agregar separadores de miles a la parte entera
    if (integerPart.length > 3) {
      // Usar regex más robusta para separadores de miles
      integerPart = integerPart.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]}$thousandsSeparator',
      );
    }

    // Construir resultado final
    String result = integerPart;

    // Agregar parte decimal si existe y se requiere
    if (decimals > 0 && decimalPart.isNotEmpty) {
      result += '$decimalSeparator$decimalPart';
    }

    // Agregar símbolo de moneda
    if (showSymbol) {
      result = '$symbol$result';
    }

    // Agregar signo negativo si aplica
    if (isNegative) {
      result = '-$result';
    }

    return result;
  }

  // ==================== VERSIONES ESPECÍFICAS ====================

  /// Versión simple para montos sin decimales
  String formatCurrencySimple(double? amount) {
    return _formatCurrency(amount, decimals: 0);
  }

  /// Versión con decimales para montos precisos
  String formatCurrencyWithDecimals(double? amount) {
    return _formatCurrency(amount, decimals: 2);
  }

  /// Versión compacta para montos grandes (1K, 1M, etc.)
  String formatCurrencyCompact(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return '\$0';
    }

    final absoluteAmount = amount.abs();
    final isNegative = amount < 0;
    String result;

    if (absoluteAmount >= 1000000000) {
      // Billones
      result = '\$${(absoluteAmount / 1000000000).toStringAsFixed(1)}B';
    } else if (absoluteAmount >= 1000000) {
      // Millones
      result = '\$${(absoluteAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absoluteAmount >= 1000) {
      // Miles
      result = '\$${(absoluteAmount / 1000).toStringAsFixed(1)}K';
    } else {
      // Menor a mil
      result = '\$${absoluteAmount.toStringAsFixed(0)}';
    }

    return isNegative ? '-$result' : result;
  }

  /// Versión internacional con soporte para diferentes monedas
  String formatCurrencyInternational(
    double? amount, {
    String currencyCode = 'USD',
    String locale = 'en_US',
  }) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return '0';
    }

    // Mapeo de códigos de moneda a símbolos
    const currencySymbols = {
      'USD': '\$',
      'COP': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'MXN': 'MX\$',
    };

    final symbol = currencySymbols[currencyCode] ?? '\$';

    // Configuración por locale
    String thousandsSeparator = ',';
    String decimalSeparator = '.';
    int decimals = 2;

    if (locale.startsWith('es') || currencyCode == 'COP') {
      // Formato colombiano/español
      thousandsSeparator = '.';
      decimalSeparator = ',';
    }

    // JPY típicamente no usa decimales
    if (currencyCode == 'JPY') {
      decimals = 0;
    }

    return _formatCurrency(
      amount,
      symbol: symbol,
      decimals: decimals,
      thousandsSeparator: thousandsSeparator,
      decimalSeparator: decimalSeparator,
    );
  }

  /// Versión para Colombia (formato local)
  String formatCurrencyColombian(double? amount) {
    return formatCurrencyInternational(
      amount,
      currencyCode: 'COP',
      locale: 'es_CO',
    );
  }

  // ==================== UTILIDADES ADICIONALES ====================

  /// Convierte string a double de forma segura
  double? parseCurrencyString(String value) {
    if (value.isEmpty) return null;

    // Remover símbolos de moneda y espacios
    String cleanValue = value
        .replaceAll(RegExp(r'[\$€£¥,.\s]'), '')
        .replaceAll(RegExp(r'[A-Za-z]'), '');

    return double.tryParse(cleanValue);
  }

  /// Validar si un string es un monto válido
  bool isValidCurrencyString(String value) {
    if (value.isEmpty) return false;
    return parseCurrencyString(value) != null;
  }

  /// Formatear porcentaje
  String formatPercentage(double? value, {int decimals = 1}) {
    if (value == null || value.isNaN || value.isInfinite) {
      return '0%';
    }
    return '${value.toStringAsFixed(decimals)}%';
  }

  // ==================== EJEMPLOS DE USO ====================

  void _ejemplosDeUso() {
    const amount = 1234567.89;

    print('Simple: ${formatCurrencySimple(amount)}'); // $1,234,568
    print(
      'Con decimales: ${formatCurrencyWithDecimals(amount)}',
    ); // $1,234,567.89
    print('Compacto: ${formatCurrencyCompact(amount)}'); // $1.2M
    print('Colombiano: ${formatCurrencyColombian(amount)}'); // $1.234.567,89
    print(
      'Internacional EUR: ${formatCurrencyInternational(amount, currencyCode: 'EUR')}',
    ); // €1,234,567.89

    // Casos especiales
    print('Negativo: ${formatCurrencySimple(-1000)}'); // -$1,000
    print('Cero: ${formatCurrencySimple(0)}'); // $0
    print('Null: ${formatCurrencySimple(null)}'); // $0
    print('NaN: ${formatCurrencySimple(double.nan)}'); // $0
  }
}
