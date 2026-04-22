// lib/features/auth/presentation/screens/profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../subscriptions/domain/entities/subscription_enums.dart';
import '../../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MainLayout provee el drawer de navegación global (igual que en
    // Configuración de Organización) para consistencia de la app.
    return MainLayout(
      title: 'Mi Perfil',
      showDrawer: true,
      showBackButton: false,
      actions: const [
        SyncStatusIcon(),
        SizedBox(width: 8),
      ],
      body: Obx(() {
        if (controller.isProfileLoading) {
          return _buildLoadingState();
        }

        if (controller.currentUser == null) {
          return _buildErrorState(context);
        }

        return ResponsiveHelper.isMobile(context)
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context);
      }),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(context),
          const SizedBox(height: 16),
          _buildProfileInfo(context),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel izquierdo
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: 20),
                    _buildActionButtons(context),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Panel derecho
              Expanded(
                child: _buildProfileInfo(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PROFILE HEADER ====================

  Widget _buildProfileHeader(BuildContext context) {
    final user = controller.currentUser!;
    final isMobile = ResponsiveHelper.isMobile(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 24 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            children: [
              // Avatar con borde gradiente
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isMobile ? 48 : 56,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child: user.avatar == null
                      ? Icon(
                          Icons.person_rounded,
                          size: isMobile ? 48 : 56,
                          color: ElegantLightTheme.primaryBlue,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 18),

              // Nombre con gradiente
              ShaderMask(
                shaderCallback: (bounds) =>
                    ElegantLightTheme.primaryGradient.createShader(bounds),
                child: Text(
                  user.fullName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 22 : 26,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 6),

              // Email
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isMobile ? 14 : 15,
                  color: ElegantLightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  // Badge de rol
                  _buildBadge(
                    icon: Icons.shield_rounded,
                    label: _getRoleText(user.role),
                    gradient: _getRoleGradient(user.role),
                    color: _getRoleColor(user.role),
                  ),
                  // Badge de organización
                  if (user.organizationName != null)
                    _buildBadge(
                      icon: Icons.business_rounded,
                      label: user.organizationName!,
                      gradient: ElegantLightTheme.primaryGradient,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  // Badge de estado basado en la SUSCRIPCIÓN (no el usuario)
                  _buildSubscriptionStatusBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required Color color,
    double iconSize = 14,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PROFILE INFO ====================

  Widget _buildProfileInfo(BuildContext context) {
    final user = controller.currentUser!;
    final isMobile = ResponsiveHelper.isMobile(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de sección
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
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        ElegantLightTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      'Información Personal',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 18 : 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildInfoItem(
                icon: Icons.person_outline_rounded,
                label: 'Nombre',
                value: user.firstName,
                gradient: ElegantLightTheme.primaryGradient,
                color: ElegantLightTheme.primaryBlue,
              ),

              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.person_outline_rounded,
                label: 'Apellido',
                value: user.lastName,
                gradient: ElegantLightTheme.primaryGradient,
                color: ElegantLightTheme.primaryBlue,
              ),

              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.email_outlined,
                label: 'Correo Electrónico',
                value: user.email,
                gradient: ElegantLightTheme.infoGradient,
                color: ElegantLightTheme.primaryBlue,
              ),

              if (user.phone != null) ...[
                const SizedBox(height: 12),
                _buildInfoItem(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: user.phone!,
                  gradient: ElegantLightTheme.successGradient,
                  color: ElegantLightTheme.successGreen,
                ),
              ],

              const SizedBox(height: 12),

              _buildSubscriptionStatusInfo(),

              if (user.lastLoginAt != null) ...[
                const SizedBox(height: 12),
                _buildInfoItem(
                  icon: Icons.access_time_rounded,
                  label: 'Último Acceso',
                  value: _formatDateTime(user.lastLoginAt!),
                  gradient: ElegantLightTheme.warningGradient,
                  color: ElegantLightTheme.warningOrange,
                ),
              ],

              const SizedBox(height: 12),

              _buildInfoItem(
                icon: Icons.calendar_today_outlined,
                label: 'Miembro Desde',
                value: _formatMemberSince(user.createdAt),
                gradient: ElegantLightTheme.successGradient,
                color: ElegantLightTheme.successGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Editar perfil (nombre, apellido, teléfono)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditProfileDialog(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          ElegantLightTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: ElegantLightTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Editar perfil',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: ElegantLightTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cambiar contraseña
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showChangePasswordDialog(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Cambiar Contraseña',
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
              ),

              const SizedBox(height: 12),

              // Cerrar sesión
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ElegantLightTheme.errorRed.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: ElegantLightTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Cerrar Sesión',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: ElegantLightTheme.errorRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== STATES ====================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando perfil...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: ElegantLightTheme.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
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
                        ElegantLightTheme.errorRed.withOpacity(0.15),
                        ElegantLightTheme.errorRed.withOpacity(0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ElegantLightTheme.errorRed.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: ElegantLightTheme.errorRed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) =>
                  ElegantLightTheme.errorGradient.createShader(bounds),
              child: Text(
                'Error al cargar el perfil',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.getProfile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Reintentar',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                  color: ElegantLightTheme.errorRed.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: ElegantLightTheme.elevatedShadow,
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
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cerrar Sesión',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¿Estás seguro que deseas cerrar sesión?',
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Get.back();
                              controller.logout();
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.errorGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: ElegantLightTheme.errorRed.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Salir',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  // ==================== HELPERS ====================

  Color _getRoleColor(dynamic role) {
    final roleStr = role.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
        return ElegantLightTheme.errorRed;
      case 'manager':
        return ElegantLightTheme.warningOrange;
      case 'user':
      default:
        return ElegantLightTheme.primaryBlue;
    }
  }

  LinearGradient _getRoleGradient(dynamic role) {
    final roleStr = role.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
        return ElegantLightTheme.errorGradient;
      case 'manager':
        return ElegantLightTheme.warningGradient;
      case 'user':
      default:
        return ElegantLightTheme.primaryGradient;
    }
  }

  String _getRoleText(dynamic role) {
    final roleStr = role.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'user':
      default:
        return 'Usuario';
    }
  }

  // ==================== SUSCRIPCIÓN (estado real) ====================

  /// Lee el estado de la suscripción desde SubscriptionController. Se usa
  /// tanto para el badge del header como para el ítem de Información.
  /// Fallback a "Sin suscripción" si el controller no está registrado o no
  /// tiene datos cargados aún.
  ({String label, Color color, LinearGradient gradient}) _subscriptionStatus() {
    try {
      if (Get.isRegistered<SubscriptionController>()) {
        final sub = Get.find<SubscriptionController>().subscription;
        if (sub != null) {
          final name = sub.status.displayName;
          switch (sub.status) {
            case SubscriptionStatus.active:
              return (
                label: name,
                color: ElegantLightTheme.successGreen,
                gradient: ElegantLightTheme.successGradient,
              );
            case SubscriptionStatus.pending:
              return (
                label: name,
                color: ElegantLightTheme.warningOrange,
                gradient: ElegantLightTheme.warningGradient,
              );
            case SubscriptionStatus.expired:
            case SubscriptionStatus.cancelled:
            case SubscriptionStatus.suspended:
              return (
                label: name,
                color: ElegantLightTheme.errorRed,
                gradient: ElegantLightTheme.errorGradient,
              );
          }
        }
      }
    } catch (_) {}
    return (
      label: 'Sin suscripción',
      color: ElegantLightTheme.textSecondary,
      gradient: ElegantLightTheme.primaryGradient,
    );
  }

  Widget _buildSubscriptionStatusBadge() {
    return Obx(() {
      // Lee `.subscription` (getter que accede a Rxn<Subscription>.value)
      // para suscribir el Obx y reconstruir cuando cambie.
      if (Get.isRegistered<SubscriptionController>()) {
        Get.find<SubscriptionController>().subscription;
      }
      final info = _subscriptionStatus();
      return _buildBadge(
        icon: Icons.circle,
        label: info.label,
        gradient: info.gradient,
        color: info.color,
        iconSize: 8,
      );
    });
  }

  Widget _buildSubscriptionStatusInfo() {
    return Obx(() {
      if (Get.isRegistered<SubscriptionController>()) {
        Get.find<SubscriptionController>().subscription;
      }
      final info = _subscriptionStatus();
      return _buildInfoItem(
        icon: Icons.verified_user_outlined,
        label: 'Estado de la suscripción',
        value: info.label,
        gradient: info.gradient,
        color: info.color,
      );
    });
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'active':
        return ElegantLightTheme.successGreen;
      case 'inactive':
        return ElegantLightTheme.warningOrange;
      case 'suspended':
        return ElegantLightTheme.errorRed;
      default:
        return ElegantLightTheme.textSecondary;
    }
  }

  LinearGradient _getStatusGradient(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'active':
        return ElegantLightTheme.successGradient;
      case 'inactive':
        return ElegantLightTheme.warningGradient;
      case 'suspended':
        return ElegantLightTheme.errorGradient;
      default:
        return ElegantLightTheme.primaryGradient;
    }
  }

  String _getStatusText(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'active':
        return 'Activo';
      case 'inactive':
        return 'Inactivo';
      case 'suspended':
        return 'Suspendido';
      default:
        return 'Desconocido';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} minutos';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatMemberSince(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      final remainingDays = difference.inDays % 365;
      final months = (remainingDays / 30).floor();

      if (years == 1 && months == 0) return 'Hace 1 año';
      if (years == 1) return 'Hace 1 año y $months meses';
      if (months == 0) return 'Hace $years años';
      return 'Hace $years años y $months meses';
    }

    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      final days = difference.inDays % 30;

      if (months == 1 && days == 0) return 'Hace 1 mes';
      if (months == 1) return 'Hace 1 mes y $days días';
      if (days == 0) return 'Hace $months meses';
      return 'Hace $months meses y $days días';
    }

    if (difference.inDays > 1) return 'Hace ${difference.inDays} días';
    if (difference.inDays == 1) return 'Hace 1 día';
    return 'Hoy';
  }
}
