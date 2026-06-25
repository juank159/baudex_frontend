// lib/features/invoices/presentation/screens/invoice_form_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Bindings
import '../bindings/invoice_binding.dart';
import '../../../customers/presentation/bindings/customer_binding.dart';
import '../../../products/presentation/bindings/product_binding.dart';

// Use cases
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/update_invoice_usecase.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../customers/domain/usecases/search_customers_usecase.dart';
import '../../../customers/domain/usecases/get_customer_by_id_usecase.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/domain/usecases/search_products_usecase.dart';

// Controllers
import '../controllers/invoice_form_controller.dart';

// Screen
import 'invoice_form_screen.dart';

class InvoiceFormScreenWrapper extends StatefulWidget {
  const InvoiceFormScreenWrapper({super.key});

  @override
  State<InvoiceFormScreenWrapper> createState() =>
      _InvoiceFormScreenWrapperState();
}

class _InvoiceFormScreenWrapperState extends State<InvoiceFormScreenWrapper> {
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWithRealDependencies();
  }

  Future<void> _initializeWithRealDependencies() async {
    try {

      // Verificar si ya existe el controlador
      if (Get.isRegistered<InvoiceFormController>()) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        return;
      }

      // 1. Inicializar bindings en orden correcto para evitar problemas de dependencias
      await _initializeBindings();

      // 2. Esperar un frame para asegurar que las dependencias estén listas
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Crear controlador con dependencias reales
      await _createControllerWithRealDependencies();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeBindings() async {

    // Inicializar CustomerBinding si no está inicializado
    if (!Get.isRegistered<GetCustomersUseCase>()) {
      CustomerBinding().dependencies();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Inicializar ProductBinding si no está inicializado
    if (!Get.isRegistered<GetProductsUseCase>()) {
      ProductBinding().dependencies();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Inicializar InvoiceBinding si no está inicializado
    if (!Get.isRegistered<CreateInvoiceUseCase>()) {
      InvoiceBinding().dependencies();
      await Future.delayed(const Duration(milliseconds: 50));
    }

  }

  Future<void> _createControllerWithRealDependencies() async {

    // Obtener use cases de forma segura
    final getCustomersUseCase = _getUseCaseSafely<GetCustomersUseCase>();
    final searchCustomersUseCase = _getUseCaseSafely<SearchCustomersUseCase>();
    final getCustomerByIdUseCase = _getUseCaseSafely<GetCustomerByIdUseCase>();
    final getProductsUseCase = _getUseCaseSafely<GetProductsUseCase>();
    final searchProductsUseCase = _getUseCaseSafely<SearchProductsUseCase>();

    // Use cases requeridos (estos deben existir)
    final createInvoiceUseCase = Get.find<CreateInvoiceUseCase>();
    final updateInvoiceUseCase = Get.find<UpdateInvoiceUseCase>();
    final getInvoiceByIdUseCase = Get.find<GetInvoiceByIdUseCase>();

    // Crear controlador con todas las dependencias disponibles
    Get.put(
      InvoiceFormController(
        // Dependencias requeridas
        createInvoiceUseCase: createInvoiceUseCase,
        updateInvoiceUseCase: updateInvoiceUseCase,
        getInvoiceByIdUseCase: getInvoiceByIdUseCase,
        // Dependencias opcionales
        getCustomersUseCase: getCustomersUseCase,
        searchCustomersUseCase: searchCustomersUseCase,
        getCustomerByIdUseCase: getCustomerByIdUseCase,
        getProductsUseCase: getProductsUseCase,
        searchProductsUseCase: searchProductsUseCase,
      ),
    );

  }

  T? _getUseCaseSafely<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Punto de Venta'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando punto de venta...'),
              SizedBox(height: 8),
              Text(
                'Conectando con backend...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al conectar con el backend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Volver'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeWithRealDependencies();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitialized) {
      return const InvoiceFormScreen();
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    // Limpiar el controlador cuando se destruya el wrapper
    if (Get.isRegistered<InvoiceFormController>()) {
      Get.delete<InvoiceFormController>();
    }
    super.dispose();
  }
}
