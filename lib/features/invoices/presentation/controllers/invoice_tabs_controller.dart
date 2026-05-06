// lib/features/invoices/presentation/controllers/invoice_tabs_controller.dart
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/search_customers_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_products_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'invoice_form_controller.dart';

class InvoiceTab {
  final String id;
  final String title;
  final InvoiceFormController controller;
  final bool isNewInvoice;
  final String? invoiceId;
  DateTime lastActivity;

  InvoiceTab({
    required this.id,
    required this.title,
    required this.controller,
    this.isNewInvoice = true,
    this.invoiceId,
    DateTime? lastActivity,
  }) : lastActivity = lastActivity ?? DateTime.now();

  InvoiceTab copyWith({String? title, DateTime? lastActivity}) {
    return InvoiceTab(
      id: id,
      title: title ?? this.title,
      controller: controller,
      isNewInvoice: isNewInvoice,
      invoiceId: invoiceId,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

class InvoiceTabsController extends GetxController
    with GetTickerProviderStateMixin {
  static const int maxTabs = 5; // Máximo 5 pestañas abiertas

  // Observables
  final _tabs = <InvoiceTab>[].obs;
  final _currentTabIndex = 0.obs;
  final _isInitialized = false.obs;

  // TabController
  TabController? _tabController;

  // Getters
  List<InvoiceTab> get tabs => _tabs;
  int get currentTabIndex => _currentTabIndex.value;
  bool get isInitialized => _isInitialized.value;
  TabController? get tabController => _tabController;
  bool get hasTabs => _tabs.isNotEmpty;
  bool get canAddMoreTabs => _tabs.length < maxTabs;
  InvoiceTab? get currentTab =>
      _tabs.isNotEmpty && _currentTabIndex.value < _tabs.length
          ? _tabs[_currentTabIndex.value]
          : null;

  @override
  void onInit() {
    super.onInit();
    print('🔖 InvoiceTabsController: Inicializando...');

    // ✅ LIMPIAR CONTROLADOR SIN TAG QUE PUEDA EXISTIR DEL WRAPPER
    _cleanupGlobalController();

    _initializeWithFirstTab();
  }

  /// Limpiar controlador global sin tag que pueda causar conflictos
  void _cleanupGlobalController() {
    try {
      if (Get.isRegistered<InvoiceFormController>()) {
        print('🧹 Limpiando InvoiceFormController global sin tag...');
        Get.delete<InvoiceFormController>();
        print('✅ InvoiceFormController global eliminado');
      }
    } catch (e) {
      print('⚠️ Error al limpiar controlador global: $e');
    }
  }

  @override
  void onClose() {
    print('🔖 InvoiceTabsController: Cerrando...');
    _disposeAllTabs();
    _tabController?.dispose();
    super.onClose();
  }

  // ==================== INICIALIZACIÓN ====================

  void _initializeWithFirstTab() {
    print('🔖 Inicializando con primera pestaña...');
    addNewTab();
    _isInitialized.value = true;
  }

  void _updateTabController() {
    _tabController?.dispose();
    if (_tabs.isNotEmpty) {
      final initialIndex = _currentTabIndex.value.clamp(0, _tabs.length - 1);
      _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: initialIndex,
      );

      _tabController!.addListener(() {
        if (_tabController!.index != _currentTabIndex.value) {
          _currentTabIndex.value = _tabController!.index;
          _updateTabActivity(_tabController!.index);
        }
      });
    }
  }

  // ==================== GESTIÓN DE PESTAÑAS ====================

  String addNewTab({String? invoiceId}) {
    if (!canAddMoreTabs) {
      _showMaxTabsError();
      return '';
    }

    print('🔖 Agregando nueva pestaña...');

    final tabId = DateTime.now().millisecondsSinceEpoch.toString();
    final isEdit = invoiceId != null;

    try {
      // Crear el controlador para esta pestaña usando el mismo ID
      final controller = _createTabController(tabId, invoiceId);

      // Crear la pestaña
      final tab = InvoiceTab(
        id: tabId,
        title: isEdit ? 'Editando...' : 'Fact ${_tabs.length + 1}',
        controller: controller,
        isNewInvoice: !isEdit,
        invoiceId: invoiceId,
      );

      _tabs.add(tab);
      _currentTabIndex.value = _tabs.length - 1;

      // Forzar actualización del observable
      _tabs.refresh();

      _updateTabController();

      print('✅ Pestaña agregada: ${tab.title} (ID: $tabId)');
      print('🔖 DEBUG: Tabs list length: ${_tabs.length}');
      print('🔖 DEBUG: Current tab index: ${_currentTabIndex.value}');
      return tabId;
    } catch (e) {
      print('💥 Error al crear pestaña: $e');
      _showError('Error', 'No se pudo crear la nueva pestaña');
      return '';
    }
  }

  void closeTab(String tabId, {bool forceClose = false}) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;

    final tab = _tabs[tabIndex];
    print('🔖 Cerrando pestaña: ${tab.title}');

    // Verificar si hay cambios sin guardar (verificar si hay items en la factura)
    if (!forceClose && tab.controller.invoiceItems.isNotEmpty) {
      _showCloseConfirmation(tabId);
      return;
    }

    // Liberar recursos del controlador
    _disposeTabController(tab);

    // Remover la pestaña
    _tabs.removeAt(tabIndex);

    // Ajustar índice actual
    if (_currentTabIndex.value >= _tabs.length) {
      _currentTabIndex.value = (_tabs.length - 1).clamp(0, _tabs.length - 1);
    }

    // Si no quedan pestañas, crear una nueva
    if (_tabs.isEmpty) {
      addNewTab();
    } else {
      _updateTabController();
    }

    print('✅ Pestaña cerrada. Pestañas restantes: ${_tabs.length}');
  }

  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentTabIndex.value = index;
      _tabController?.animateTo(index);
      _updateTabActivity(index);
    }
  }

  void switchToTabById(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index != -1) {
      switchToTab(index);
    }
  }

  // ==================== GESTIÓN DE TÍTULOS ====================

  void updateTabTitle(String tabId, String newTitle) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex != -1) {
      _tabs[tabIndex] = _tabs[tabIndex].copyWith(title: newTitle);
      _tabs.refresh();
    }
  }

  void updateCurrentTabTitle(String newTitle) {
    if (currentTab != null) {
      updateTabTitle(currentTab!.id, newTitle);
    }
  }

  // ==================== ACCIONES RÁPIDAS ====================

  void duplicateCurrentTab() {
    if (currentTab == null || !canAddMoreTabs) return;

    final newTabId = addNewTab();
    if (newTabId.isNotEmpty) {
      // Copiar datos de la pestaña actual a la nueva
      final currentController = currentTab!.controller;
      final newTab = _tabs.firstWhere((tab) => tab.id == newTabId);

      // Copiar items de la factura actual
      for (final item in currentController.invoiceItems) {
        // Buscar el producto en los productos disponibles
        final product = currentController.availableProducts.firstWhereOrNull(
          (p) => p.id == item.productId,
        );

        if (product != null) {
          newTab.controller.addOrUpdateProductToInvoice(
            product,
            quantity: item.quantity,
          );
        }
      }

      // Copiar cliente si existe
      if (currentController.selectedCustomer != null) {
        newTab.controller.selectCustomer(currentController.selectedCustomer!);
      }

      updateTabTitle(newTabId, 'Copia - ${currentTab!.title}');
      switchToTabById(newTabId);
    }
  }

  void closeOtherTabs() {
    if (currentTab == null) return;

    final currentTabId = currentTab!.id;
    final tabsToClose = _tabs.where((tab) => tab.id != currentTabId).toList();

    for (final tab in tabsToClose) {
      closeTab(tab.id, forceClose: true);
    }
  }

  void closeAllTabs() {
    final tabsToClose = List<InvoiceTab>.from(_tabs);
    for (final tab in tabsToClose) {
      closeTab(tab.id, forceClose: true);
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  InvoiceFormController _createTabController(String tabId, String? invoiceId) {
    // Obtener las dependencias necesarias del GetX con manejo de errores
    try {
      return Get.put(
        InvoiceFormController(
          createInvoiceUseCase: Get.find(),
          updateInvoiceUseCase: Get.find(),
          getInvoiceByIdUseCase: Get.find(),
          getCustomersUseCase: _tryFindOptional<GetCustomersUseCase>(),
          searchCustomersUseCase: _tryFindOptional<SearchCustomersUseCase>(),
          getCustomerByIdUseCase: _tryFindOptional<GetCustomerByIdUseCase>(),
          getProductsUseCase: _tryFindOptional<GetProductsUseCase>(),
          searchProductsUseCase: _tryFindOptional<SearchProductsUseCase>(),
        ),
        tag: tabId,
      );
    } catch (e) {
      print('💥 Error específico al crear controlador de pestaña: $e');
      rethrow;
    }
  }

  T? _tryFindOptional<T>() {
    try {
      return Get.find<T>();
    } catch (e) {
      print('⚠️ Dependencia opcional no encontrada: ${T.toString()}');
      return null;
    }
  }

  void _disposeTabController(InvoiceTab tab) {
    try {
      Get.delete<InvoiceFormController>(tag: tab.id);
    } catch (e) {
      print('⚠️ Error al liberar controlador de pestaña: $e');
    }
  }

  void _disposeAllTabs() {
    for (final tab in _tabs) {
      _disposeTabController(tab);
    }
    _tabs.clear();
  }

  void _updateTabActivity(int index) {
    if (index >= 0 && index < _tabs.length) {
      _tabs[index] = _tabs[index].copyWith(lastActivity: DateTime.now());
    }
  }

  // ==================== DIÁLOGOS Y MENSAJES ====================

  void _showCloseConfirmation(String tabId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Pestaña'),
        content: const Text(
          'Esta pestaña tiene cambios sin guardar. ¿Estás seguro de que quieres cerrarla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              closeTab(tabId, forceClose: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sin guardar'),
          ),
        ],
      ),
    );
  }

  void _showMaxTabsError() {
    // Programar para el siguiente frame para evitar errores durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        'Límite alcanzado',
        'No puedes tener más de $maxTabs pestañas abiertas al mismo tiempo',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
    });
  }

  void _showError(String title, String message) {
    // Programar para el siguiente frame para evitar errores durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    });
  }

  // ==================== INFORMACIÓN DEBUG ====================

  void printTabsInfo() {
    print('🔖 === ESTADO DE PESTAÑAS ===');
    print('🔖 Total pestañas: ${_tabs.length}');
    print('🔖 Pestaña actual: ${_currentTabIndex.value}');
    for (int i = 0; i < _tabs.length; i++) {
      final tab = _tabs[i];
      print(
        '🔖 [$i] ${tab.title} (${tab.id}) - Items: ${tab.controller.invoiceItems.length}',
      );
    }
    print('🔖 ========================');
  }
}
