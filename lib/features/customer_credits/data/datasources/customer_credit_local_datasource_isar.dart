// lib/features/customer_credits/data/datasources/customer_credit_local_datasource_isar.dart

import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/customer_credit_model.dart';
import '../models/isar/isar_customer_credit.dart';
import '../../domain/entities/customer_credit.dart';
import 'customer_credit_local_datasource.dart';

/// Implementación ISAR del datasource local de créditos de clientes
/// Almacenamiento persistente offline-first usando ISAR
class CustomerCreditLocalDataSourceIsar implements CustomerCreditLocalDataSource {
  final IsarDatabase _database;

  CustomerCreditLocalDataSourceIsar(this._database);

  @override
  Future<void> cacheCredits(List<CustomerCreditModel> credits) async {
    try {
      final isar = _database.database;

      await isar.writeTxn(() async {
        // Procesar créditos uno por uno
        for (final credit in credits) {
          // Buscar crédito existente por serverId
          IsarCustomerCredit? existingCredit = await isar.isarCustomerCredits
              .filter()
              .serverIdEqualTo(credit.id)
              .findFirst();

          IsarCustomerCredit isarCredit;

          if (existingCredit != null) {
            // Actualizar crédito existente
            isarCredit = existingCredit
              ..originalAmount = credit.originalAmount
              ..paidAmount = credit.paidAmount
              ..balanceDue = credit.balanceDue
              ..status = _mapToIsarStatus(credit.status)
              ..dueDate = credit.dueDate
              ..description = credit.description
              ..notes = credit.notes
              ..customerId = credit.customerId
              ..customerName = credit.customerName
              ..invoiceId = credit.invoiceId
              ..invoiceNumber = credit.invoiceNumber
              ..organizationId = credit.organizationId
              ..createdById = credit.createdById
              ..createdByName = credit.createdByName
              ..createdAt = credit.createdAt
              ..updatedAt = credit.updatedAt
              ..deletedAt = credit.deletedAt
              ..isSynced = true
              ..lastSyncAt = DateTime.now()
              ..metadataJson = _serializeCreditData(credit);
          } else {
            // Crear nuevo crédito
            isarCredit = IsarCustomerCredit(
              serverId: credit.id,
              originalAmount: credit.originalAmount,
              paidAmount: credit.paidAmount,
              balanceDue: credit.balanceDue,
              status: _mapToIsarStatus(credit.status),
              dueDate: credit.dueDate,
              description: credit.description,
              notes: credit.notes,
              customerId: credit.customerId,
              customerName: credit.customerName,
              invoiceId: credit.invoiceId,
              invoiceNumber: credit.invoiceNumber,
              organizationId: credit.organizationId,
              createdById: credit.createdById,
              createdByName: credit.createdByName,
              createdAt: credit.createdAt,
              updatedAt: credit.updatedAt,
              deletedAt: credit.deletedAt,
              isSynced: true,
              lastSyncAt: DateTime.now(),
              metadataJson: _serializeCreditData(credit),
            );
          }

          await isar.isarCustomerCredits.put(isarCredit);
        }
      });

      print('📦 ISAR: ${credits.length} créditos cacheados exitosamente');
    } catch (e) {
      print('❌ Error al cachear créditos en ISAR: $e');
      throw CacheException('Error al cachear créditos en ISAR: $e');
    }
  }

