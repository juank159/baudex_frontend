// Usuario en sesión para pruebas: registra un AuthController falso cuyo
// `currentUser` tiene el rol pedido (null = sin usuario cargado).
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class FakeSessionAuth extends Mock implements AuthController {
  FakeSessionAuth(UserRole? role) : _user = Rxn<User>(_userWith(role));

  final Rxn<User> _user;

  @override
  User? get currentUser => _user.value;

  /// Cambia el usuario en sesión (reactivo, como en la app).
  void setRole(UserRole? role) => _user.value = _userWith(role);

  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});

  static User? _userWith(UserRole? role) => role == null
      ? null
      : User(
          id: 'u-${role.value}',
          firstName: 'Prueba',
          lastName: role.value,
          email: '${role.value}@prueba.test',
          role: role,
          status: UserStatus.active,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          organizationId: 'org-1',
          organizationSlug: 'org-1',
        );
}

/// Pone en sesión un usuario con [role] y lo devuelve.
FakeSessionAuth putSessionRole(UserRole? role) {
  final auth = FakeSessionAuth(role);
  // Reemplaza al usuario anterior (Get.put no pisa uno ya registrado).
  if (Get.isRegistered<AuthController>()) {
    Get.delete<AuthController>(force: true);
  }
  Get.put<AuthController>(auth);
  return auth;
}
