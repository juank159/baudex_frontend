// lib/features/settings/data/repositories/organization_offline_repository.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../models/isar/isar_organization.dart';

/// Implementación offline del repositorio de organización usando ISAR
class OrganizationOfflineRepository implements OrganizationRepository {
  final IsarDatabase _database;

  OrganizationOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async {
    try {
      // Obtener la primera organización (generalmente solo hay una)
      final isarOrg = await _isar.isarOrganizations
          .filter()
          .deletedAtIsNull()
          .findFirst();

      if (isarOrg == null) {
        return Left(CacheFailure('Organización no encontrada en cache local'));
      }

      return Right(isarOrg.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo organización: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Organization>> getOrganizationById(String id) async {
    try {
      final isarOrg = await _isar.isarOrganizations
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarOrg == null) {
        return Left(CacheFailure('Organización no encontrada'));
      }

      return Right(isarOrg.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo organización: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Organization>> updateCurrentOrganization(
    Map<String, dynamic> updates,
  ) async {
    try {
      // Obtener la organización actual
      final isarOrg = await _isar.isarOrganizations
          .filter()
          .deletedAtIsNull()
          .findFirst();

      if (isarOrg == null) {
        return Left(CacheFailure('Organización no encontrada'));
      }

      // Aplicar actualizaciones
      if (updates.containsKey('name')) {
        isarOrg.name = updates['name'] as String;
      }
      if (updates.containsKey('domain')) {
        isarOrg.domain = updates['domain'] as String?;
      }
      if (updates.containsKey('logo')) {
        isarOrg.logo = updates['logo'] as String?;
      }
      if (updates.containsKey('currency')) {
        isarOrg.currency = updates['currency'] as String;
      }
      if (updates.containsKey('locale')) {
        isarOrg.locale = updates['locale'] as String;
      }
      if (updates.containsKey('timezone')) {
        isarOrg.timezone = updates['timezone'] as String;
      }
      if (updates.containsKey('settings')) {
        isarOrg.updateSettings(updates['settings'] as Map<String, dynamic>);
      }
      if (updates.containsKey('defaultProfitMarginPercentage')) {
        isarOrg.defaultProfitMarginPercentage =
            updates['defaultProfitMarginPercentage'] as double?;
      }

      isarOrg.incrementVersion(modifiedBy: 'offline');

      await _isar.writeTxn(() async {
        await _isar.isarOrganizations.put(isarOrg);
      });

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'organization',
          entityId: isarOrg.serverId,
          operationType: SyncOperationType.update,
          data: updates,
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarOrg.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error actualizando organización: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateProfitMargin(double marginPercentage) async {
    try {
      final isarOrg = await _isar.isarOrganizations
          .filter()
          .deletedAtIsNull()
          .findFirst();

      if (isarOrg == null) {
        return Left(CacheFailure('Organización no encontrada'));
      }

      isarOrg.updateProfitMargin(marginPercentage, modifiedBy: 'offline');

      await _isar.writeTxn(() async {
        await _isar.isarOrganizations.put(isarOrg);
      });

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'organization_profit_margin',
          entityId: isarOrg.serverId,
          operationType: SyncOperationType.update,
          data: {'defaultProfitMarginPercentage': marginPercentage},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Error actualizando margen de ganancia: ${e.toString()}'));
    }
  }

  // ==================== CACHE OPERATIONS ====================

  /// Guardar organización en cache (para sincronización desde servidor)
  Future<Either<Failure, void>> cacheOrganization(Organization organization) async {
    try {
      final existingOrg = await _isar.isarOrganizations
          .filter()
          .serverIdEqualTo(organization.id)
          .findFirst();

      if (existingOrg != null) {
        existingOrg.updateFromEntity(organization);
        await _isar.writeTxn(() async {
          await _isar.isarOrganizations.put(existingOrg);
        });
      } else {
        final isarOrg = IsarOrganization.fromEntity(organization);
        await _isar.writeTxn(() async {
          await _isar.isarOrganizations.put(isarOrg);
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error cacheando organización: ${e.toString()}'));
    }
  }

  /// Obtener organizaciones no sincronizadas
  Future<Either<Failure, List<Organization>>> getUnsyncedOrganizations() async {
    try {
      final unsyncedOrgs = await _isar.isarOrganizations
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      final organizations = unsyncedOrgs.map((isar) => isar.toEntity()).toList();
      return Right(organizations);
    } catch (e) {
      return Left(CacheFailure('Error obteniendo organizaciones no sincronizadas: ${e.toString()}'));
    }
  }

  /// Marcar organización como sincronizada
  Future<Either<Failure, void>> markOrganizationAsSynced(String orgId) async {
    try {
      final isarOrg = await _isar.isarOrganizations
          .filter()
          .serverIdEqualTo(orgId)
          .findFirst();

      if (isarOrg != null) {
        isarOrg.markAsSynced();
        await _isar.writeTxn(() async {
          await _isar.isarOrganizations.put(isarOrg);
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marcando organización como sincronizada: ${e.toString()}'));
    }
  }

  /// Limpiar cache de organizaciones
  Future<Either<Failure, void>> clearOrganizationsCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarOrganizations.clear();
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error limpiando cache de organizaciones: ${e.toString()}'));
    }
  }
}
