import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../network/dio_client.dart';
import '../../../features/auth/domain/entities/user.dart';
import '../../../features/employees/domain/entities/module_permission.dart';

/// Servicio global de permisos del USUARIO ACTUAL (logueado).
/// - Cachea los permisos en memoria para que las pantallas pregunten
///   instantáneamente sin pegarle al server cada vez.
/// - Carga al login y al cambio de tenant; se limpia al logout.
/// - Admin SIEMPRE responde true a hasPermission (no consulta cache).
///
/// Helpers:
///   PermissionsService.to.canView('invoices')
///   PermissionsService.to.canEdit('expenses')
///   PermissionsService.to.canDelete('customers')
class PermissionsService extends GetxService {
  static PermissionsService get to => Get.find<PermissionsService>();

  final DioClient _dio;
  PermissionsService(this._dio);

  /// Permisos en memoria (clave = moduleCode).
  final RxMap<String, ModulePermission> _permissions =
      <String, ModulePermission>{}.obs;

  /// Rol del usuario actual; afecta el cortocircuito de admin.
  final Rxn<UserRole> _currentRole = Rxn<UserRole>();

  final RxBool isLoading = false.obs;
  final RxBool isLoaded = false.obs;

  /// Útil para Obx: rebuilds cuando cambian los permisos.
  RxMap<String, ModulePermission> get rxPermissions => _permissions;

  // ===== API pública =====

  bool canView(String moduleCode) => _check(moduleCode, (p) => p.canView);
  bool canEdit(String moduleCode) => _check(moduleCode, (p) => p.canEdit);
  bool canDelete(String moduleCode) => _check(moduleCode, (p) => p.canDelete);

  bool _check(String moduleCode, bool Function(ModulePermission) accessor) {
    if (_currentRole.value == UserRole.admin) return true;
    final p = _permissions[moduleCode];
    if (p == null) return false; // sin info → denegar (cierra por defecto)
    return accessor(p);
  }

  /// Carga los permisos efectivos del usuario actual desde el backend.
  /// Idempotente: si ya está loading, se ignora.
  Future<void> loadCurrentUserPermissions(UserRole role) async {
    if (isLoading.value) return;
    _currentRole.value = role;

    // Admin: shortcut, no necesita cache (siempre puede todo).
    if (role == UserRole.admin) {
      isLoaded.value = true;
      // ignore: avoid_print
      print('🔓 PermissionsService: usuario ADMIN — acceso total sin cache');
      return;
    }

    isLoading.value = true;
    try {
      // ignore: avoid_print
      print('📥 PermissionsService: cargando permisos del usuario (rol=${role.value})...');
      final res = await _dio.get('/users/me/permissions');
      final data = res.data;
      final list = (data is List)
          ? data
          : (data is Map<String, dynamic> && data['data'] is List
              ? data['data'] as List
              : <dynamic>[]);
      final perms = list
          .whereType<Map<String, dynamic>>()
          .map(ModulePermission.fromJson)
          .toList();
      _permissions
        ..clear()
        ..addEntries(perms.map((p) => MapEntry(p.moduleCode, p)));
      isLoaded.value = true;
      // ignore: avoid_print
      print(
        '✅ PermissionsService: ${perms.length} permisos cargados — '
        '${perms.where((p) => p.canView).length} con canView=true',
      );
    } on DioException catch (e) {
      // ignore: avoid_print
      print(
        '⚠️ PermissionsService: error HTTP cargando permisos: '
        '${e.response?.statusCode} — ${e.response?.data ?? e.message}',
      );
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ PermissionsService: error inesperado: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset al hacer logout o cambio de tenant.
  void clear() {
    _permissions.clear();
    _currentRole.value = null;
    isLoaded.value = false;
    isLoading.value = false;
  }

  // ===== CRUD para administrar permisos de OTROS empleados =====

  /// Lee los permisos efectivos de un empleado (solo admin/manager pueden).
  Future<List<ModulePermission>> getUserPermissions(String userId) async {
    final res = await _dio.get('/users/$userId/permissions');
    final data = res.data;
    final list = (data is List)
        ? data
        : (data is Map<String, dynamic> && data['data'] is List
            ? data['data'] as List
            : <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ModulePermission.fromJson)
        .toList();
  }

  /// Reemplaza el set completo de permisos de un empleado (solo admin).
  Future<List<ModulePermission>> setUserPermissions(
    String userId,
    List<ModulePermission> permissions,
  ) async {
    final res = await _dio.patch(
      '/users/$userId/permissions',
      data: {
        'permissions': permissions.map((p) => p.toJson()).toList(),
      },
    );
    final data = res.data;
    final list = (data is List)
        ? data
        : (data is Map<String, dynamic> && data['data'] is List
            ? data['data'] as List
            : <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ModulePermission.fromJson)
        .toList();
  }
}
