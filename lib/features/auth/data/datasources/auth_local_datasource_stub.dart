// lib/features/auth/data/datasources/auth_local_datasource_stub.dart
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';
import 'auth_local_datasource.dart';

/// Implementación stub del datasource local de autenticación
/// 
/// Esta es una implementación temporal que simula el almacenamiento
/// mientras se resuelven los problemas de dependencias
class AuthLocalDataSourceStub implements AuthLocalDataSource {
  // Simular almacenamiento en memoria
  String? _token;
  String? _refreshToken;
  UserModel? _user;
  bool _isAuthenticated = false;

  @override
  Future<void> saveAuthData(AuthResponseModel authResponse) async {
    try {
      _token = authResponse.token;
      _refreshToken = authResponse.refreshToken;
      _user = authResponse.user;
      _isAuthenticated = true;
      print('🔐 AuthLocalDataSourceStub: Datos de auth guardados para ${authResponse.user.email}');
    } catch (e) {
      throw CacheException('Stub - Error al guardar datos de autenticación: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return _token;
    } catch (e) {
      throw CacheException('Stub - Error al obtener token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return _refreshToken;
    } catch (e) {
      throw CacheException('Stub - Error al obtener refresh token: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      return _user;
    } catch (e) {
      throw CacheException('Stub - Error al obtener datos del usuario: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return _isAuthenticated && _token != null && _user != null;
    } catch (e) {
      // En caso de error, asumir que no está autenticado
      return false;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      _token = null;
      _refreshToken = null;
      _user = null;
      _isAuthenticated = false;
      print('🔐 AuthLocalDataSourceStub: Datos de auth limpiados');
    } catch (e) {
      throw CacheException('Stub - Error al limpiar datos de autenticación: $e');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      _token = token;
      _isAuthenticated = true;
    } catch (e) {
      throw CacheException('Stub - Error al guardar token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      _user = user;
    } catch (e) {
      throw CacheException('Stub - Error al guardar datos del usuario: $e');
    }
  }

  /// Métodos adicionales útiles

  /// Verificar si existe token válido
  Future<bool> hasValidToken() async {
    try {
      return _token != null && _token!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si existen datos del usuario
  Future<bool> hasUserData() async {
    try {
      return _user != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener datos completos de autenticación
  Future<AuthLocalData?> getAuthData() async {
    try {
      if (_token != null && _user != null) {
        return AuthLocalData(
          token: _token!,
          refreshToken: _refreshToken,
          user: _user!,
        );
      }
      return null;
    } catch (e) {
      throw CacheException('Stub - Error al obtener datos de autenticación: $e');
    }
  }

  /// Actualizar solo el token (útil para refresh)
  Future<void> updateToken(String newToken) async {
    try {
      _token = newToken;
    } catch (e) {
      throw CacheException('Stub - Error al actualizar token: $e');
    }
  }

  /// Actualizar solo los datos del usuario
  Future<void> updateUser(UserModel user) async {
    try {
      _user = user;
    } catch (e) {
      throw CacheException('Stub - Error al actualizar datos del usuario: $e');
    }
  }

  /// Simular login exitoso con datos de prueba
  Future<void> simulateLogin(String email, String password) async {
    // Crear usuario de prueba
    final testUser = UserModel(
      id: '1',
      firstName: 'Usuario',
      lastName: 'Demo',
      email: email,
      role: UserRole.admin,
      status: UserStatus.active,
      organizationId: 'org-1',
      organizationName: 'Organización Demo',
      organizationSlug: 'demo-org',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Crear respuesta de auth de prueba
    final authResponse = AuthResponseModel(
      token: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      user: testUser,
      refreshToken: 'demo-refresh-token',
    );

    // Guardar datos
    await saveAuthData(authResponse);
  }
}