  @override
  Future<void> cacheCredit(CustomerCreditModel credit) async {
    try {
      final isar = _database.database;

      await isar.writeTxn(() async {
        // Buscar crédito existente
        IsarCustomerCredit? existingCredit = await isar.isarCustomerCredits
            .filter()
            .serverIdEqualTo(credit.id)
            .findFirst();

        IsarCustomerCredit isarCredit;

        if (existingCredit != null) {
          // Actualizar existente
          isarCredit = existingCredit
            ..serverId = credit.id
            ..originalAmount = credit.originalAmount
            ..paidAmount = credit.paidAmount
            ..balanceDue = credit.balanceDue
            ..status = _mapToIsarStatus(credit.status)
            ..dueDate = credit.dueDate
            ..description = credit.description
            ..notes = credit.notes
            ..customerId = credit.customerId
            ..customerName = credit.customerName
            ..invoiceId = credit.invoiceId
            ..invoiceNumber = credit.invoiceNumber
            ..organizationId = credit.organizationId
            ..createdById = credit.createdById
            ..createdByName = credit.createdByName
            ..createdAt = credit.createdAt
            ..updatedAt = credit.updatedAt
            ..deletedAt = credit.deletedAt
            ..isSynced = true
            ..lastSyncAt = DateTime.now()
            ..metadataJson = _serializeCreditData(credit);
        } else {
          // Crear nuevo
          isarCredit = IsarCustomerCredit(
            serverId: credit.id,
            originalAmount: credit.originalAmount,
            paidAmount: credit.paidAmount,
            balanceDue: credit.balanceDue,
            status: _mapToIsarStatus(credit.status),
            dueDate: credit.dueDate,
            description: credit.description,
            notes: credit.notes,
            customerId: credit.customerId,
            customerName: credit.customerName,
            invoiceId: credit.invoiceId,
            invoiceNumber: credit.invoiceNumber,
            organizationId: credit.organizationId,
            createdById: credit.createdById,
            createdByName: credit.createdByName,
            createdAt: credit.createdAt,
            updatedAt: credit.updatedAt,
            deletedAt: credit.deletedAt,
            isSynced: true,
            lastSyncAt: DateTime.now(),
            metadataJson: _serializeCreditData(credit),
          );
        }

        await isar.isarCustomerCredits.put(isarCredit);
      });

      print('📦 ISAR: Crédito ${credit.id} cacheado exitosamente');
    } catch (e) {
      print('❌ Error al cachear crédito en ISAR: $e');
      throw CacheException('Error al cachear crédito en ISAR: $e');
    }
  }

  @override
  Future<List<CustomerCreditModel>> getCachedCredits() async {
    try {
      final isar = _database.database;

      final isarCredits = await isar.isarCustomerCredits
          .filter()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .findAll();

      if (isarCredits.isEmpty) {
        print('📦 ISAR: No hay créditos en cache local');
        throw const CacheException('No hay créditos en cache local');
      }

      final credits =
          isarCredits.map((isarCredit) => _convertToModel(isarCredit)).toList();

      print('📦 ISAR: ${credits.length} créditos obtenidos del cache local');
      return credits;
    } catch (e) {
      if (e is CacheException) rethrow;
      print('❌ Error al obtener créditos de ISAR: $e');
      throw CacheException('Error al obtener créditos de ISAR: $e');
    }
  }

