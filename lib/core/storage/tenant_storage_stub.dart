// lib/core/storage/tenant_storage_stub.dart
import 'tenant_storage.dart';

/// Implementación stub de TenantStorage
/// 
/// Simula el almacenamiento de tenant pero también sincroniza con SecureStorage
class TenantStorageStub implements TenantStorage {
  String? _tenantSlug;
  Map<String, dynamic>? _currentOrganization;

  @override
  Future<String?> getTenantSlug() async {
    return _tenantSlug;
  }

  @override
  Future<void> setTenantSlug(String tenantSlug) async {
    _tenantSlug = tenantSlug;
  }

  @override
  Future<void> clearTenantSlug() async {
    _tenantSlug = null;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentOrganization() async {
    return _currentOrganization;
  }

  @override
  Future<void> setCurrentOrganization(Map<String, dynamic> organization) async {
    _currentOrganization = organization;
  }

  @override
  Future<void> clearCurrentOrganization() async {
    _currentOrganization = null;
  }
}