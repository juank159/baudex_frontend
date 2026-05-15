// lib/features/notifications/presentation/screens/notification_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../dashboard/domain/entities/notification.dart' as entities;
import '../controllers/notifications_controller.dart';

class NotificationDetailScreen extends GetView<NotificationsController> {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String notificationId = Get.parameters['id'] ?? '';

    return Scaffold(
      backgroundColor: ElegantLightTheme.scaffoldBackground,
      appBar: _buildModernAppBar(context, notificationId),
      body: Obx(() {
        final notification = controller.notifications
            .firstWhereOrNull((n) => n.id == notificationId);

        if (notification == null) {
          return _buildNotFoundState(context);
        }

        return ResponsiveHelper.isMobile(context)
            ? _buildMobileLayout(context, notification)
            : _buildDesktopLayout(context, notification);
      }),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, String notificationId) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: _buildAppBarBackButton(),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) =>
                ElegantLightTheme.primaryGradient.createShader(bounds),
            child: Text(
              'Detalle',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _buildAppBarActionButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Eliminar',
          color: ElegantLightTheme.errorRed,
          onPressed: () => _confirmDelete(context, notificationId),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: 'Volver',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ElegantLightTheme.primaryBlue.withOpacity(0.08),
                    ElegantLightTheme.primaryBlue.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: ElegantLightTheme.primaryBlue,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.12),
                    color.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.2),
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, entities.Notification notification) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationHeader(context, notification),
          const SizedBox(height: 20),
          _buildNotificationBody(context, notification),
          const SizedBox(height: 20),
          _buildActionButtons(context, notification),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, entities.Notification notification) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationHeader(context, notification),
              const SizedBox(height: 28),
              _buildNotificationBody(context, notification),
              const SizedBox(height: 28),
              _buildActionButtons(context, notification),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationHeader(BuildContext context, entities.Notification notification) {
    final typeColor = _getTypeColor(notification.type);
    final typeGradient = _getTypeGradient(notification.type);

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
              color: typeColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              ...ElegantLightTheme.glassShadow,
              BoxShadow(
                color: typeColor.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(notification.type),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: typeGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notification.formattedTime,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 13,
                                color: ElegantLightTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildPriorityBadge(notification.priority),
                ],
              ),
              const SizedBox(height: 20),
              _buildElegantDivider(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildInfoChip(
                    icon: _getTypeIconData(notification.type),
                    label: notification.type.displayName,
                    color: typeColor,
                    gradient: typeGradient,
                  ),
                  _buildInfoChip(
                    icon: notification.isRead
                        ? Icons.check_circle_rounded
                        : Icons.circle_notifications_rounded,
                    label: notification.isRead ? 'Leida' : 'No leida',
                    color: notification.isRead
                        ? ElegantLightTheme.successGreen
                        : ElegantLightTheme.warningOrange,
                    gradient: notification.isRead
                        ? ElegantLightTheme.successGradient
                        : ElegantLightTheme.warningGradient,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBody(BuildContext context, entities.Notification notification) {
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
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
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
                      Icons.message_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        ElegantLightTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      'Mensaje',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  notification.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    height: 1.7,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ),
              if (notification.relatedId != null) ...[
                const SizedBox(height: 20),
                _buildElegantDivider(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ElegantLightTheme.primaryBlue.withOpacity(0.08),
                        ElegantLightTheme.primaryBlue.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Relacionado con: ${notification.relatedId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 13,
                          color: ElegantLightTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, entities.Notification notification) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.successGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        ElegantLightTheme.successGradient.createShader(bounds),
                    child: Text(
                      'Acciones',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!notification.isRead)
                _buildElegantButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Marcar como leida',
                  gradient: ElegantLightTheme.successGradient,
                  onPressed: () {
                    controller.markAsRead(notification.id);
                    Get.snackbar(
                      'Exito',
                      'Notificacion marcada como leida',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: ElegantLightTheme.successGreen.withOpacity(0.9),
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                ),
              if (notification.isRead) ...[
                _buildElegantOutlinedButton(
                  icon: Icons.circle_notifications_rounded,
                  label: 'Marcar como no leida',
                  color: ElegantLightTheme.primaryBlue,
                  onPressed: () {
                    Get.snackbar(
                      'Info',
                      'Funcionalidad pendiente',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: ElegantLightTheme.primaryBlue.withOpacity(0.9),
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                ),
              ],
              if (notification.actionData != null) ...[
                const SizedBox(height: 12),
                _buildElegantButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Ver detalles',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                  ),
                  onPressed: () => _handleRelatedAction(context, notification),
                ),
              ],
              const SizedBox(height: 12),
              _buildElegantOutlinedButton(
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar notificacion',
                color: ElegantLightTheme.errorRed,
                onPressed: () => _confirmDelete(context, notification.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantOutlinedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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

  Widget _buildTypeIcon(entities.NotificationType type) {
    final iconData = _getTypeIconData(type);
    final gradient = _getTypeGradient(type);
    final color = _getTypeColor(type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(iconData, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(entities.NotificationPriority priority) {
    final color = _getPriorityColor(priority);
    final gradient = _getPriorityGradient(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(priority), size: 14, color: color),
          const SizedBox(width: 6),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              priority.displayName.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ElegantLightTheme.warningOrange.withOpacity(0.15),
                          ElegantLightTheme.warningOrange.withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ElegantLightTheme.warningOrange.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.warningOrange.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: ElegantLightTheme.warningOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (bounds) =>
                    ElegantLightTheme.warningGradient.createShader(bounds),
                child: Text(
                  'Notificacion no encontrada',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'La notificacion que buscas no existe o fue eliminada',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _buildElegantButton(
                icon: Icons.arrow_back_rounded,
                label: 'Volver',
                gradient: ElegantLightTheme.primaryGradient,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIconData(entities.NotificationType type) {
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

  IconData _getPriorityIcon(entities.NotificationPriority priority) {
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

  void _handleRelatedAction(BuildContext context, entities.Notification notification) {
    switch (notification.type) {
      case entities.NotificationType.invoice:
        Get.toNamed('/invoices/${notification.relatedId}');
        break;
      case entities.NotificationType.payment:
        Get.toNamed('/payments/${notification.relatedId}');
        break;
      case entities.NotificationType.sale:
        Get.toNamed('/sales/${notification.relatedId}');
        break;
      default:
        Get.snackbar(
          'Info',
          'Accion no disponible para este tipo de notificacion',
          snackPosition: SnackPosition.TOP,
          backgroundColor: ElegantLightTheme.primaryBlue.withOpacity(0.9),
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
    }
  }

  void _confirmDelete(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: ElegantLightTheme.glassDecoration(
                borderColor: ElegantLightTheme.errorRed.withOpacity(0.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.errorGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.errorRed.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Eliminar notificacion',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estas seguro de que deseas eliminar esta notificacion? Esta accion no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildElegantButton(
                          icon: Icons.delete_rounded,
                          label: 'Eliminar',
                          gradient: ElegantLightTheme.errorGradient,
                          onPressed: () {
                            controller.deleteNotification(notificationId);
                            Get.back();
                            Get.back();
                            Get.snackbar(
                              'Exito',
                              'Notificacion eliminada',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: ElegantLightTheme.successGreen.withOpacity(0.9),
                              colorText: Colors.white,
                              borderRadius: 12,
                              margin: const EdgeInsets.all(16),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