  @override
  Future<CustomerCreditModel?> getCachedCredit(String id) async {
    try {
      final isar = _database.database;

      final isarCredit = await isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCredit == null) {
        print('📦 ISAR: Crédito con ID $id no encontrado en cache');
        return null;
      }

      return _convertToModel(isarCredit);
    } catch (e) {
      print('❌ Error al obtener crédito de ISAR: $e');
      throw CacheException('Error al obtener crédito de ISAR: $e');
    }
  }

  @override
  Future<void> removeCachedCredit(String id) async {
    try {
      final isar = _database.database;

      await isar.writeTxn(() async {
        // Marcar como eliminado en lugar de borrar físicamente
        final credit = await isar.isarCustomerCredits
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (credit != null) {
          credit.deletedAt = DateTime.now();
          await isar.isarCustomerCredits.put(credit);
        }
      });

      print('🗑️ ISAR: Crédito $id marcado como eliminado');
    } catch (e) {
      print('❌ Error al remover crédito de ISAR: $e');
      throw CacheException('Error al remover crédito de ISAR: $e');
    }
  }

  @override
  Future<void> clearCreditCache() async {
    try {
      final isar = _database.database;

      await isar.writeTxn(() async {
        await isar.isarCustomerCredits.clear();
      });

      print('🧹 ISAR: Cache de créditos limpiado');
    } catch (e) {
      print('❌ Error al limpiar cache de ISAR: $e');
      throw CacheException('Error al limpiar cache de ISAR: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final isar = _database.database;
      final count = await isar.isarCustomerCredits
          .filter()
          .deletedAtIsNull()
          .count();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // ==================== MÉTODOS ADICIONALES PARA SINCRONIZACIÓN ====================

  /// Guardar crédito creado offline para posterior sincronización
  Future<void> cacheCreditForSync(CustomerCredit credit) async {
    try {
      final isar = _database.database;

      final isarCredit = IsarCustomerCredit(
        serverId: credit.id, // ID temporal offline
        originalAmount: credit.originalAmount,
        paidAmount: credit.paidAmount,
        balanceDue: credit.balanceDue,
        status: _mapToIsarStatus(credit.status),
        dueDate: credit.dueDate,
        description: credit.description,
        notes: credit.notes,
        customerId: credit.customerId,
        customerName: credit.customerName,
        invoiceId: credit.invoiceId,
        invoiceNumber: credit.invoiceNumber,
        organizationId: credit.organizationId,
        createdById: credit.createdById,
        createdByName: credit.createdByName,
        createdAt: credit.createdAt,
        updatedAt: credit.updatedAt,
        deletedAt: credit.deletedAt,
        isSynced: false, // Marcar como no sincronizado
      );

      // Serializar payments si existen
      isarCredit.metadataJson = jsonEncode({
        'payments': credit.payments?.map((p) => {
          'id': p.id,
          'amount': p.amount,
          'paymentMethod': p.paymentMethod,
          'paymentDate': p.paymentDate.toIso8601String(),
          'reference': p.reference,
          'notes': p.notes,
          'creditId': p.creditId,
          'bankAccountId': p.bankAccountId,
          'organizationId': p.organizationId,
          'createdById': p.createdById,
          'createdAt': p.createdAt.toIso8601String(),
          'updatedAt': p.updatedAt.toIso8601String(),
        }).toList() ?? [],
      });

      await isar.writeTxn(() async {
        await isar.isarCustomerCredits.put(isarCredit);
      });

      print('✅ ISAR: Crédito guardado para sincronizar: ${credit.id}');
    } catch (e) {
      throw CacheException('Error guardando crédito para sync en ISAR: $e');
    }
  }

  /// Obtener créditos que faltan por sincronizar
  Future<List<CustomerCredit>> getUnsyncedCredits() async {
    try {
      final isar = _database.database;

      final unsyncedIsarCredits = await isar.isarCustomerCredits
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final unsyncedCredits = <CustomerCredit>[];

      for (final isarCredit in unsyncedIsarCredits) {
        try {
          final model = _convertToModel(isarCredit);
          final entity = _modelToEntity(model);
          unsyncedCredits.add(entity);
        } catch (e) {
          print('⚠️ Error convirtiendo crédito no sincronizado ${isarCredit.serverId}: $e');
        }
      }

      print('📋 ISAR: ${unsyncedCredits.length} créditos sin sincronizar');
      return unsyncedCredits;
    } catch (e) {
      throw CacheException('Error obteniendo créditos no sincronizados: $e');
    }
  }

  /// Marcar crédito como sincronizado y actualizar su ID
  Future<void> markCreditAsSynced(String tempId, String serverId) async {
    try {
      final isar = _database.database;

      await isar.writeTxn(() async {
        final tempCredit = await isar.isarCustomerCredits
            .filter()
            .serverIdEqualTo(tempId)
            .findFirst();

        if (tempCredit != null) {
          tempCredit.serverId = serverId;
          tempCredit.isSynced = true;
          tempCredit.updatedAt = DateTime.now();
          tempCredit.lastSyncAt = DateTime.now();

          await isar.isarCustomerCredits.put(tempCredit);
        }
      });

      print('✅ ISAR: Crédito marcado como sincronizado: $tempId -> $serverId');
    } catch (e) {
      throw CacheException('Error marcando crédito como sincronizado: $e');
    }
  }

  // ==================== MÉTODOS HELPER ====================

  /// Convertir IsarCustomerCredit a CustomerCreditModel
  CustomerCreditModel _convertToModel(IsarCustomerCredit isarCredit) {
    // Deserializar payments desde metadataJson
    List<CreditPayment>? payments;
    if (isarCredit.metadataJson != null && isarCredit.metadataJson!.isNotEmpty) {
      try {
        final metadata = jsonDecode(isarCredit.metadataJson!) as Map<String, dynamic>;
        if (metadata['payments'] != null) {
          payments = (metadata['payments'] as List).map((p) =>
            CreditPayment(
              id: p['id'] ?? '',
              amount: (p['amount'] as num).toDouble(),
              paymentMethod: p['paymentMethod'] ?? '',
              paymentDate: DateTime.parse(p['paymentDate']),
              reference: p['reference'],
              notes: p['notes'],
              creditId: p['creditId'] ?? '',
              bankAccountId: p['bankAccountId'],
              bankAccountName: p['bankAccountName'],
              organizationId: p['organizationId'] ?? '',
              createdById: p['createdById'] ?? '',
              createdByName: p['createdByName'],
              createdAt: DateTime.parse(p['createdAt']),
              updatedAt: DateTime.parse(p['updatedAt']),
            )
          ).toList();
        }
      } catch (e) {
        print('⚠️ Error deserializando payments: $e');
      }
    }

    return CustomerCreditModel(
      id: isarCredit.serverId,
      originalAmount: isarCredit.originalAmount,
      paidAmount: isarCredit.paidAmount,
      balanceDue: isarCredit.balanceDue,
      status: _mapFromIsarStatus(isarCredit.status),
      dueDate: isarCredit.dueDate,
      description: isarCredit.description,
      notes: isarCredit.notes,
      customerId: isarCredit.customerId,
      customerName: isarCredit.customerName,
      invoiceId: isarCredit.invoiceId,
      invoiceNumber: isarCredit.invoiceNumber,
      organizationId: isarCredit.organizationId,
      createdById: isarCredit.createdById,
      createdByName: isarCredit.createdByName,
      payments: payments,
      createdAt: isarCredit.createdAt,
      updatedAt: isarCredit.updatedAt,
      deletedAt: isarCredit.deletedAt,
    );
  }

  /// Convertir CustomerCreditModel a CustomerCredit entity
  CustomerCredit _modelToEntity(CustomerCreditModel model) {
    return CustomerCredit(
      id: model.id,
      originalAmount: model.originalAmount,
      paidAmount: model.paidAmount,
      balanceDue: model.balanceDue,
      status: model.status,
      dueDate: model.dueDate,
      description: model.description,
      notes: model.notes,
      customerId: model.customerId,
      customerName: model.customerName,
      invoiceId: model.invoiceId,
      invoiceNumber: model.invoiceNumber,
      organizationId: model.organizationId,
      createdById: model.createdById,
      createdByName: model.createdByName,
      payments: model.payments,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
    );
  }

  /// Serializar datos del crédito a JSON
  String _serializeCreditData(CustomerCreditModel credit) {
    try {
      return jsonEncode({
        'payments': credit.payments?.map((p) => {
          'id': p.id,
          'amount': p.amount,
          'paymentMethod': p.paymentMethod,
          'paymentDate': p.paymentDate.toIso8601String(),
          'reference': p.reference,
          'notes': p.notes,
          'creditId': p.creditId,
          'bankAccountId': p.bankAccountId,
          'organizationId': p.organizationId,
          'createdById': p.createdById,
          'createdAt': p.createdAt.toIso8601String(),
          'updatedAt': p.updatedAt.toIso8601String(),
        }).toList() ?? [],
      });
    } catch (e) {
      print('❌ Error serializando datos del crédito: $e');
      return '{}';
    }
  }

  /// Mapear CreditStatus a IsarCreditStatus
  IsarCreditStatus _mapToIsarStatus(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return IsarCreditStatus.pending;
      case CreditStatus.partiallyPaid:
        return IsarCreditStatus.partiallyPaid;
      case CreditStatus.paid:
        return IsarCreditStatus.paid;
      case CreditStatus.cancelled:
        return IsarCreditStatus.cancelled;
      case CreditStatus.overdue:
        return IsarCreditStatus.overdue;
    }
  }

  /// Mapear IsarCreditStatus a CreditStatus
  CreditStatus _mapFromIsarStatus(IsarCreditStatus status) {
    switch (status) {
      case IsarCreditStatus.pending:
        return CreditStatus.pending;
      case IsarCreditStatus.partiallyPaid:
        return CreditStatus.partiallyPaid;
      case IsarCreditStatus.paid:
        return CreditStatus.paid;
      case IsarCreditStatus.cancelled:
        return CreditStatus.cancelled;
      case IsarCreditStatus.overdue:
        return CreditStatus.overdue;
    }
  }

  /// Obtener timestamp de última sincronización
  Future<DateTime?> getLastSyncTime() async {
    try {
      final isar = _database.database;
      final credit = await isar.isarCustomerCredits
          .filter()
          .lastSyncAtIsNotNull()
          .sortByLastSyncAtDesc()
          .findFirst();

      return credit?.lastSyncAt;
    } catch (e) {
      return null;
    }
  }

  /// Verificar si hay datos offline
  Future<bool> hasOfflineData() async {
    try {
      final isar = _database.database;
      final count = await isar.isarCustomerCredits
          .filter()
          .deletedAtIsNull()
          .count();

      print('📦 ISAR: $count créditos disponibles offline');
      return count > 0;
    } catch (e) {
      return false;
    }
  }
}
