// lib/features/expenses/presentation/widgets/modern_expense_selector_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/expense.dart';

class ModernExpenseTypeSelector extends StatelessWidget {
  final ExpenseType? value;
  final Function(ExpenseType?) onChanged;
  final bool isRequired;

  const ModernExpenseTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSelector(context),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.accentOrange.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  value != null ? _getIcon(value!) : Icons.category,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tipo de Gasto${isRequired ? ' *' : ''}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value?.displayName ?? 'Seleccionar tipo',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: value != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: ElegantLightTheme.primaryBlue,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpenseTypeBottomSheet(
        currentValue: value,
        onSelected: (selectedValue) {
          onChanged(selectedValue);
          Navigator.pop(context);
        },
      ),
    );
  }

  IconData _getIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return Icons.business_center;
      case ExpenseType.administrative:
        return Icons.admin_panel_settings;
      case ExpenseType.sales:
        return Icons.point_of_sale;
      case ExpenseType.financial:
        return Icons.account_balance;
      case ExpenseType.extraordinary:
        return Icons.warning_amber;
    }
  }
}

class _ExpenseTypeBottomSheet extends StatefulWidget {
  final ExpenseType? currentValue;
  final Function(ExpenseType) onSelected;

  const _ExpenseTypeBottomSheet({
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_ExpenseTypeBottomSheet> createState() =>
      _ExpenseTypeBottomSheetState();
}

class _ExpenseTypeBottomSheetState extends State<_ExpenseTypeBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return Icons.business_center;
      case ExpenseType.administrative:
        return Icons.admin_panel_settings;
      case ExpenseType.sales:
        return Icons.point_of_sale;
      case ExpenseType.financial:
        return Icons.account_balance;
      case ExpenseType.extraordinary:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 300),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                ),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.accentOrange.withValues(alpha: 0.05),
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
                            gradient: ElegantLightTheme.warningGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: ElegantLightTheme.accentOrange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.category,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Seleccionar Tipo de Gasto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                            foregroundColor: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: ExpenseType.values.length,
                      itemBuilder: (context, index) {
                        final type = ExpenseType.values[index];
                        final isSelected = type == widget.currentValue;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onSelected(type),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            ElegantLightTheme.accentOrange.withValues(alpha: 0.15),
                                            ElegantLightTheme.accentOrange.withValues(alpha: 0.05),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? ElegantLightTheme.accentOrange
                                        : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? ElegantLightTheme.accentOrange.withValues(alpha: 0.2)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getIcon(type),
                                        size: 20,
                                        color: isSelected
                                            ? ElegantLightTheme.accentOrange
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: Text(
                                        type.displayName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? ElegantLightTheme.accentOrange
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: ElegantLightTheme.warningGradient,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: ElegantLightTheme.accentOrange.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ModernPaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? value;
  final Function(PaymentMethod?) onChanged;
  final bool isRequired;

  const ModernPaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSelector(context),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade600.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  value != null ? _getIcon(value!) : Icons.payment,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Método de Pago${isRequired ? ' *' : ''}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value?.displayName ?? 'Seleccionar método',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: value != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.green.shade600,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentMethodBottomSheet(
        currentValue: value,
        onSelected: (selectedValue) {
          onChanged(selectedValue);
          Navigator.pop(context);
        },
      ),
    );
  }

  IconData _getIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.request_page;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }
}

class _PaymentMethodBottomSheet extends StatefulWidget {
  final PaymentMethod? currentValue;
  final Function(PaymentMethod) onSelected;

  const _PaymentMethodBottomSheet({
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<_PaymentMethodBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.request_page;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 300),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                ),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
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
                            gradient: ElegantLightTheme.successGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade600.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.payment,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Seleccionar Método de Pago',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                            foregroundColor: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: PaymentMethod.values.length,
                      itemBuilder: (context, index) {
                        final method = PaymentMethod.values[index];
                        final isSelected = method == widget.currentValue;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onSelected(method),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            Colors.green.shade100,
                                            Colors.green.shade50,
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green.shade600
                                        : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.green.shade100
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getIcon(method),
                                        size: 20,
                                        color: isSelected
                                            ? Colors.green.shade600
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: Text(
                                        method.displayName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.green.shade700
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: ElegantLightTheme.successGradient,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.shade600.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
