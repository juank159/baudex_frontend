// lib/core/network/tenant_interceptor.dart
import 'dart:io';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';

class TenantInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  TenantInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('🏢 ==================== TENANT INTERCEPTOR ====================');
    print('🔍 Processing request: ${options.method} ${options.path}');

    // 1. Intentar obtener el tenant desde el storage
    final tenantSlug = await _secureStorage.getTenantSlug();

    // DEBUG: Log detallado del tenant
    print('🔍 TENANT DEBUG: Storage tenant slug: $tenantSlug');

    if (tenantSlug != null && tenantSlug.isNotEmpty) {
      // Tenant del storage tiene PRIORIDAD absoluta
      options.headers['X-Tenant-Slug'] = tenantSlug;
      print('✅ TENANT: Using tenant from storage: $tenantSlug');
    } else {
      print('⚠️ TENANT: No tenant found in storage');

      // 2. Solo usar subdominio como fallback si NO hay tenant en storage
      final uri = Uri.parse(options.baseUrl + options.path);
      final host = uri.host;
      print('🌐 Request host: $host');

      if (!_isIPAddress(host) && host.contains('.') && !host.startsWith('www.') && !_isHostingProviderDomain(host)) {
        final subdomain = host.split('.').first;
        print('🔍 Detected subdomain: $subdomain');
        if (!_isSystemSubdomain(subdomain)) {
          options.headers['X-Tenant-Slug'] = subdomain;
          print('✅ TENANT: Using subdomain as fallback tenant: $subdomain');
        } else {
          print('⚠️ TENANT: Ignoring system subdomain: $subdomain');
        }
      } else {
        print('⚠️ TENANT: No valid subdomain (IP, system domain, or hosting provider)');
      }
    }

    // 3. Agregar header de identificación para debugging
    if (options.headers['X-Tenant-Slug'] != null) {
      options.headers['X-Client-Type'] = 'flutter-app';
      print(
        '✅ TENANT: Final tenant header: ${options.headers['X-Tenant-Slug']}',
      );
    } else {
      print('❌ TENANT: No tenant header will be sent!');
    }

    // Log all headers being sent
    print('📋 Final request headers:');
    options.headers.forEach((key, value) {
      print('   $key: $value');
    });
    print(
      '🏢 ==================== END TENANT INTERCEPTOR ====================',
    );

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log del tenant actual en desarrollo
    if (response.requestOptions.headers.containsKey('X-Tenant-Slug')) {
      final tenant = response.requestOptions.headers['X-Tenant-Slug'];
      print('🏢 API Response for tenant: $tenant');
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Manejar errores relacionados con tenant
    if (err.response?.statusCode == 400) {
      final errorMessage = err.response?.data?['message']?.toString() ?? '';
      if (errorMessage.contains('Organización no encontrada') ||
          errorMessage.contains('Organization not found')) {
        // Error específico de tenant no válido
        print('❌ Tenant Error: $errorMessage');
        // Podrías emitir un evento para cambiar de tenant o mostrar selector
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

  /// Verifica si el host pertenece a un proveedor de hosting conocido
  /// donde el subdominio NO es un tenant sino un nombre de app
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

  /// Verifica si el host es una dirección IP (IPv4 o IPv6)
  bool _isIPAddress(String host) {
    // Verificar IPv4 (formato: 192.168.1.8)
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipv4Regex.hasMatch(host)) {
      return true;
    }

    // Verificar IPv6 (contiene ':')
    if (host.contains(':')) {
      return true;
    }

    // También considerar localhost como IP para este contexto
    if (host == 'localhost' || host == '127.0.0.1') {
      return true;
    }

    return false;
  }
}
