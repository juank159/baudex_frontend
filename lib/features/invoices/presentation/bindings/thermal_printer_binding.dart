// lib/features/invoices/presentation/bindings/thermal_printer_binding.dart

import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';
import 'package:get/get.dart';

class ThermalPrinterBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar como singleton para mantener configuración
    Get.lazyPut<ThermalPrinterController>(
      () => ThermalPrinterController(),
      fenix: true, // Permite recrear si se elimina
    );
  }

  /// Método estático para registro manual
  static void registerThermalPrinter() {
    if (!Get.isRegistered<ThermalPrinterController>()) {
      Get.put(ThermalPrinterController(), permanent: true);
    }
  }

  /// Método para limpiar dependencias
  static void dispose() {
    if (Get.isRegistered<ThermalPrinterController>()) {
      Get.delete<ThermalPrinterController>();
    }
  }
}
