// lib/features/inventory/domain/inventory_adjust_permission.dart
//
// Quién puede ajustar el inventario (Ajuste de Stock y Ajustes Masivos).
// Decisión del dueño (2026-11-27): solo el ADMINISTRADOR del negocio (rol
// `admin`: quien registró el negocio y a quien él nombre). Gerente y usuario
// no. El servidor aplica la misma regla (responde 403).
//
// Regla pura: sin Flutter ni GetX, para probarla sola.
import '../../auth/domain/entities/user.dart';
import 'entities/inventory_movement.dart';

/// Lo que ve quien no es administrador al intentar ajustar.
const String kAdjustInventoryAdminOnlyMessage =
    'Solo el administrador del negocio puede ajustar el inventario.';

/// Aviso cuando un ajuste hecho sin internet llega al servidor y este lo
/// rechaza porque quien lo hizo no es administrador.
const String kAdjustRejectedAdminOnlyMessage =
    'El ajuste no se aplicó: solo el administrador puede ajustar el inventario';

/// true solo para el administrador. Si no se conoce el rol (no hay usuario
/// cargado) no se permite.
bool canAdjustInventory(UserRole? role) => role == UserRole.admin;

/// Tipos de movimiento que se le ofrecen a [role] al crear un movimiento:
/// el tipo "ajuste" solo al administrador; los demás, a todos.
List<InventoryMovementType> movementTypesFor(UserRole? role) => [
  for (final type in InventoryMovementType.values)
    if (type != InventoryMovementType.adjustment || canAdjustInventory(role))
      type,
];
