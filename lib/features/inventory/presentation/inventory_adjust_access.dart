// lib/features/inventory/presentation/inventory_adjust_access.dart
//
// Une la regla pura `canAdjustInventory` con el usuario que tiene la sesión.
// Pantallas, accesos y controladores preguntan aquí; nadie repite la regla.
import 'package:get/get.dart';

import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/inventory_adjust_permission.dart';

/// Rol de quien tiene la sesión; null si no hay usuario cargado. Dentro de un
/// `Obx` es reactivo (cambia al cambiar el usuario).
UserRole? currentSessionRole() {
  try {
    if (!Get.isRegistered<AuthController>()) return null;
    return Get.find<AuthController>().currentUser?.role;
  } catch (_) {
    return null;
  }
}

/// ¿Quien tiene la sesión puede ajustar el inventario?
bool sessionCanAdjustInventory() => canAdjustInventory(currentSessionRole());

/// ¿Quien tiene la sesión puede mover stock a mano (movimiento manual,
/// inventario inicial)?
bool sessionCanCreateManualMovement() =>
    canCreateManualMovement(currentSessionRole());
