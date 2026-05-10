import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/repositories/employee_repository.dart';

/// Controller del listado de empleados.
/// Online-only. Carga al entrar y permite filtrar/buscar.
class EmployeeListController extends GetxController {
  final EmployeeRepository repository;
  EmployeeListController({required this.repository});

  // ===== State =====
  final isLoading = false.obs;
  final isMutating = false.obs; // mientras se crea/edita/borra
  final errorMessage = ''.obs;
  final RxList<User> employees = <User>[].obs;

  // ===== Filtros =====
  final searchQuery = ''.obs;
  final Rxn<UserRole> filterRole = Rxn<UserRole>();
  final Rxn<UserStatus> filterStatus = Rxn<UserStatus>();

  /// Empleados filtrados localmente. El backend ya filtra, pero aplicamos
  /// también del lado cliente para feedback inmediato al tipear.
  List<User> get filteredEmployees {
    final q = searchQuery.value.toLowerCase().trim();
    return employees.where((e) {
      if (q.isNotEmpty) {
        final inText = e.fullName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            (e.phone?.toLowerCase().contains(q) ?? false);
        if (!inText) return false;
      }
      if (filterRole.value != null && e.role != filterRole.value) return false;
      if (filterStatus.value != null && e.status != filterStatus.value) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Excluye al usuario logueado del listado de "edición de otros" — el
  /// admin se autoedita desde Mi Perfil, no desde aquí.
  String? get currentUserId =>
      Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().currentUser?.id
          : null;

  bool isCurrentUser(User u) => u.id == currentUserId;

  @override
  void onReady() {
    super.onReady();
    refreshList();
  }

  Future<void> refreshList() async {
    isLoading.value = true;
    errorMessage.value = '';
    final result = await repository.list(EmployeeListFilters(
      search: searchQuery.value.isEmpty ? null : searchQuery.value,
      role: filterRole.value,
      status: filterStatus.value,
    ));
    result.fold(
      (failure) => errorMessage.value = failure.message,
      (list) => employees.assignAll(list),
    );
    isLoading.value = false;
  }

  void clearFilters() {
    searchQuery.value = '';
    filterRole.value = null;
    filterStatus.value = null;
    refreshList();
  }

  // ===== Acciones =====

  /// Crea un empleado. Devuelve true si fue exitoso.
  Future<bool> create({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    if (isMutating.value) return false;
    isMutating.value = true;
    final r = await repository.create(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: role,
      phone: phone,
    );
    isMutating.value = false;
    return r.fold(
      (f) {
        _err(f.message);
        return false;
      },
      (_) {
        _ok('Empleado creado', '$firstName $lastName fue agregado al equipo');
        refreshList();
        return true;
      },
    );
  }

  Future<bool> updateEmployee({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
  }) async {
    if (isMutating.value) return false;
    isMutating.value = true;
    final r = await repository.update(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      role: role,
    );
    isMutating.value = false;
    return r.fold(
      (f) {
        _err(f.message);
        return false;
      },
      (_) {
        _ok('Empleado actualizado', 'Cambios guardados');
        refreshList();
        return true;
      },
    );
  }

  Future<bool> toggleStatus(User employee) async {
    if (isMutating.value) return false;
    final newStatus = employee.status == UserStatus.active
        ? UserStatus.suspended
        : UserStatus.active;
    isMutating.value = true;
    final r = await repository.updateStatus(
      id: employee.id,
      status: newStatus,
    );
    isMutating.value = false;
    return r.fold(
      (f) {
        _err(f.message);
        return false;
      },
      (_) {
        _ok(
          newStatus == UserStatus.active ? 'Empleado activado' : 'Empleado suspendido',
          employee.fullName,
        );
        refreshList();
        return true;
      },
    );
  }

  Future<bool> resetPassword(String id, String newPassword) async {
    if (isMutating.value) return false;
    isMutating.value = true;
    final r = await repository.resetPassword(id: id, newPassword: newPassword);
    isMutating.value = false;
    return r.fold(
      (f) {
        _err(f.message);
        return false;
      },
      (_) {
        _ok('Contraseña restablecida',
            'Comunícale al empleado la nueva contraseña');
        return true;
      },
    );
  }

  Future<bool> delete(User employee) async {
    if (isMutating.value) return false;
    isMutating.value = true;
    final r = await repository.delete(employee.id);
    isMutating.value = false;
    return r.fold(
      (f) {
        _err(f.message);
        return false;
      },
      (_) {
        _ok('Empleado eliminado', employee.fullName);
        refreshList();
        return true;
      },
    );
  }

  // ===== Helpers UI =====

  void _ok(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: ElegantLightTheme.successGreen.withValues(alpha: 0.12),
      colorText: ElegantLightTheme.successGreen,
      icon: Icon(Icons.check_circle, color: ElegantLightTheme.successGreen),
      duration: const Duration(seconds: 3),
    );
  }

  void _err(String msg) {
    errorMessage.value = msg;
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: ElegantLightTheme.errorRed.withValues(alpha: 0.12),
      colorText: ElegantLightTheme.errorRed,
      icon: Icon(Icons.error_outline, color: ElegantLightTheme.errorRed),
      duration: const Duration(seconds: 4),
    );
  }
}
