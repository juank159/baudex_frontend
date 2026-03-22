// lib/core/network/tenant_interceptor.dart
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';

class TenantInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  // Cache en memoria para evitar lecturas de storage en cada request
  static String? _cachedSlug;
  static bool _cacheInitialized = false;

  TenantInterceptor(this._secureStorage);

  /// Actualizar cache cuando el tenant cambia (login, logout)
  static void updateCachedSlug(String? slug) {
    _cachedSlug = slug;
    _cacheInitialized = slug != null;
  }

  /// Obtener el slug cacheado (para verificar disponibilidad antes de API calls)
  static String? get cachedSlug => _cachedSlug;

  /// Forzar re-lectura del storage en el próximo request
  static void invalidateCache() {
    _cacheInitialized = false;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Leer de storage solo una vez, luego usar cache
    if (!_cacheInitialized) {
      try {
        _cachedSlug = await _secureStorage.getTenantSlug();
      } catch (_) {
        // Si falla storage, continuar sin tenant
      }
      _cacheInitialized = true;
    }

    if (_cachedSlug != null && _cachedSlug!.isNotEmpty) {
      options.headers['X-Tenant-Slug'] = _cachedSlug;
      options.headers['X-Client-Type'] = 'flutter-app';
    } else {
      // Fallback: intentar subdominio solo para dominios custom
      final uri = Uri.parse(options.baseUrl + options.path);
      final host = uri.host;

      if (!_isIPAddress(host) &&
          host.contains('.') &&
          !host.startsWith('www.') &&
          !_isHostingProviderDomain(host)) {
        final subdomain = host.split('.').first;
        if (!_isSystemSubdomain(subdomain)) {
          options.headers['X-Tenant-Slug'] = subdomain;
          options.headers['X-Client-Type'] = 'flutter-app';
        }
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 400) {
      final errorMessage = err.response?.data?['message']?.toString() ?? '';
      if (errorMessage.contains('Organización no encontrada') ||
          errorMessage.contains('Organization not found')) {
        // Invalidar cache para forzar re-lectura en próximo request
        _cacheInitialized = false;
        print('❌ Tenant Error: $errorMessage');
      }
    }

    super.onError(err, handler);
  }

  bool _isSystemSubdomain(String subdomain) {
    const systemSubdomains = [
      'www',
      'api',
      'admin',
      'app',
      'localhost',
      'staging',
      'dev',
      'test',
      'baudex-backend',
    ];
    return systemSubdomains.contains(subdomain.toLowerCase());
  }

  bool _isHostingProviderDomain(String host) {
    const hostingDomains = [
      'onrender.com',
      'herokuapp.com',
      'railway.app',
      'fly.dev',
      'vercel.app',
      'netlify.app',
      'azurewebsites.net',
      'cloudfront.net',
    ];
    final hostLower = host.toLowerCase();
    return hostingDomains.any((domain) => hostLower.endsWith(domain));
  }

  bool _isIPAddress(String host) {
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipv4Regex.hasMatch(host)) return true;
    if (host.contains(':')) return true;
    if (host == 'localhost' || host == '127.0.0.1') return true;
    return false;
  }
}
