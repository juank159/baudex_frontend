// lib/features/auth/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/auth_controller.dart';
import '../widgets/change_password_dialog.dart';

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isProfileLoading) {
          return const LoadingWidget(message: 'Cargando perfil...');
        }

        if (controller.currentUser == null) {
          return _buildErrorState(context);
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
      title: const Text('Mi Perfil'),
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 8),
                      Text('Cambiar Contraseña'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        children: [
          _buildProfileHeader(context),
          SizedBox(height: context.verticalSpacing),
          _buildProfileInfo(context),
          SizedBox(height: context.verticalSpacing),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 600,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),
            _buildProfileHeader(context),
            SizedBox(height: context.verticalSpacing * 2),
            CustomCard(child: _buildProfileInfo(context)),
            SizedBox(height: context.verticalSpacing),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 800,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo con header
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(height: context.verticalSpacing * 2),
                  CustomCard(child: _buildProfileHeader(context)),
                  SizedBox(height: context.verticalSpacing),
                  _buildActionButtons(context),
                ],
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            // Panel derecho con información
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(height: context.verticalSpacing * 2),
                  CustomCard(child: _buildProfileInfo(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final user = controller.currentUser!;

    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: context.isMobile ? 50 : 60,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage:
              user.avatar != null ? NetworkImage(user.avatar!) : null,
          child:
              user.avatar == null
                  ? Icon(
                    Icons.person,
                    size: context.isMobile ? 50 : 60,
                    color: Theme.of(context).primaryColor,
                  )
                  : null,
        ),

        SizedBox(height: context.verticalSpacing),

        // Nombre completo
        Text(
          user.fullName,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.verticalSpacing / 2),

        // Email
        Text(
          user.email,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.verticalSpacing / 2),

        // Badge de rol
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getRoleColor(user.role), width: 1),
          ),
          child: Text(
            _getRoleText(user.role),
            style: TextStyle(
              color: _getRoleColor(user.role),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        
        SizedBox(height: context.verticalSpacing / 2),
        
        // Badge de organización
        if (user.organizationName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business,
                  size: 12,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  user.organizationName!,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    final user = controller.currentUser!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: context.verticalSpacing),

        _buildInfoItem(context, 'Nombre', user.firstName, Icons.person_outline),

        SizedBox(height: context.verticalSpacing),

        _buildInfoItem(
          context,
          'Apellido',
          user.lastName,
          Icons.person_outline,
        ),

        SizedBox(height: context.verticalSpacing),

        _buildInfoItem(
          context,
          'Correo Electrónico',
          user.email,
          Icons.email_outlined,
        ),

        if (user.phone != null) ...[
          SizedBox(height: context.verticalSpacing),
          _buildInfoItem(
            context,
            'Teléfono',
            user.phone!,
            Icons.phone_outlined,
          ),
        ],

        SizedBox(height: context.verticalSpacing),

        _buildInfoItem(
          context,
          'Estado',
          _getStatusText(user.status),
          Icons.verified_user_outlined,
          statusColor: _getStatusColor(user.status),
        ),

        if (user.lastLoginAt != null) ...[
          SizedBox(height: context.verticalSpacing),
          _buildInfoItem(
            context,
            'Último Acceso',
            _formatDateTime(user.lastLoginAt!),
            Icons.access_time,
          ),
        ],

        SizedBox(height: context.verticalSpacing),

        _buildInfoItem(
          context,
          'Miembro Desde',
          _formatMemberSince(user.createdAt),
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor ?? Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: statusColor ?? Colors.black87,
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'Cambiar Contraseña',
          icon: Icons.lock_outline,
          type: ButtonType.outline,
          onPressed: () => _showChangePasswordDialog(context),
        ),

        SizedBox(height: context.verticalSpacing / 2),

        CustomButton(
          text: 'Cerrar Sesión',
          icon: Icons.logout,
          type: ButtonType.secondary,
          textColor: Colors.red,
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            'Error al cargar el perfil',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: context.verticalSpacing),
          CustomButton(text: 'Reintentar', onPressed: controller.getProfile),
        ],
      ),
    );
  }

  // ==================== MÉTODOS DE ACCIÓN ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'change_password':
        _showChangePasswordDialog(context);
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  controller.logout();
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // ==================== MÉTODOS HELPER ====================

  Color _getRoleColor(dynamic role) {
    final roleStr = role.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.orange;
      case 'user':
      default:
        return Colors.blue;
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

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
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
    
    // Mostrar años y meses si es más de un año
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      final remainingDays = difference.inDays % 365;
      final months = (remainingDays / 30).floor();
      
      if (years == 1 && months == 0) {
        return 'Hace 1 año';
      } else if (years == 1) {
        return 'Hace 1 año y $months meses';
      } else if (months == 0) {
        return 'Hace $years años';
      } else {
        return 'Hace $years años y $months meses';
      }
    }
    
    // Mostrar meses y días si es más de un mes
    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      final days = difference.inDays % 30;
      
      if (months == 1 && days == 0) {
        return 'Hace 1 mes';
      } else if (months == 1) {
        return 'Hace 1 mes y $days días';
      } else if (days == 0) {
        return 'Hace $months meses';
      } else {
        return 'Hace $months meses y $days días';
      }
    }
    
    // Mostrar solo días si es menos de un mes
    if (difference.inDays > 1) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays == 1) {
      return 'Hace 1 día';
    } else {
      return 'Hoy';
    }
  }
}
