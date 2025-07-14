// lib/app/shared/widgets/drawer_usage_examples.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_scaffold.dart';
import '../controllers/app_drawer_controller.dart';
import '../../config/routes/app_routes.dart';

/// Ejemplos de cómo usar el drawer independiente en diferentes pantallas

// ==================== EJEMPLO 1: USO BÁSICO ====================
class ExampleScreen1 extends StatelessWidget {
  const ExampleScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.products, // Indica la ruta actual
      appBar: AppBarBuilder.build(
        title: 'Mi Pantalla',
        leadingIcon: Icons.inventory,
      ),
      body: const Center(
        child: Text('Contenido de mi pantalla'),
      ),
    );
  }
}

// ==================== EJEMPLO 2: CON APPBAR PERSONALIZADA ====================
class ExampleScreen2 extends StatelessWidget {
  const ExampleScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.invoices,
      appBar: AppBarBuilder.buildWithSearch(
        title: 'Facturas',
        onSearchPressed: () {
          // Lógica de búsqueda
        },
        leadingIcon: Icons.receipt_long,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Mostrar filtros
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Lista de facturas'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==================== EJEMPLO 3: PANTALLA DE FORMULARIO ====================
class ExampleFormScreen extends StatelessWidget {
  const ExampleFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: '/customers/create',
      appBar: AppBarBuilder.buildForm(
        title: 'Nuevo Cliente',
        onSave: () {
          // Guardar cliente
        },
        onCancel: () {
          Get.back();
        },
        isLoading: false,
        leadingIcon: Icons.person_add,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Formulario de cliente aquí'),
            // Campos del formulario...
          ],
        ),
      ),
    );
  }
}

// ==================== EJEMPLO 4: SIN DRAWER ====================
class ExampleNoDrawerScreen extends StatelessWidget {
  const ExampleNoDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      includeDrawer: false, // Sin drawer
      appBar: AppBar(
        title: const Text('Pantalla sin drawer'),
      ),
      body: const Center(
        child: Text('Esta pantalla no tiene drawer'),
      ),
    );
  }
}

// ==================== EJEMPLO 5: USANDO EXTENSIONES ====================
class ExampleWithExtensions extends StatelessWidget {
  const ExampleWithExtensions({super.key});

  @override
  Widget build(BuildContext context) {
    // Usando la extensión para envolver el contenido
    return const Column(
      children: [
        Text('Mi contenido'),
        Text('Más contenido'),
      ],
    ).wrapWithAppBar(
      title: 'Usando Extensiones',
      leadingIcon: Icons.extension,
      currentRoute: AppRoutes.dashboard,
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: null,
        ),
      ],
    );
  }
}

// ==================== EJEMPLO 6: USANDO APPBAR CON GRADIENTE ====================
class ExampleGradientAppBar extends StatelessWidget {
  const ExampleGradientAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.dashboard,
      appBar: AppBarBuilder.buildGradient(
        title: 'Pantalla con Gradiente',
        leadingIcon: Icons.gradient,
        gradientColors: [
          Colors.purple,
          Colors.blue,
        ],
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.blue],
          ),
        ),
        child: const Center(
          child: Text(
            'Pantalla con gradiente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CÓMO USAR EL CONTROLADOR DEL DRAWER ====================
class ExampleDrawerController extends StatelessWidget {
  const ExampleDrawerController({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.products,
      appBar: AppBarBuilder.build(
        title: 'Control del Drawer',
        leadingIcon: Icons.settings,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Acceder al controlador del drawer
              final drawerController = Get.find<AppDrawerController>();
              
              // Actualizar badges
              drawerController.updateBadgeCount('invoices', 5);
              drawerController.incrementBadge('customers');
              
              // Refrescar estadísticas
              drawerController.refreshStatistics();
              
              Get.snackbar(
                'Drawer actualizado',
                'Las estadísticas se han refrescado',
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Control del Drawer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {
                final drawerController = Get.find<AppDrawerController>();
                drawerController.goToDashboard();
              },
              child: const Text('Ir al Dashboard'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                final drawerController = Get.find<AppDrawerController>();
                drawerController.goToCreateInvoice();
              },
              child: const Text('Crear Factura'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {
                final drawerController = Get.find<AppDrawerController>();
                drawerController.updateBadgeCount('products', 10);
                
                Get.snackbar(
                  'Badge actualizado',
                  'Productos ahora tiene 10 notificaciones',
                );
              },
              child: const Text('Actualizar Badge Productos'),
            ),
            
            const SizedBox(height: 16),
            
            GetBuilder<AppDrawerController>(
              builder: (drawerController) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del Drawer:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Items de menú: ${drawerController.menuItems.length}'),
                    Text('Badges activos: ${drawerController.badgeCounts.length}'),
                    Text('Cargando: ${drawerController.isLoading}'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== IMPORTAR EN TUS PANTALLAS ====================
/*
Para usar el drawer independiente en cualquier pantalla:

1. Importa AppScaffold:
   import '../../../../app/shared/widgets/app_scaffold.dart';

2. Importa las rutas:
   import '../../../../app/config/routes/app_routes.dart';

3. Usa AppScaffold en lugar de Scaffold:
   return AppScaffold(
     currentRoute: AppRoutes.tuRuta,
     appBar: AppBarBuilder.build(title: 'Tu Título'),
     body: tuContenido,
   );

4. Para usar el controlador del drawer:
   final drawerController = Get.find<AppDrawerController>();
   drawerController.updateBadgeCount('invoices', 3);

5. El controlador está disponible globalmente, registrado en InitialBinding
*/