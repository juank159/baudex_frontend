// lib/app/shared/screens/simple_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/simple_auth_controller.dart';

/// Pantalla de dashboard stub simple
/// 
/// Esta es una implementación temporal que funciona sin dependencias complejas
/// mientras se resuelven los problemas de ISAR
class SimpleDashboardScreen extends GetView<SimpleAuthController> {
  const SimpleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baudex Desktop - Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.desktop_windows,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido a Baudex Desktop',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sistema de gestión empresarial',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Cards
            const Text(
              'Estado del Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatusCard(
                    'Base de Datos',
                    'Stub Implementation',
                    Icons.storage,
                    Colors.orange,
                    'Base de datos en modo stub',
                  ),
                  _buildStatusCard(
                    'Autenticación',
                    'Activa (Demo)',
                    Icons.security,
                    Colors.green,
                    'Sistema de auth funcionando',
                  ),
                  _buildStatusCard(
                    'Sincronización',
                    'Deshabilitada',
                    Icons.sync_disabled,
                    Colors.grey,
                    'Sync no disponible en modo stub',
                  ),
                  _buildStatusCard(
                    'Funcionalidades',
                    'Limitadas',
                    Icons.warning,
                    Colors.amber,
                    'Solo funciones básicas disponibles',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones Disponibles',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed('/products'),
                          icon: const Icon(Icons.inventory),
                          label: const Text('Productos'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed('/customers'),
                          icon: const Icon(Icons.people),
                          label: const Text('Clientes'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed('/invoices'),
                          icon: const Icon(Icons.receipt),
                          label: const Text('Facturas'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed('/settings'),
                          icon: const Icon(Icons.settings),
                          label: const Text('Configuración'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    String status,
    IconData icon,
    Color color,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
              Get.offAllNamed('/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}