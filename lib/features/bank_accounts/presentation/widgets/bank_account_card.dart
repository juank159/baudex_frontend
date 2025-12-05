// lib/features/bank_accounts/presentation/widgets/bank_account_card.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/bank_account.dart';
import 'bank_account_form_dialog.dart';

/// Widget de tarjeta elegante para mostrar una cuenta bancaria
class BankAccountCard extends StatefulWidget {
  final BankAccount account;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;
  final VoidCallback? onToggleActive;

  const BankAccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
    this.onToggleActive,
  });

  @override
  State<BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<BankAccountCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: ElegantLightTheme.normalAnimation,
                curve: ElegantLightTheme.smoothCurve,
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                        : ElegantLightTheme.textTertiary.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    ...ElegantLightTheme.elevatedShadow,
                    if (_isHovered) ...ElegantLightTheme.glowShadow,
                  ],
                ),
                child: Opacity(
                  opacity: widget.account.isActive ? 1.0 : 0.7,
                  child: Padding(
                    padding: ResponsiveHelper.getPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            // Icon container con gradiente
                            _buildIcon(context),
                            SizedBox(
                                width:
                                    ResponsiveHelper.getHorizontalSpacing(context)),

                            // Account info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name with default badge
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.account.name,
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.getFontSize(
                                              context,
                                              mobile: 16,
                                              tablet: 17,
                                              desktop: 18,
                                            ),
                                            fontWeight: FontWeight.w700,
                                            color: widget.account.isActive
                                                ? ElegantLightTheme.textPrimary
                                                : ElegantLightTheme.textTertiary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (widget.account.isDefault)
                                        _buildDefaultBadge(),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Type
                                  Text(
                                    widget.account.type.displayName,
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getFontSize(
                                        context,
                                        mobile: 13,
                                        tablet: 14,
                                        desktop: 14,
                                      ),
                                      color: ElegantLightTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status badge
                            _buildStatusBadge(context),
                          ],
                        ),

                        // Details section
                        if (widget.account.bankName != null ||
                            widget.account.accountNumber != null ||
                            widget.account.holderName != null) ...[
                          SizedBox(
                              height: ResponsiveHelper.getVerticalSpacing(context,
                                  size: SpacingSize.small)),
                          _buildDetailsSection(context),
                        ],

                        // Actions
                        SizedBox(
                            height: ResponsiveHelper.getVerticalSpacing(context,
                                size: SpacingSize.small)),
                        _buildActionsRow(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(BuildContext context) {
    final iconSize = ResponsiveHelper.getHeight(
      context,
      mobile: 52.0,
      tablet: 56.0,
      desktop: 60.0,
    );

    // Usar el icono personalizado si existe, de lo contrario usar el icono del tipo
    final hasCustomIcon = widget.account.icon != null && widget.account.icon!.isNotEmpty;
    final iconData = hasCustomIcon
        ? BankAccountIcon.getIconData(widget.account.icon)
        : widget.account.type.icon;
    final iconColor = hasCustomIcon
        ? BankAccountIcon.getIconColor(widget.account.icon)
        : _getTypeColor(widget.account.type);

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        gradient: widget.account.isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.15),
                  iconColor.withOpacity(0.05),
                ],
              )
            : null,
        color: widget.account.isActive ? null : ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.account.isActive
              ? iconColor.withOpacity(0.3)
              : ElegantLightTheme.textTertiary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: widget.account.isActive
            ? [
                BoxShadow(
                  color: iconColor.withOpacity(0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Icon(
        iconData,
        size: iconSize * 0.48,
        color: widget.account.isActive ? iconColor : ElegantLightTheme.textTertiary,
      ),
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.warningGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Principal',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isActive = widget.account.isActive;

    return AnimatedContainer(
      duration: ElegantLightTheme.normalAnimation,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isActive
            ? ElegantLightTheme.successGradient
            : LinearGradient(
                colors: [
                  ElegantLightTheme.textTertiary.withOpacity(0.3),
                  ElegantLightTheme.textTertiary.withOpacity(0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Text(
        isActive ? 'ACTIVA' : 'INACTIVA',
        style: TextStyle(
          color: isActive ? Colors.white : ElegantLightTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          if (widget.account.bankName != null)
            _buildDetailItem(
                Icons.business_rounded, 'Banco', widget.account.bankName!),
          if (widget.account.accountNumber != null)
            _buildDetailItem(Icons.numbers_rounded, 'Cuenta',
                _maskAccountNumber(widget.account.accountNumber!)),
          if (widget.account.holderName != null)
            _buildDetailItem(
                Icons.person_rounded, 'Titular', widget.account.holderName!),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return Row(
        children: [
          if (widget.onSetDefault != null && !widget.account.isDefault)
            Expanded(
              child: _buildActionButton(
                icon: Icons.star_outline_rounded,
                label: 'Principal',
                onPressed: widget.onSetDefault!,
                gradient: ElegantLightTheme.warningGradient,
              ),
            ),
          if (widget.onEdit != null) ...[
            if (widget.onSetDefault != null && !widget.account.isDefault)
              const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.edit_rounded,
                label: 'Editar',
                onPressed: widget.onEdit!,
                gradient: ElegantLightTheme.primaryGradient,
              ),
            ),
          ],
          if (widget.onDelete != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar',
                onPressed: widget.onDelete!,
                gradient: ElegantLightTheme.errorGradient,
              ),
            ),
          ],
        ],
      );
    }

    // Desktop/Tablet - icon buttons elegantes
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onToggleActive != null)
          _buildIconButton(
            icon: widget.account.isActive
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            tooltip: widget.account.isActive ? 'Desactivar' : 'Activar',
            onPressed: widget.onToggleActive!,
            color: ElegantLightTheme.textSecondary,
          ),
        if (widget.onSetDefault != null && !widget.account.isDefault)
          _buildIconButton(
            icon: Icons.star_outline_rounded,
            tooltip: 'Establecer como principal',
            onPressed: widget.onSetDefault!,
            color: const Color(0xFFF59E0B),
          ),
        if (widget.onEdit != null)
          _buildIconButton(
            icon: Icons.edit_rounded,
            tooltip: 'Editar cuenta',
            onPressed: widget.onEdit!,
            color: ElegantLightTheme.primaryBlue,
          ),
        if (widget.onDelete != null)
          _buildIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Eliminar cuenta',
            onPressed: widget.onDelete!,
            color: const Color(0xFFEF4444),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
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

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return const Color(0xFF10B981); // Green
      case BankAccountType.savings:
        return const Color(0xFF3B82F6); // Blue
      case BankAccountType.checking:
        return const Color(0xFF6366F1); // Indigo
      case BankAccountType.digitalWallet:
        return const Color(0xFF8B5CF6); // Purple
      case BankAccountType.creditCard:
        return const Color(0xFFF59E0B); // Orange
      case BankAccountType.debitCard:
        return const Color(0xFF14B8A6); // Teal
      case BankAccountType.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    final visible = number.substring(number.length - 4);
    return '****$visible';
  }
}
