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

/// Lo que ve quien no es administrador al intentar registrar a mano una
/// entrada o salida de stock (movimiento manual o inventario inicial).
const String kManualMovementAdminOnlyMessage =
    'Solo el administrador del negocio puede registrar entradas o salidas '
    'de inventario a mano.';

/// ¿Puede [role] mover stock A MANO (crear, confirmar o cancelar un
/// movimiento manual, cargar inventario inicial)? Decisión del dueño
/// (2026-11-27): solo el administrador, igual que los ajustes. Facturas,
/// compras y traslados mueven stock por su propio camino y no pasan por aquí.
bool canCreateManualMovement(UserRole? role) => canAdjustInventory(role);

/// Tipos de movimiento que se le ofrecen a [role] al crear un movimiento
/// manual: todos al administrador; ninguno a los demás (no pueden crearlo).
List<InventoryMovementType> movementTypesFor(UserRole? role) => [
  if (canCreateManualMovement(role)) ...InventoryMovementType.values,
];
