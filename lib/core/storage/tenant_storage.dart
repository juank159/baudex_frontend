// lib/core/storage/tenant_storage.dart
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';

abstract class TenantStorage {
  Future<String?> getTenantSlug();
  Future<void> setTenantSlug(String tenantSlug);
  Future<void> clearTenantSlug();
  Future<Map<String, dynamic>?> getCurrentOrganization();
  Future<void> setCurrentOrganization(Map<String, dynamic> organization);
  Future<void> clearCurrentOrganization();
}

class TenantStorageImpl implements TenantStorage {
  final SecureStorageService _secureStorage;

  TenantStorageImpl(this._secureStorage);

  @override
  Future<String?> getTenantSlug() async {
    return await _secureStorage.getTenantSlug();
  }

  @override
  Future<void> setTenantSlug(String tenantSlug) async {
    await _secureStorage.saveTenantSlug(tenantSlug);
  }

  @override
  Future<void> clearTenantSlug() async {
    await _secureStorage.deleteTenantSlug();
  }

  @override
  Future<Map<String, dynamic>?> getCurrentOrganization() async {
    return await _secureStorage.getCurrentOrganization();
  }

  @override
  Future<void> setCurrentOrganization(Map<String, dynamic> organization) async {
    await _secureStorage.saveCurrentOrganization(organization);
  }

  @override
  Future<void> clearCurrentOrganization() async {
    await _secureStorage.deleteCurrentOrganization();
  }
}
