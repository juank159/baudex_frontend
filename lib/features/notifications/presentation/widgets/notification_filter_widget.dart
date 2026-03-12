// lib/features/notifications/presentation/widgets/notification_filter_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../dashboard/domain/entities/notification.dart' as entities;

class NotificationFilterWidget extends StatefulWidget {
  final bool showUnreadOnly;
  final entities.NotificationType? selectedType;
  final entities.NotificationPriority? selectedPriority;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(bool) onUnreadOnlyChanged;
  final Function(entities.NotificationType?) onTypeChanged;
  final Function(entities.NotificationPriority?) onPriorityChanged;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final VoidCallback onClearFilters;

  const NotificationFilterWidget({
    super.key,
    required this.showUnreadOnly,
    required this.selectedType,
    required this.selectedPriority,
    required this.startDate,
    required this.endDate,
    required this.onUnreadOnlyChanged,
    required this.onTypeChanged,
    required this.onPriorityChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
  });

  @override
  State<NotificationFilterWidget> createState() => _NotificationFilterWidgetState();
}

class _NotificationFilterWidgetState extends State<NotificationFilterWidget> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: ElegantLightTheme.glassShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_list_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            ElegantLightTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          'Filtros',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildClearButton(),
                ],
              ),
              const SizedBox(height: 24),

              // Filtro de no leidas con estilo elegante
              _buildUnreadSwitch(),
              const SizedBox(height: 20),
              _buildElegantDivider(),
              const SizedBox(height: 20),

              // Filtro por tipo
              _buildSectionTitle(
                icon: Icons.category_rounded,
                title: 'Tipo de notificacion',
                gradient: ElegantLightTheme.infoGradient,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTypeChip(null, 'Todos', Icons.apps_rounded),
                  ...entities.NotificationType.values.map(
                    (type) => _buildTypeChip(type, type.displayName, _getTypeIcon(type)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildElegantDivider(),
              const SizedBox(height: 20),

              // Filtro por prioridad
              _buildSectionTitle(
                icon: Icons.priority_high_rounded,
                title: 'Prioridad',
                gradient: ElegantLightTheme.warningGradient,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPriorityChip(null, 'Todas'),
                  ...entities.NotificationPriority.values.map(
                    (priority) => _buildPriorityChip(priority, priority.displayName),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onClearFilters,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ElegantLightTheme.errorRed.withOpacity(0.12),
                ElegantLightTheme.errorRed.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.errorRed.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.clear_all_rounded,
                size: 18,
                color: ElegantLightTheme.errorRed,
              ),
              const SizedBox(width: 6),
              Text(
                'Limpiar',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.errorRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadSwitch() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.showUnreadOnly
                  ? [
                      ElegantLightTheme.warningOrange.withOpacity(0.15),
                      ElegantLightTheme.warningOrange.withOpacity(0.08),
                    ]
                  : [
                      Colors.grey.withOpacity(0.08),
                      Colors.grey.withOpacity(0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.showUnreadOnly
                  ? ElegantLightTheme.warningOrange.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: widget.showUnreadOnly
                      ? ElegantLightTheme.warningGradient
                      : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: widget.showUnreadOnly
                      ? [
                          BoxShadow(
                            color: ElegantLightTheme.warningOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.showUnreadOnly
                      ? Icons.circle_notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solo no leidas',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Text(
                      widget.showUnreadOnly
                          ? 'Mostrando notificaciones sin leer'
                          : 'Mostrando todas las notificaciones',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: widget.showUnreadOnly,
                  onChanged: widget.onUnreadOnlyChanged,
                  activeColor: ElegantLightTheme.warningOrange,
                  activeTrackColor: ElegantLightTheme.warningOrange.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            ElegantLightTheme.primaryBlue.withOpacity(0.2),
            ElegantLightTheme.primaryBlue.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required LinearGradient gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(entities.NotificationType? type, String label, IconData icon) {
    final isSelected = widget.selectedType == type;
    final color = type != null ? _getTypeColor(type) : ElegantLightTheme.primaryBlue;
    final gradient = type != null ? _getTypeGradient(type) : ElegantLightTheme.primaryGradient;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTypeChanged(type),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? gradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.withOpacity(0.08),
                      Colors.grey.withOpacity(0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(entities.NotificationPriority? priority, String label) {
    final isSelected = widget.selectedPriority == priority;
    final color = priority != null ? _getPriorityColor(priority) : Colors.grey.shade600;
    final gradient = priority != null ? _getPriorityGradient(priority) : LinearGradient(
      colors: [Colors.grey.shade500, Colors.grey.shade600],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onPriorityChanged(priority),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? gradient
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.withOpacity(0.08),
                      Colors.grey.withOpacity(0.04),
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPriorityIcon(priority),
                size: 16,
                color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(entities.NotificationType type) {
    switch (type) {
      case entities.NotificationType.system:
        return Icons.settings_rounded;
      case entities.NotificationType.payment:
        return Icons.payment_rounded;
      case entities.NotificationType.invoice:
        return Icons.receipt_long_rounded;
      case entities.NotificationType.lowStock:
        return Icons.inventory_rounded;
      case entities.NotificationType.expense:
        return Icons.trending_down_rounded;
      case entities.NotificationType.sale:
        return Icons.trending_up_rounded;
      case entities.NotificationType.user:
        return Icons.person_rounded;
      case entities.NotificationType.reminder:
        return Icons.schedule_rounded;
    }
  }

  Color _getTypeColor(entities.NotificationType type) {
    switch (type) {
      case entities.NotificationType.system:
        return const Color(0xFF6366F1);
      case entities.NotificationType.payment:
        return ElegantLightTheme.successGreen;
      case entities.NotificationType.invoice:
        return ElegantLightTheme.primaryBlue;
      case entities.NotificationType.lowStock:
        return ElegantLightTheme.warningOrange;
      case entities.NotificationType.expense:
        return ElegantLightTheme.errorRed;
      case entities.NotificationType.sale:
        return const Color(0xFF14B8A6);
      case entities.NotificationType.user:
        return const Color(0xFF8B5CF6);
      case entities.NotificationType.reminder:
        return const Color(0xFFF59E0B);
    }
  }

  LinearGradient _getTypeGradient(entities.NotificationType type) {
    switch (type) {
      case entities.NotificationType.system:
        return const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]);
      case entities.NotificationType.payment:
        return ElegantLightTheme.successGradient;
      case entities.NotificationType.invoice:
        return ElegantLightTheme.infoGradient;
      case entities.NotificationType.lowStock:
        return ElegantLightTheme.warningGradient;
      case entities.NotificationType.expense:
        return ElegantLightTheme.errorGradient;
      case entities.NotificationType.sale:
        return const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]);
      case entities.NotificationType.user:
        return const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]);
      case entities.NotificationType.reminder:
        return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
    }
  }

  Color _getPriorityColor(entities.NotificationPriority priority) {
    switch (priority) {
      case entities.NotificationPriority.low:
        return const Color(0xFF64748B);
      case entities.NotificationPriority.medium:
        return ElegantLightTheme.primaryBlue;
      case entities.NotificationPriority.high:
        return ElegantLightTheme.warningOrange;
      case entities.NotificationPriority.urgent:
        return ElegantLightTheme.errorRed;
    }
  }

  LinearGradient _getPriorityGradient(entities.NotificationPriority priority) {
    switch (priority) {
      case entities.NotificationPriority.low:
        return const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]);
      case entities.NotificationPriority.medium:
        return ElegantLightTheme.infoGradient;
      case entities.NotificationPriority.high:
        return ElegantLightTheme.warningGradient;
      case entities.NotificationPriority.urgent:
        return ElegantLightTheme.errorGradient;
    }
  }

  IconData _getPriorityIcon(entities.NotificationPriority? priority) {
    if (priority == null) return Icons.all_inclusive_rounded;
    switch (priority) {
      case entities.NotificationPriority.low:
        return Icons.arrow_downward_rounded;
      case entities.NotificationPriority.medium:
        return Icons.remove_rounded;
      case entities.NotificationPriority.high:
        return Icons.arrow_upward_rounded;
      case entities.NotificationPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}
