// lib/features/customer_credits/data/repositories/customer_credit_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_credit_repository.dart';
import '../datasources/customer_credit_local_datasource.dart';
import '../datasources/customer_credit_remote_datasource.dart';
import '../credit_limit_guard.dart';
import '../models/customer_credit_model.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_item.dart';
import '../../../invoices/domain/entities/invoice_payment.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart' show IsarInvoiceStatus;
import '../models/isar/isar_customer_credit.dart';

/// Implementación del repositorio de créditos
class CustomerCreditRepositoryImpl implements CustomerCreditRepository {
  final CustomerCreditRemoteDataSource remoteDataSource;
  final CustomerCreditLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CustomerCreditRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  /// Helper para detectar errores de timeout/conexión
  bool _isTimeoutError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('timeout') || msg.contains('tiempo') ||
        msg.contains('socketexception') || msg.contains('conexión') ||
        msg.contains('connection') || error is ConnectionException;
  }

  /// Lista de créditos LOCAL-FIRST: se lee de la base del equipo, que la
  /// sincronización incremental mantiene al día cada pocos segundos. Antes se
  /// pedía al servidor la lista completa (miles de créditos) y la pantalla
  /// esperaba esa respuesta; además no mostraba los créditos hechos sin
  /// conexión que aún no subían. Solo si el equipo no tiene ningún crédito
  /// (primera descarga sin terminar) se consulta al servidor.
  @override
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query) async {
    final local = await _localCredits();
    if (local.isNotEmpty) return Right(_applyQuery(local, query));

    if (await networkInfo.isConnected) {
      try {
        final credits = await remoteDataSource.getCredits(query);
        networkInfo.resetServerReachability();
        await _cacheWithoutPendingChanges(credits.cast<CustomerCreditModel>());
        return Right(credits);
      } catch (e) {
        AppLogger.w('Error obteniendo créditos del servidor: $e', tag: 'CREDIT');
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
      }
    }
    return const Right(<CustomerCredit>[]);
  }

  Future<List<CustomerCreditModel>> _localCredits() async {
    try {
      return withoutReplacedProvisionalCredits(
          await localDataSource.getCachedCredits());
    } catch (_) {
      return const [];
    }
  }

  /// Una venta a crédito hecha sin conexión crea en el equipo un crédito
  /// provisional (`credit_offline_…`). Cuando la factura sube, el servidor
  /// crea el crédito real. Si ambos están en el equipo, se muestra solo el
  /// real (si no, la deuda aparecería dos veces). Mientras el real no llegue,
  /// el provisional se sigue mostrando.
  static List<CustomerCreditModel> withoutReplacedProvisionalCredits(
    List<CustomerCreditModel> credits,
  ) {
    bool isProvisional(CustomerCreditModel c) => c.id.startsWith('credit_offline_');
    final realInvoiceIds = <String>{};
    final realInvoiceNumbers = <String>{};
    for (final c in credits) {
      if (isProvisional(c)) continue;
      if (c.invoiceId != null && c.invoiceId!.isNotEmpty) realInvoiceIds.add(c.invoiceId!);
      if (c.invoiceNumber != null && c.invoiceNumber!.isNotEmpty) {
        realInvoiceNumbers.add('${c.customerId}|${c.invoiceNumber}');
      }
    }
    return credits.where((c) {
      if (!isProvisional(c)) return true;
      if (c.invoiceId != null && realInvoiceIds.contains(c.invoiceId)) return false;
      if (c.invoiceNumber != null &&
          realInvoiceNumbers.contains('${c.customerId}|${c.invoiceNumber}')) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Mismos filtros que el listado del servidor.
  List<CustomerCredit> _applyQuery(
    List<CustomerCreditModel> credits,
    CustomerCreditQueryParams? query,
  ) {
    final now = DateTime.now();
    DateTime? parseDay(String? value, {bool end = false}) {
      if (value == null || value.isEmpty) return null;
      final d = DateTime.tryParse(value);
      if (d == null) return null;
      return end ? DateTime(d.year, d.month, d.day, 23, 59, 59) : DateTime(d.year, d.month, d.day);
    }

    final start = parseDay(query?.startDate);
    final end = parseDay(query?.endDate, end: true);
    return credits.where((c) {
      if (query?.customerId != null && c.customerId != query!.customerId) return false;
      if (query?.status != null && c.status.value != query!.status) return false;
      if (query?.includeCancelled != true && c.status == CreditStatus.cancelled) return false;
      if (query?.overdueOnly == true) {
        final open = c.status != CreditStatus.paid && c.status != CreditStatus.cancelled;
        if (!open || c.dueDate == null || !c.dueDate!.isBefore(now)) return false;
      }
      if (start != null && c.createdAt.isBefore(start)) return false;
      if (end != null && c.createdAt.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// Guarda en el equipo lo que respondió el servidor, sin pisar créditos con
  /// cambios hechos aquí que aún no suben (un abono sin conexión, p. ej.).
  Future<void> _cacheWithoutPendingChanges(List<CustomerCreditModel> credits) async {
    final pending = await _creditIdsWithPendingChanges();
    final safe = credits.where((c) => !pending.contains(c.id)).toList();
    if (safe.isEmpty) return;
    await localDataSource.cacheCredits(safe);
  }

  Future<Set<String>> _creditIdsWithPendingChanges() async {
    try {
      final ops = await IsarDatabase.instance.getPendingSyncOperations();
      return ops
          .where((op) => op.entityType == 'CustomerCredit' || op.entityType == 'customer_credit')
          .map((op) => op.entityId)
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  /// Obtener créditos desde cache local (ISAR)
  Future<Either<Failure, List<CustomerCredit>>> _getCreditsFromCache() async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      if (cachedCredits.isNotEmpty) {
        AppLogger.i('Créditos cargados desde cache local (${cachedCredits.length} registros)', tag: 'CREDIT');
        return Right(cachedCredits);
      }
      return const Right(<CustomerCredit>[]);
    } catch (cacheError) {
      AppLogger.w('Error al obtener créditos del cache: $cacheError', tag: 'CREDIT');
      return const Right(<CustomerCredit>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> getCreditById(String id) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        // Con cambios hechos en este equipo sin subir, manda lo local.
        if ((await _creditIdsWithPendingChanges()).contains(id)) {
          return _getCreditFromCache(id);
        }
        final credit = await remoteDataSource.getCreditById(id);
        networkInfo.resetServerReachability();
        await localDataSource.cacheCredit(credit as CustomerCreditModel);
        return Right(credit);
      } catch (e) {
        AppLogger.w('Error obteniendo crédito del servidor: $e - intentando cache local...', tag: 'CREDIT');
        if (_isTimeoutError(e)) {
          networkInfo.markServerUnreachable();
        }
        return _getCreditFromCache(id);
      }
    } else {
      return _getCreditFromCache(id);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> getCreditByIdLocal(String id) {
    return _getCreditFromCache(id);
  }

  Future<Either<Failure, CustomerCredit>> _getCreditFromCache(String id) async {
    try {
      final cachedCredit = await localDataSource.getCachedCredit(id);
      if (cachedCredit != null) {
        AppLogger.i('Crédito cargado desde SecureStorage', tag: 'CREDIT');
        final enriched = await _enrichWithInvoiceItems(cachedCredit);
        return Right(enriched);
      }

      // Fallback: try ISAR (credits synced via FullSync are there)
      final isarCredit = await _getCreditFromIsar(id);
      if (isarCredit != null) {
        AppLogger.i('Crédito cargado desde ISAR', tag: 'CREDIT');
        final enriched = await _enrichWithInvoiceItems(isarCredit);
        return Right(enriched);
      }

      return Left(CacheFailure('Crédito no encontrado en cache local'));
    } catch (cacheError) {
      return Left(CacheFailure('Error al obtener crédito del cache: $cacheError'));
    }
  }

  Future<CustomerCreditModel?> _getCreditFromIsar(String id) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarCredit = await isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(id)
          .findFirst();
      if (isarCredit == null) return null;

      final statusMap = {
        IsarCreditStatus.pending: CreditStatus.pending,
        IsarCreditStatus.partiallyPaid: CreditStatus.partiallyPaid,
        IsarCreditStatus.paid: CreditStatus.paid,
        IsarCreditStatus.cancelled: CreditStatus.cancelled,
        IsarCreditStatus.overdue: CreditStatus.overdue,
      };

      return CustomerCreditModel(
        id: isarCredit.serverId,
        originalAmount: isarCredit.originalAmount,
        paidAmount: isarCredit.paidAmount,
        balanceDue: isarCredit.balanceDue,
        status: statusMap[isarCredit.status] ?? CreditStatus.pending,
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
        createdAt: isarCredit.createdAt,
        updatedAt: isarCredit.updatedAt,
        deletedAt: isarCredit.deletedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Enrich a cached credit with invoice items from ISAR (offline fallback)
  Future<CustomerCredit> _enrichWithInvoiceItems(CustomerCreditModel credit) async {
    if (credit.invoiceItems != null && credit.invoiceItems!.isNotEmpty) return credit;
    final invoiceId = credit.invoiceId;
    if (invoiceId == null || invoiceId.isEmpty) return credit;

    try {
      final isar = IsarDatabase.instance.database;
      final isarInvoice = await isar.isarInvoices
          .filter()
          .serverIdEqualTo(invoiceId)
          .findFirst();

      if (isarInvoice == null) return credit;

      final invoiceItems = IsarInvoice.decodeItemsPublic(isarInvoice.itemsJson);
      if (invoiceItems.isEmpty) return credit;

      final summaries = invoiceItems.map((item) => InvoiceItemSummary(
        id: item.id,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal: item.subtotal,
        productName: item.description,
      )).toList();

      return credit.copyWith(invoiceItems: summaries);
    } catch (_) {
      return credit;
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCreditsByCustomer(String customerId) async {
    final local = await _localCredits();
    if (local.isNotEmpty) {
      return Right(local.where((c) => c.customerId == customerId).toList());
    }
    if (await networkInfo.isConnected) {
      try {
        final credits = await remoteDataSource.getCreditsByCustomer(customerId);
        networkInfo.resetServerReachability();
        return Right(credits);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        // Fallback: filtrar desde cache local
        return _getCreditsByCustomerFromCache(customerId);
      }
    } else {
      return _getCreditsByCustomerFromCache(customerId);
    }
  }

  Future<Either<Failure, List<CustomerCredit>>> _getCreditsByCustomerFromCache(String customerId) async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final filtered = cachedCredits.where((c) => c.customerId == customerId).toList();
      AppLogger.d('Cache: ${filtered.length} créditos del cliente $customerId', tag: 'CREDIT');
      return Right(filtered);
    } catch (e) {
      return const Right(<CustomerCredit>[]);
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getPendingCreditsByCustomer(String customerId) async {
    final local = await _localCredits();
    if (local.isNotEmpty) {
      // Igual que el servidor: lo que no está pagado, del más antiguo al más
      // nuevo (los abonos se aplican en ese orden). Sin cancelados: no deben.
      final pending = local
          .where((c) =>
              c.customerId == customerId &&
              c.status != CreditStatus.paid &&
              c.status != CreditStatus.cancelled)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return Right(pending);
    }
    if (await networkInfo.isConnected) {
      try {
        final credits = await remoteDataSource.getPendingCreditsByCustomer(customerId);
        networkInfo.resetServerReachability();
        return Right(credits);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        return _getPendingCreditsByCustomerFromCache(customerId);
      }
    } else {
      return _getPendingCreditsByCustomerFromCache(customerId);
    }
  }

  Future<Either<Failure, List<CustomerCredit>>> _getPendingCreditsByCustomerFromCache(String customerId) async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final filtered = cachedCredits.where((c) =>
        c.customerId == customerId &&
        (c.status == CreditStatus.pending || c.status == CreditStatus.partiallyPaid)
      ).toList();
      return Right(filtered);
    } catch (e) {
      return const Right(<CustomerCredit>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> createCredit(CreateCustomerCreditDto dto) async {
    // LÍMITE DE CRÉDITO: una deuda directa (sin factura) no puede pasar el
    // cupo del cliente. Se valida ANTES de guardar, con datos locales, para
    // avisar de inmediato aunque no haya internet. Los créditos de factura
    // se validan al guardar la factura.
    if (dto.invoiceId == null || dto.invoiceId!.isEmpty) {
      final limitFailure = await _creditLimitFailure(dto.customerId, dto.originalAmount);
      if (limitFailure != null) return Left(limitFailure);
    }

    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.createCredit(dto);

        // Cache locally
        try {
          // credit is already a CustomerCredit, cast it to CustomerCreditModel for caching
          if (credit is CustomerCreditModel) {
            await localDataSource.cacheCredit(credit);
          }
        } catch (e) {
          AppLogger.w('Error al guardar crédito en cache: $e', tag: 'CREDIT');
        }

        return Right(credit);
      } on ServerException catch (e) {
        // Rechazo del servidor (límite de crédito, datos inválidos...): se
        // informa y NO se guarda localmente como si hubiera quedado.
        if (_isBusinessRejection(e)) {
          AppLogger.w('[CREDIT_REPO] Crédito rechazado por el servidor (${e.statusCode}): ${e.message}', tag: 'CREDIT');
          return Left(ServerFailure(e.message, code: e.statusCode));
        }
        AppLogger.w('[CREDIT_REPO] ServerException en create: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _createCreditOffline(dto);
      } on ConnectionException catch (e) {
        AppLogger.w('[CREDIT_REPO] ConnectionException en create: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _createCreditOffline(dto);
      } catch (e) {
        AppLogger.w('[CREDIT_REPO] Exception en create: $e - Fallback offline...', tag: 'CREDIT');
        return _createCreditOffline(dto);
      }
    } else {
      return _createCreditOffline(dto);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addPayment(String creditId, AddCreditPaymentDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.addPayment(creditId, dto);

        // Update cache
        try {
          // credit is already a CustomerCredit, cast it to CustomerCreditModel for caching
          if (credit is CustomerCreditModel) {
            await localDataSource.cacheCredit(credit);
          }
        } catch (e) {
          AppLogger.w('Error al actualizar crédito en cache: $e', tag: 'CREDIT');
        }

        return Right(credit);
      } on ServerException catch (e) {
        // El servidor RECHAZÓ el abono (crédito ya pagado, caja cerrada, sin
        // permiso, datos inválidos...). No es un problema de red: encolarlo
        // offline lo mostraría como pagado en el dispositivo sin que exista
        // en el servidor. Se informa el error y no se guarda nada local.
        if (_isBusinessRejection(e)) {
          AppLogger.w('[CREDIT_REPO] Abono rechazado por el servidor (${e.statusCode}): ${e.message}', tag: 'CREDIT');
          return Left(ServerFailure(e.message, code: e.statusCode));
        }
        AppLogger.w('[CREDIT_REPO] ServerException en addPayment: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _addPaymentOffline(creditId, dto);
      } on ConnectionException catch (e) {
        AppLogger.w('[CREDIT_REPO] ConnectionException en addPayment: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _addPaymentOffline(creditId, dto);
      } catch (e) {
        AppLogger.w('[CREDIT_REPO] Exception en addPayment: $e - Fallback offline...', tag: 'CREDIT');
        return _addPaymentOffline(creditId, dto);
      }
    } else {
      return _addPaymentOffline(creditId, dto);
    }
  }

  @override
  Future<Either<Failure, List<CreditPayment>>> getCreditPayments(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        final payments = await remoteDataSource.getCreditPayments(creditId);
        networkInfo.resetServerReachability();
        return Right(payments);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo pagos: $e - intentando cache...', tag: 'CREDIT');
        return _getCreditPaymentsFromCache(creditId);
      }
    } else {
      return _getCreditPaymentsFromCache(creditId);
    }
  }

  /// Obtener pagos desde el crédito cacheado localmente
  Future<Either<Failure, List<CreditPayment>>> _getCreditPaymentsFromCache(String creditId) async {
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit != null && cachedCredit.payments != null) {
        AppLogger.d('Pagos obtenidos desde cache (${cachedCredit.payments!.length})', tag: 'CREDIT');
        return Right(cachedCredit.payments!);
      }
      return const Right(<CreditPayment>[]);
    } catch (e) {
      return const Right(<CreditPayment>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> cancelCredit(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.cancelCredit(creditId);
        networkInfo.resetServerReachability();
        if (credit is CustomerCreditModel) {
          await localDataSource.cacheCredit(credit);
        }
        return Right(credit);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en cancelCredit: $e - Fallback offline...', tag: 'CREDIT');
        return _cancelCreditOffline(creditId);
      }
    } else {
      return _cancelCreditOffline(creditId);
    }
  }

  @override
  Future<Either<Failure, int>> markOverdueCredits() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.markOverdueCredits();
        networkInfo.resetServerReachability();
        return Right(count);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        // Calcular localmente desde cache
        return _markOverdueCreditsLocally();
      }
    } else {
      return _markOverdueCreditsLocally();
    }
  }

  @override
  Future<Either<Failure, CreditStats>> getCreditStats() async {
    // Local-first: calculadas con los mismos créditos que muestra la lista.
    if ((await _localCredits()).isNotEmpty) return _getStatsFromCache();

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        final stats = await remoteDataSource.getCreditStats();
        networkInfo.resetServerReachability();
        return Right(stats);
      } catch (e) {
        AppLogger.w('Error obteniendo estadísticas del servidor: $e - calculando desde cache local...', tag: 'CREDIT');
        if (_isTimeoutError(e)) {
          networkInfo.markServerUnreachable();
        }
        return _getStatsFromCache();
      }
    } else {
      AppLogger.d('📴 Sin conexión, calculando stats desde cache...', tag: 'CREDIT');
      return _getStatsFromCache();
    }
  }

  /// Calcular estadísticas desde créditos en cache local con desglose por tipo
  /// Consistente con el backend: totalPaid = originalAmount de créditos PAID
  Future<Either<Failure, CreditStats>> _getStatsFromCache() async {
    try {
      final cachedCredits = await _localCredits();

      double totalPending = 0, totalOverdue = 0, totalPaid = 0;
      int countPending = 0, countOverdue = 0;
      double directPending = 0, directOverdue = 0, directPaid = 0;
      double invoicePending = 0, invoiceOverdue = 0, invoicePaid = 0;
      int directCountPending = 0, directCountOverdue = 0;
      int invoiceCountPending = 0, invoiceCountOverdue = 0;

      for (final credit in cachedCredits) {
        final isInvoice = credit.invoiceId != null && credit.invoiceId!.isNotEmpty;

        if (credit.status == CreditStatus.paid) {
          totalPaid += credit.originalAmount;
          if (isInvoice) { invoicePaid += credit.originalAmount; }
          else { directPaid += credit.originalAmount; }
          continue;
        }

        if (credit.status == CreditStatus.cancelled) continue;

        // Verificar overdue: status explícito O fecha vencida con saldo pendiente
        if ((credit.status == CreditStatus.overdue) ||
            (credit.dueDate != null && credit.dueDate!.isBefore(DateTime.now()) && credit.balanceDue > 0)) {
          countOverdue++;
          totalOverdue += credit.balanceDue;
          if (isInvoice) { invoiceOverdue += credit.balanceDue; invoiceCountOverdue++; }
          else { directOverdue += credit.balanceDue; directCountOverdue++; }
        } else if (credit.status == CreditStatus.pending || credit.status == CreditStatus.partiallyPaid) {
          countPending++;
          totalPending += credit.balanceDue;
          if (isInvoice) { invoicePending += credit.balanceDue; invoiceCountPending++; }
          else { directPending += credit.balanceDue; directCountPending++; }
        }
      }

      final stats = CreditStats(
        totalPending: totalPending,
        totalOverdue: totalOverdue,
        countPending: countPending,
        countOverdue: countOverdue,
        totalPaid: totalPaid,
        directPending: directPending,
        directOverdue: directOverdue,
        directPaid: directPaid,
        directCountPending: directCountPending,
        directCountOverdue: directCountOverdue,
        invoicePending: invoicePending,
        invoiceOverdue: invoiceOverdue,
        invoicePaid: invoicePaid,
        invoiceCountPending: invoiceCountPending,
        invoiceCountOverdue: invoiceCountOverdue,
      );

      AppLogger.i('Estadísticas calculadas desde cache local (${cachedCredits.length} créditos)', tag: 'CREDIT');
      return Right(stats);
    } catch (cacheError) {
      // Retornar stats vacías en vez de error
      return Right(CreditStats(
        totalPending: 0, totalOverdue: 0,
        countPending: 0, countOverdue: 0, totalPaid: 0,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCredit(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCredit(creditId);

        // Remove from cache
        await localDataSource.removeCachedCredit(creditId);

        return const Right(null);
      } on ServerException catch (e) {
        AppLogger.w('[CREDIT_REPO] ServerException en delete: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _deleteCreditOffline(creditId);
      } on ConnectionException catch (e) {
        AppLogger.w('[CREDIT_REPO] ConnectionException en delete: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _deleteCreditOffline(creditId);
      } catch (e) {
        AppLogger.w('[CREDIT_REPO] Exception en delete: $e - Fallback offline...', tag: 'CREDIT');
        return _deleteCreditOffline(creditId);
      }
    } else {
      return _deleteCreditOffline(creditId);
    }
  }

  // ==================== CREDIT TRANSACTIONS ====================

  @override
  Future<Either<Failure, List<CreditTransactionModel>>> getCreditTransactions(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        final transactions = await remoteDataSource.getCreditTransactions(creditId);
        networkInfo.resetServerReachability();
        return Right(transactions);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo transacciones: $e - retornando lista vacía', tag: 'CREDIT');
        return const Right(<CreditTransactionModel>[]);
      }
    } else {
      AppLogger.d('📴 Sin conexión, retornando transacciones vacías', tag: 'CREDIT');
      return const Right(<CreditTransactionModel>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addAmountToCredit(String creditId, AddAmountToCreditDto dto) async {
    // LÍMITE DE CRÉDITO: aumentar la deuda no puede pasar el cupo del
    // cliente. Se valida antes de guardar, con datos locales.
    try {
      final cachedForLimit = await localDataSource.getCachedCredit(creditId);
      if (cachedForLimit != null) {
        final limitFailure = await _creditLimitFailure(cachedForLimit.customerId, dto.amount);
        if (limitFailure != null) return Left(limitFailure);
      }
    } catch (e) {
      AppLogger.w('No se pudo validar el límite localmente: $e', tag: 'CREDIT');
    }

    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.addAmountToCredit(creditId, dto);
        networkInfo.resetServerReachability();
        // Actualizar cache local
        if (credit is CustomerCreditModel) {
          await localDataSource.cacheCredit(credit);
        }
        return Right(credit);
      } catch (e) {
        // Rechazo del servidor (límite de crédito, crédito pagado...): se
        // informa y NO se aplica localmente.
        if (e is ServerException && _isBusinessRejection(e)) {
          AppLogger.w('[CREDIT_REPO] Aumento de deuda rechazado por el servidor (${e.statusCode}): ${e.message}', tag: 'CREDIT');
          return Left(ServerFailure(e.message, code: e.statusCode));
        }
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en addAmountToCredit: $e - Fallback offline...', tag: 'CREDIT');
        return _addAmountToCreditOffline(creditId, dto);
      }
    } else {
      return _addAmountToCreditOffline(creditId, dto);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.applyBalanceToCredit(creditId, dto);
        networkInfo.resetServerReachability();
        if (credit is CustomerCreditModel) {
          await localDataSource.cacheCredit(credit);
        }
        return Right(credit);
      } catch (e) {
        // Rechazo del servidor (sin saldo a favor, crédito pagado...): se
        // informa y NO se aplica localmente.
        if (e is ServerException && _isBusinessRejection(e)) {
          AppLogger.w('[CREDIT_REPO] Aplicación de saldo rechazada por el servidor (${e.statusCode}): ${e.message}', tag: 'CREDIT');
          return Left(ServerFailure(e.message, code: e.statusCode));
        }
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en applyBalanceToCredit: $e - Fallback offline...', tag: 'CREDIT');
        return _applyBalanceToCreditOffline(creditId, dto);
      }
    } else {
      return _applyBalanceToCreditOffline(creditId, dto);
    }
  }

  // ==================== CLIENT BALANCE ====================

  @override
  Future<Either<Failure, List<ClientBalanceModel>>> getAllClientBalances() async {
    if (await networkInfo.isConnected) {
      try {
        final balances = await remoteDataSource.getAllClientBalances();
        networkInfo.resetServerReachability();
        return Right(balances);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo saldos: $e - retornando lista vacía', tag: 'CREDIT');
        return const Right(<ClientBalanceModel>[]);
      }
    } else {
      return const Right(<ClientBalanceModel>[]);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel?>> getClientBalance(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.getClientBalance(customerId);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo saldo del cliente: $e - retornando null', tag: 'CREDIT');
        return const Right(null);
      }
    } else {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, List<ClientBalanceTransactionModel>>> getClientBalanceTransactions(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final transactions = await remoteDataSource.getClientBalanceTransactions(customerId);
        networkInfo.resetServerReachability();
        return Right(transactions);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo transacciones de saldo: $e - retornando lista vacía', tag: 'CREDIT');
        return const Right(<ClientBalanceTransactionModel>[]);
      }
    } else {
      return const Right(<ClientBalanceTransactionModel>[]);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> depositBalance(DepositBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.depositBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en depositBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _depositBalanceOffline(dto);
      }
    } else {
      return _depositBalanceOffline(dto);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> useBalance(UseBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.useBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en useBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _useBalanceOffline(dto);
      }
    } else {
      return _useBalanceOffline(dto);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> refundBalance(RefundBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.refundBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en refundBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _refundBalanceOffline(dto);
      }
    } else {
      return _refundBalanceOffline(dto);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> adjustBalance(AdjustBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.adjustBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en adjustBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _adjustBalanceOffline(dto);
      }
    } else {
      return _adjustBalanceOffline(dto);
    }
  }

  // ==================== CUSTOMER ACCOUNT ====================

  @override
  Future<Either<Failure, CustomerAccountModel>> getCustomerAccount(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final account = await remoteDataSource.getCustomerAccount(customerId);
        networkInfo.resetServerReachability();
        return Right(account);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo cuenta corriente: $e - construyendo desde cache...', tag: 'CREDIT');
        return _getCustomerAccountFromCache(customerId);
      }
    } else {
      AppLogger.d('📴 Sin conexión, construyendo cuenta corriente desde cache...', tag: 'CREDIT');
      return _getCustomerAccountFromCache(customerId);
    }
  }

  /// `true` cuando el servidor respondió y rechazó la operación por una regla
  /// de negocio o de validación (4xx). Esos casos NO se reintentan ni se
  /// encolan. 401 (sesión vencida), 408 y 429 sí son reintentables.
  bool _isBusinessRejection(ServerException e) {
    final code = e.statusCode;
    if (code == null) return false;
    if (code == 401 || code == 408 || code == 429) return false;
    return code >= 400 && code < 500;
  }

  /// Devuelve un Failure si agregar [amount] de deuda al cliente supera su
  /// límite de crédito (deuda pendiente + monto nuevo > cupo); `null` si cabe.
  Future<Failure?> _creditLimitFailure(String customerId, double amount) async {
    final check = await CreditLimitGuard.check(customerId: customerId, amount: amount);
    if (check == null || check.allowed) return null;
    AppLogger.w('[CREDIT_REPO] Límite de crédito excedido: debe ${check.pendingDebt}, cupo ${check.creditLimit}, nuevo ${check.amount}', tag: 'CREDIT');
    return ServerFailure('Límite de crédito excedido. ${check.message}', code: 400);
  }

  // ==================== SYNC QUEUE HELPER ====================

  /// Helper para agregar operaciones a la cola de sincronización de forma segura
  /// Usa addOperation directamente con organizationId del AuthController o del crédito
  Future<void> _addToSyncQueue({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    String? fallbackOrganizationId,
    int priority = 1,
  }) async {
    // Un cambio local SIN su operación en la cola nunca llegaría al
    // servidor. Por eso, si no se puede encolar, esto LANZA: el llamador
    // deshace el cambio local y le informa el error al usuario, en vez de
    // dejarlo creyendo que quedó guardado.
    final syncService = Get.find<SyncService>();
    final authController = Get.find<AuthController>();

    // Obtener organizationId: primero del usuario, luego del fallback
    String organizationId = authController.currentUser?.organizationId ?? '';
    if (organizationId.isEmpty && fallbackOrganizationId != null) {
      organizationId = fallbackOrganizationId;
    }

    if (organizationId.isEmpty) {
      throw StateError(
        'No se pudo identificar la organización para guardar la operación pendiente',
      );
    }

    await syncService.addOperation(
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      data: data,
      organizationId: organizationId,
      priority: priority,
    );
    AppLogger.d('Operación $operationType agregada a sync queue: $entityType/$entityId', tag: 'CREDIT');
  }

  /// Encola un movimiento de un crédito ya modificado en la caché local. Si
  /// no se puede encolar, restaura el crédito a como estaba y relanza, para
  /// que el dispositivo nunca muestre un movimiento que no se va a subir.
  Future<void> _queueCreditChangeOrRevert({
    required String creditId,
    required CustomerCreditModel previous,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: creditId,
        operationType: SyncOperationType.update,
        data: data,
        fallbackOrganizationId: previous.organizationId,
      );
    } catch (e) {
      AppLogger.e('No se pudo encolar el movimiento del crédito $creditId: $e — se deshace el cambio local', tag: 'CREDIT');
      try {
        await localDataSource.cacheCredit(previous);
      } catch (revertError) {
        AppLogger.e('Tampoco se pudo restaurar el crédito local: $revertError', tag: 'CREDIT');
      }
      rethrow;
    }
  }

  // ==================== OFFLINE OPERATIONS ====================

  /// Create customer credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CustomerCredit>> _createCreditOffline(
    CreateCustomerCreditDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Creating credit offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final now = DateTime.now();
      final tempId = 'customercredit_offline_${now.millisecondsSinceEpoch}_${dto.customerId.hashCode}';

      // Parse dueDate from String to DateTime if provided
      DateTime? parsedDueDate;
      if (dto.dueDate != null) {
        try {
          parsedDueDate = DateTime.parse(dto.dueDate!);
        } catch (e) {
          AppLogger.w('Error parsing dueDate: $e', tag: 'CREDIT');
        }
      }

      // Get current user info for organizationId and createdById
      final authController = Get.find<AuthController>();
      final organizationId = authController.currentUser?.organizationId ?? '';
      final createdById = authController.currentUser?.id ?? '';

      // Create temporary credit entity
      final tempCredit = CustomerCreditModel(
        id: tempId,
        originalAmount: dto.originalAmount,
        paidAmount: 0.0,
        balanceDue: dto.originalAmount,
        status: CreditStatus.pending,
        dueDate: parsedDueDate,
        description: dto.description,
        notes: dto.notes,
        customerId: dto.customerId,
        customerName: null,
        invoiceId: dto.invoiceId,
        invoiceNumber: null,
        organizationId: organizationId,
        createdById: createdById,
        createdByName: authController.currentUser?.firstName,
        payments: null,
        createdAt: now,
        updatedAt: now,
      );

      // Cache locally
      await localDataSource.cacheCredit(tempCredit);

      // Add to sync queue
      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: tempId,
        operationType: SyncOperationType.create,
        data: {
          'customerId': dto.customerId,
          'originalAmount': dto.originalAmount,
          'dueDate': dto.dueDate,
          'description': dto.description,
          'notes': dto.notes,
          'invoiceId': dto.invoiceId,
          'skipAutoBalance': dto.skipAutoBalance,
        },
        fallbackOrganizationId: organizationId,
      );

      AppLogger.i('Customer credit created offline successfully', tag: 'CREDIT');
      return Right(tempCredit);
    } catch (e) {
      AppLogger.e('Error creating customer credit offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al crear crédito offline: $e'));
    }
  }

  /// Add payment to credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CustomerCredit>> _addPaymentOffline(
    String creditId,
    AddCreditPaymentDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Adding payment offline: $creditId', tag: 'CREDIT');
    // Asegurar que el cooldown quede activo para evitar timeouts en lecturas posteriores
    networkInfo.markServerUnreachable();
    try {
      // Get cached credit
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      // Calculate new amounts
      final newPaidAmount = cachedCredit.paidAmount + dto.amount;
      final newBalanceDue = cachedCredit.originalAmount - newPaidAmount;
      final newStatus = newBalanceDue <= 0 ? CreditStatus.paid : CreditStatus.pending;

      // Update credit with payment (using copyWith-like approach)
      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: cachedCredit.originalAmount,
        paidAmount: newPaidAmount,
        balanceDue: newBalanceDue,
        status: newStatus,
        dueDate: cachedCredit.dueDate,
        description: cachedCredit.description,
        notes: cachedCredit.notes,
        customerId: cachedCredit.customerId,
        customerName: cachedCredit.customerName,
        invoiceId: cachedCredit.invoiceId,
        invoiceNumber: cachedCredit.invoiceNumber,
        organizationId: cachedCredit.organizationId,
        createdById: cachedCredit.createdById,
        createdByName: cachedCredit.createdByName,
        payments: cachedCredit.payments,
        createdAt: cachedCredit.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: cachedCredit.deletedAt,
      );

      // Update cache
      await localDataSource.cacheCredit(updatedCredit);

      // Add to sync queue. Se usa la MISMA clave del abono que ya pudo haber
      // viajado en el intento en línea: si aquel intento sí llegó al servidor
      // (la respuesta se perdió), el reenvío desde la cola no lo duplica.
      final idempotencyKey = dto.idempotencyKey;
      await _queueCreditChangeOrRevert(
        creditId: creditId,
        previous: cachedCredit,
        data: {
          'action': 'addPayment',
          'idempotencyKey': idempotencyKey,
          'amount': dto.amount,
          'paymentMethod': dto.paymentMethod,
          'paymentDate': dto.paymentDate ?? DateTime.now().toIso8601String(),
          'reference': dto.reference,
          'notes': dto.notes,
          'bankAccountId': dto.bankAccountId,
        },
      );

      // ✅ Cross-update: actualizar factura asociada en ISAR
      if (cachedCredit.invoiceId != null && cachedCredit.invoiceId!.isNotEmpty) {
        await _crossUpdateInvoiceFromCreditPayment(
          invoiceId: cachedCredit.invoiceId!,
          paymentAmount: dto.amount,
          paymentMethod: dto.paymentMethod,
        );
      }

      AppLogger.i('Payment added offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error adding payment offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al agregar pago offline: $e'));
    }
  }

  /// Cross-update: actualizar factura en ISAR cuando se paga un crédito asociado.
  /// NO encola a sync queue - el backend maneja la cross-update.
  Future<void> _crossUpdateInvoiceFromCreditPayment({
    required String invoiceId,
    required double paymentAmount,
    required String paymentMethod,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarInvoice = await isar.isarInvoices
          .filter()
          .serverIdEqualTo(invoiceId)
          .findFirst();

      if (isarInvoice == null) {
        AppLogger.d('CustomerCreditRepo: No hay factura asociada en ISAR: $invoiceId', tag: 'CREDIT');
        return;
      }

      final now = DateTime.now();
      final newPaidAmount = isarInvoice.paidAmount + paymentAmount;
      final newBalanceDue = (isarInvoice.total - newPaidAmount).clamp(0.0, double.infinity);

      // Actualizar status
      if (newBalanceDue <= 0) {
        isarInvoice.status = IsarInvoiceStatus.paid;
      } else if (newPaidAmount > 0) {
        isarInvoice.status = IsarInvoiceStatus.partiallyPaid;
      }

      isarInvoice.paidAmount = newPaidAmount;
      isarInvoice.balanceDue = newBalanceDue;
      isarInvoice.updatedAt = now;

      // Append payment al paymentsJson
      final existingPayments = IsarInvoice.decodePayments(isarInvoice.paymentsJson);
      String createdById = '';
      String organizationId = '';
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser!.id;
          organizationId = authController.currentUser!.organizationId;
        }
      } catch (_) {}

      existingPayments.add(InvoicePayment(
        id: 'payment_credit_${now.millisecondsSinceEpoch}_${invoiceId.hashCode}',
        amount: paymentAmount,
        paymentMethod: PaymentMethod.fromString(paymentMethod),
        paymentDate: now,
        reference: 'Pago desde crédito',
        notes: 'Pago registrado desde pantalla de créditos (offline)',
        invoiceId: invoiceId,
        createdById: createdById,
        organizationId: organizationId,
        createdAt: now,
        updatedAt: now,
      ));

      isarInvoice.paymentsJson = IsarInvoice.encodePayments(existingPayments);

      await isar.writeTxn(() async {
        await isar.isarInvoices.put(isarInvoice);
      });

      AppLogger.i(
        'CustomerCreditRepo: Factura $invoiceId cross-updated: paidAmount=\$$newPaidAmount, balanceDue=\$$newBalanceDue',
        tag: 'CREDIT',
      );
    } catch (e) {
      AppLogger.w('CustomerCreditRepo: Error en cross-update factura: $e', tag: 'CREDIT');
    }
  }

  /// Agregar monto a crédito offline
  Future<Either<Failure, CustomerCredit>> _addAmountToCreditOffline(
    String creditId,
    AddAmountToCreditDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Adding amount offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      // Actualizar montos localmente
      final newOriginalAmount = cachedCredit.originalAmount + dto.amount;
      final newBalanceDue = cachedCredit.balanceDue + dto.amount;
      final newStatus = newBalanceDue > 0
          ? (cachedCredit.paidAmount > 0 ? CreditStatus.partiallyPaid : CreditStatus.pending)
          : CreditStatus.paid;

      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: newOriginalAmount,
        paidAmount: cachedCredit.paidAmount,
        balanceDue: newBalanceDue,
        status: newStatus,
        dueDate: cachedCredit.dueDate,
        description: cachedCredit.description,
        notes: cachedCredit.notes,
        customerId: cachedCredit.customerId,
        customerName: cachedCredit.customerName,
        invoiceId: cachedCredit.invoiceId,
        invoiceNumber: cachedCredit.invoiceNumber,
        organizationId: cachedCredit.organizationId,
        createdById: cachedCredit.createdById,
        createdByName: cachedCredit.createdByName,
        payments: cachedCredit.payments,
        createdAt: cachedCredit.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: cachedCredit.deletedAt,
      );

      await localDataSource.cacheCredit(updatedCredit);

      // Encolar para sincronización
      await _queueCreditChangeOrRevert(
        creditId: creditId,
        previous: cachedCredit,
        data: {
          'action': 'addAmount',
          'idempotencyKey': dto.idempotencyKey,
          'creditId': creditId,
          'amount': dto.amount,
          'description': dto.description,
        },
      );

      AppLogger.i('Amount added offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error adding amount offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al agregar monto offline: $e'));
    }
  }

  /// Aplicar saldo a favor a crédito offline
  Future<Either<Failure, CustomerCredit>> _applyBalanceToCreditOffline(
    String creditId,
    ApplyBalanceToCreditDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Applying balance offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      final amountToApply = dto.amount ?? cachedCredit.balanceDue;
      final newPaidAmount = cachedCredit.paidAmount + amountToApply;
      final newBalanceDue = cachedCredit.originalAmount - newPaidAmount;
      final newStatus = newBalanceDue <= 0 ? CreditStatus.paid : CreditStatus.partiallyPaid;

      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: cachedCredit.originalAmount,
        paidAmount: newPaidAmount,
        balanceDue: newBalanceDue < 0 ? 0 : newBalanceDue,
        status: newStatus,
        dueDate: cachedCredit.dueDate,
        description: cachedCredit.description,
        notes: cachedCredit.notes,
        customerId: cachedCredit.customerId,
        customerName: cachedCredit.customerName,
        invoiceId: cachedCredit.invoiceId,
        invoiceNumber: cachedCredit.invoiceNumber,
        organizationId: cachedCredit.organizationId,
        createdById: cachedCredit.createdById,
        createdByName: cachedCredit.createdByName,
        payments: cachedCredit.payments,
        createdAt: cachedCredit.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: cachedCredit.deletedAt,
      );

      await localDataSource.cacheCredit(updatedCredit);

      await _queueCreditChangeOrRevert(
        creditId: creditId,
        previous: cachedCredit,
        data: {
          'action': 'applyBalance',
          'idempotencyKey': dto.idempotencyKey,
          'creditId': creditId,
          'amount': dto.amount,
        },
      );

      AppLogger.i('Balance applied offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error applying balance offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al aplicar saldo offline: $e'));
    }
  }

  /// Cancelar crédito offline
  Future<Either<Failure, CustomerCredit>> _cancelCreditOffline(String creditId) async {
    AppLogger.d('CustomerCreditRepository: Cancelling credit offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: cachedCredit.originalAmount,
        paidAmount: cachedCredit.paidAmount,
        balanceDue: cachedCredit.balanceDue,
        status: CreditStatus.cancelled,
        dueDate: cachedCredit.dueDate,
        description: cachedCredit.description,
        notes: cachedCredit.notes,
        customerId: cachedCredit.customerId,
        customerName: cachedCredit.customerName,
        invoiceId: cachedCredit.invoiceId,
        invoiceNumber: cachedCredit.invoiceNumber,
        organizationId: cachedCredit.organizationId,
        createdById: cachedCredit.createdById,
        createdByName: cachedCredit.createdByName,
        payments: cachedCredit.payments,
        createdAt: cachedCredit.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: cachedCredit.deletedAt,
      );

      await localDataSource.cacheCredit(updatedCredit);

      await _queueCreditChangeOrRevert(
        creditId: creditId,
        previous: cachedCredit,
        data: {
          'action': 'cancel',
          'creditId': creditId,
        },
      );

      AppLogger.i('Credit cancelled offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error cancelling credit offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al cancelar crédito offline: $e'));
    }
  }

  /// Marcar créditos vencidos localmente
  Future<Either<Failure, int>> _markOverdueCreditsLocally() async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final now = DateTime.now();
      int count = 0;

      for (final credit in cachedCredits) {
        if (credit.dueDate != null &&
            credit.dueDate!.isBefore(now) &&
            credit.balanceDue > 0 &&
            credit.status != CreditStatus.overdue &&
            credit.status != CreditStatus.cancelled &&
            credit.status != CreditStatus.paid) {
          count++;
        }
      }

      AppLogger.d('Créditos vencidos calculados localmente: $count', tag: 'CREDIT');
      return Right(count);
    } catch (e) {
      return const Right(0);
    }
  }

  /// Depositar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _depositBalanceOffline(DepositBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Depositing balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: dto.amount,
        customerId: dto.customerId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.customerId,
        operationType: SyncOperationType.create,
        data: {
          'action': 'deposit',
          'customerId': dto.customerId,
          'amount': dto.amount,
          'description': dto.description,
          'relatedCreditId': dto.relatedCreditId,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance deposited offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al depositar saldo offline: $e'));
    }
  }

  /// Usar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _useBalanceOffline(UseBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Using balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: 0,
        customerId: dto.clientId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.clientId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'use',
          'clientId': dto.clientId,
          'amount': dto.amount,
          'description': dto.description,
          'relatedCreditId': dto.relatedCreditId,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance used offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al usar saldo offline: $e'));
    }
  }

  /// Reembolsar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _refundBalanceOffline(RefundBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Refunding balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: 0,
        customerId: dto.clientId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.clientId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'refund',
          'clientId': dto.clientId,
          'amount': dto.amount,
          'description': dto.description,
          'paymentMethod': dto.paymentMethod,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance refunded offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al reembolsar saldo offline: $e'));
    }
  }

  /// Ajustar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _adjustBalanceOffline(AdjustBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Adjusting balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: dto.amount,
        customerId: dto.clientId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.clientId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'adjust',
          'clientId': dto.clientId,
          'amount': dto.amount,
          'description': dto.description,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance adjusted offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al ajustar saldo offline: $e'));
    }
  }

  /// Construir cuenta corriente desde cache local
  Future<Either<Failure, CustomerAccountModel>> _getCustomerAccountFromCache(String customerId) async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final customerCredits = cachedCredits.where((c) => c.customerId == customerId).toList();

      // Separar créditos por tipo
      final invoiceCredits = customerCredits
          .where((c) => c.invoiceId != null && c.invoiceId!.isNotEmpty)
          .cast<CustomerCreditModel>()
          .toList();
      final directCredits = customerCredits
          .where((c) => c.invoiceId == null || c.invoiceId!.isEmpty)
          .cast<CustomerCreditModel>()
          .toList();

      // Calcular deudas
      double invoiceDebt = 0;
      double directDebt = 0;
      for (final c in invoiceCredits) {
        if (c.status != CreditStatus.cancelled && c.status != CreditStatus.paid) {
          invoiceDebt += c.balanceDue;
        }
      }
      for (final c in directCredits) {
        if (c.status != CreditStatus.cancelled && c.status != CreditStatus.paid) {
          directDebt += c.balanceDue;
        }
      }

      final totalDebt = invoiceDebt + directDebt;
      final customerName = customerCredits.isNotEmpty ? (customerCredits.first.customerName ?? '') : '';

      final account = CustomerAccountModel(
        customer: CustomerAccountCustomer(
          id: customerId,
          name: customerName,
          currentBalance: 0,
        ),
        summary: CustomerAccountSummary(
          totalDebt: totalDebt,
          invoiceDebt: invoiceDebt,
          directCreditDebt: directDebt,
          availableBalance: 0,
          netBalance: -totalDebt,
        ),
        invoiceCredits: invoiceCredits,
        directCredits: directCredits,
        clientBalance: const CustomerAccountBalance(balance: 0),
      );

      AppLogger.i('Cuenta corriente construida desde cache (${customerCredits.length} créditos)', tag: 'CREDIT');
      return Right(account);
    } catch (e) {
      AppLogger.w('Error construyendo cuenta corriente desde cache: $e', tag: 'CREDIT');
      // Retornar cuenta vacía en vez de error
      return Right(CustomerAccountModel(
        customer: CustomerAccountCustomer(id: customerId, name: '', currentBalance: 0),
        summary: const CustomerAccountSummary(
          totalDebt: 0, invoiceDebt: 0, directCreditDebt: 0,
          availableBalance: 0, netBalance: 0,
        ),
        invoiceCredits: const [],
        directCredits: const [],
        clientBalance: const CustomerAccountBalance(balance: 0),
      ));
    }
  }

  /// Delete customer credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, void>> _deleteCreditOffline(String creditId) async {
    AppLogger.d('CustomerCreditRepository: Deleting credit offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      // Remove from cache
      await localDataSource.removeCachedCredit(creditId);

      // Add to sync queue
      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: creditId,
        operationType: SyncOperationType.delete,
        data: {'id': creditId},
      );

      AppLogger.i('Customer credit deleted offline successfully', tag: 'CREDIT');
      return const Right(null);
    } catch (e) {
      AppLogger.e('Error deleting customer credit offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al eliminar crédito offline: $e'));
    }
  }
}
