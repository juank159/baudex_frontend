// lib/features/cash_register/data/repositories/cash_register_repository_impl.dart
import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../expenses/data/models/isar/isar_expense.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';
import '../datasources/cash_register_remote_datasource.dart';
import '../models/cash_register_model.dart';

/// Caja registradora offline-first.
///
/// Abrir y cerrar funcionan con o sin internet:
/// - Con conexión se hace directo en el servidor (que valida, p. ej., que no
///   haya otra caja abierta).
/// - Sin conexión (o si el servidor no responde) se hace en el equipo y queda
///   en la cola de sincronización con el id y la hora reales; al volver la
///   conexión se envía y el servidor calcula el cuadre definitivo.
///
/// El "esperado" en caja = último cuadre que dio el servidor + el efectivo
/// registrado en este equipo que todavía no ha subido (ventas, abonos y
/// gastos pagados con la caja). Así es correcto con y sin conexión.
class CashRegisterRepositoryImpl implements CashRegisterRepository {
  final CashRegisterRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SecureStorageService? secureStorage;

  /// Último estado conocido de la caja (servidor o cambios locales).
  static const _cacheKey = 'cash_register_current_cache';

  /// Historial de cajas para consultarlo sin conexión.
  static const _historyKey = 'cash_register_history_cache_v1';

  /// Tipo de entidad en la cola. Todas las operaciones de caja usan el mismo
  /// entityId para que la cola las envíe en orden (cerrar la anterior antes
  /// de abrir la siguiente).
  static const syncEntityType = 'CashRegister';
  static const syncEntityId = 'cash_register';

  CashRegisterRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    this.secureStorage,
  });

  // ==================== ESTADO ACTUAL ====================

  @override
  Future<Either<Failure, CashRegisterCurrentState>> getCurrent() async {
    // Con aperturas/cierres locales sin subir, el servidor aún no los conoce:
    // manda el estado local hasta que se sincronicen.
    final hasPendingLocalChange = (await _pendingCashRegisterOps()).isNotEmpty;

    CashRegisterCurrentStateModel? base;
    if (!hasPendingLocalChange && await networkInfo.isConnected) {
      try {
        base = await remoteDataSource.getCurrent();
        await _writeCache(base);
      } catch (e) {
        AppLogger.w('Caja: no se pudo leer del servidor, uso el estado guardado: $e',
            tag: 'CASH');
      }
    }
    base ??= await _readCache();
    if (base == null) {
      return Left(NetworkFailure(
        'Sin conexión y sin estado guardado de la caja. Conéctate al menos una vez para sincronizarla.',
      ));
    }
    return Right(await _withUnsyncedCash(base));
  }

  /// Suma al estado el efectivo registrado en este equipo que aún no subió.
  Future<CashRegisterCurrentState> _withUnsyncedCash(
    CashRegisterCurrentStateModel base,
  ) async {
    final register = base.cashRegister;
    if (register == null) return base;
    final delta = await _unsyncedCashSince(register.openedAt);
    if (delta.isEmpty) return base;

    final s = base.summary;
    final summary = CashRegisterSummaryModel(
      cashSales: s.cashSales + delta.cashIn,
      cashSalesCount: s.cashSalesCount + delta.cashInCount,
      cashExpenses: s.cashExpenses + delta.cashOut,
      cashExpensesCount: s.cashExpensesCount + delta.cashOutCount,
      cashDeposits: s.cashDeposits,
      cashWithdrawals: s.cashWithdrawals,
      invoicesCount: s.invoicesCount + delta.salesCount,
      creditNotesCount: s.creditNotesCount,
      creditNotesTotal: s.creditNotesTotal,
      cashFromSales: (s.cashFromSales ?? 0) + delta.salesCash,
      cashFromSalesCount: (s.cashFromSalesCount ?? 0) + delta.salesCount,
      cashFromCreditPayments:
          (s.cashFromCreditPayments ?? 0) + delta.creditPaymentsCash,
      cashFromCreditPaymentsCount:
          (s.cashFromCreditPaymentsCount ?? 0) + delta.creditPaymentsCount,
      otherMethods: s.otherMethods,
      otherMethodsTotal: s.otherMethodsTotal,
      otherMethodsCount: s.otherMethodsCount,
      totalCollected:
          s.totalCollected != null ? s.totalCollected! + delta.cashIn : null,
      creditSalesTotal: s.creditSalesTotal,
      creditSalesCount: s.creditSalesCount,
    );
    return CashRegisterCurrentState(
      cashRegister: register,
      summary: summary,
      expectedAmount: base.expectedAmount + delta.cashIn - delta.cashOut,
    );
  }

  // ==================== ABRIR ====================

  @override
  Future<Either<Failure, CashRegister>> open({
    required double openingAmount,
    String? openingNotes,
  }) async {
    final id = _uuidV4();
    final openedAt = DateTime.now();

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.open(
          openingAmount: openingAmount,
          openingNotes: openingNotes,
          id: id,
          openedAt: openedAt,
        );
        await _writeCache(CashRegisterCurrentStateModel(
          cashRegister: result,
          summary: CashRegisterSummary.empty,
          expectedAmount: result.openingAmount,
        ));
        return Right(result);
      } catch (e) {
        if (_isRejection(e)) return Left(ServerFailure(_message(e)));
        AppLogger.w('Caja: el servidor no respondió al abrir, se abre en el equipo: $e',
            tag: 'CASH');
      }
    }

    // ── Sin conexión: abrir en el equipo y encolar ──
    final current = await _readCache();
    if (current?.cashRegister != null) {
      return Left(CacheFailure(
          'Ya hay una caja abierta. Ciérrala antes de abrir otra.'));
    }
    final auth = _auth;
    final local = CashRegisterModel(
      id: id,
      status: CashRegisterStatus.open,
      openingAmount: openingAmount,
      openedAt: openedAt,
      openedById: auth?.currentUser?.id ?? '',
      openedByName: auth?.currentUser?.fullName,
      openingNotes: openingNotes,
      organizationId: auth?.currentUser?.organizationId ?? '',
      createdAt: openedAt,
      updatedAt: openedAt,
    );
    try {
      await _enqueue({
        'action': 'open',
        'id': id,
        'openingAmount': openingAmount,
        if (openingNotes != null) 'openingNotes': openingNotes,
        'openedAt': openedAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      return Left(CacheFailure(
          'No se pudo guardar la apertura en el equipo: $e'));
    }
    await _writeCache(CashRegisterCurrentStateModel(
      cashRegister: local,
      summary: CashRegisterSummary.empty,
      expectedAmount: openingAmount,
    ));
    return Right(local);
  }

  // ==================== CERRAR ====================

  @override
  Future<Either<Failure, CashRegister>> close({
    required String id,
    required double closingActualAmount,
    String? closingNotes,
  }) async {
    final closedAt = DateTime.now();
    final hasPendingLocalChange = (await _pendingCashRegisterOps()).isNotEmpty;

    // Si la apertura de esta caja aún no subió, el cierre también va por la
    // cola (detrás de ella).
    if (!hasPendingLocalChange && await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.close(
          id: id,
          closingActualAmount: closingActualAmount,
          closingNotes: closingNotes,
          closedAt: closedAt,
        );
        await _writeCache(const CashRegisterCurrentStateModel());
        await _rememberInHistory(result);
        return Right(result);
      } catch (e) {
        if (_isRejection(e)) return Left(ServerFailure(_message(e)));
        AppLogger.w('Caja: el servidor no respondió al cerrar, se cierra en el equipo: $e',
            tag: 'CASH');
      }
    }

    // ── Sin conexión: cerrar en el equipo y encolar ──
    final currentResult = await getCurrent();
    final current = currentResult.fold((_) => null, (s) => s);
    final register = current?.cashRegister;
    if (register == null || register.id != id) {
      return Left(CacheFailure('No hay una caja abierta para cerrar.'));
    }
    final expected = current!.expectedAmount;
    final difference =
        ((closingActualAmount - expected) * 100).roundToDouble() / 100;

    try {
      await _enqueue({
        'action': 'close',
        'id': id,
        'closingActualAmount': closingActualAmount,
        if (closingNotes != null) 'closingNotes': closingNotes,
        'closedAt': closedAt.toUtc().toIso8601String(),
        // Solo informativo: el servidor recalcula el cuadre con todos los datos.
        'localExpectedAmount': expected,
      });
    } catch (e) {
      return Left(CacheFailure('No se pudo guardar el cierre en el equipo: $e'));
    }

    final auth = _auth;
    final closed = CashRegisterModel(
      id: register.id,
      status: CashRegisterStatus.closed,
      openingAmount: register.openingAmount,
      closingExpectedAmount: expected,
      closingActualAmount: closingActualAmount,
      closingDifference: difference,
      closingSummary: current.summary,
      openedAt: register.openedAt,
      openedById: register.openedById,
      openedByName: register.openedByName,
      closedAt: closedAt,
      closedById: auth?.currentUser?.id,
      closedByName: auth?.currentUser?.fullName,
      openingNotes: register.openingNotes,
      closingNotes: closingNotes,
      organizationId: register.organizationId,
      createdAt: register.createdAt,
      updatedAt: closedAt,
    );
    await _writeCache(const CashRegisterCurrentStateModel());
    await _rememberInHistory(closed);
    return Right(closed);
  }

  // ==================== CONSULTAS ====================

  @override
  Future<Either<Failure, CashRegister>> findById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        return Right(await remoteDataSource.findById(id));
      } catch (e) {
        if (_isRejection(e)) return Left(ServerFailure(_message(e)));
      }
    }
    final current = (await _readCache())?.cashRegister;
    if (current?.id == id) return Right(current!);
    final cached = await _readHistory();
    final match = cached.where((r) => r.id == id);
    if (match.isNotEmpty) return Right(match.first);
    return Left(NetworkFailure('Sin conexión y esta caja no está guardada en el equipo'));
  }

  @override
  Future<Either<Failure, List<CashRegister>>> list({
    CashRegisterStatus? status,
    int limit = 30,
    int offset = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.list(
          status: status,
          limit: limit,
          offset: offset,
        );
        if (status == null && offset == 0) {
          await _writeHistory(await _mergeLocalPending(result));
        }
        return Right(_filter(await _mergeLocalPending(result), status));
      } catch (e) {
        if (_isRejection(e)) return Left(ServerFailure(_message(e)));
      }
    }
    final cached = await _readHistory();
    final current = (await _readCache())?.cashRegister;
    final all = [
      if (current != null && !cached.any((r) => r.id == current.id)) current,
      ...cached,
    ];
    return Right(_filter(all, status).skip(offset).take(limit).toList());
  }

  List<CashRegister> _filter(List<CashRegister> list, CashRegisterStatus? status) =>
      status == null ? list : list.where((r) => r.status == status).toList();

  /// Agrega al historial del servidor las cajas cerradas en este equipo que
  /// aún no subieron (para que no "desaparezcan" del historial).
  Future<List<CashRegister>> _mergeLocalPending(List<CashRegisterModel> server) async {
    final cached = await _readHistory();
    final pendingIds = (await _pendingCashRegisterOps())
        .map((op) => _decode(op.payload)['id'])
        .whereType<String>()
        .toSet();
    final serverIds = server.map((r) => r.id).toSet();
    final localOnly =
        cached.where((r) => pendingIds.contains(r.id) && !serverIds.contains(r.id));
    final merged = <CashRegister>[...localOnly, ...server];
    merged.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return merged;
  }

  // ==================== EFECTIVO SIN SUBIR ====================

  /// Efectivo registrado en este equipo desde [since] que aún está en la
  /// cola (el servidor todavía no lo cuenta).
  Future<_UnsyncedCash> _unsyncedCashSince(DateTime since) async {
    final result = _UnsyncedCash();
    try {
      final isar = IsarDatabase.instance.database;
      final ops = await IsarDatabase.instance.getPendingSyncOperations();
      final relevant = ops.where((op) => !op.createdAt.isBefore(since)).toList();

      // Facturas creadas en el equipo: su efectivo ya incluye los pagos que se
      // les agregaron después, así que esos pagos no se cuentan aparte.
      final createdInvoiceIds = relevant
          .where((op) => _isInvoice(op) && op.operationType == SyncOperationType.create)
          .map((op) => op.entityId)
          .toSet();

      for (final invoiceId in createdInvoiceIds) {
        final invoice =
            await isar.isarInvoices.filter().serverIdEqualTo(invoiceId).findFirst();
        if (invoice == null || invoice.deletedAt != null) continue;
        final cash = _cashOfInvoice(invoice);
        if (cash > 0) result.addSale(cash);
      }

      for (final op in relevant) {
        final data = _decode(op.payload);
        final isCash = (data['paymentMethod'] ?? '').toString() == 'cash';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;

        if (_isInvoice(op) &&
            op.operationType == SyncOperationType.update &&
            data['action'] == 'addPayment' &&
            isCash &&
            !createdInvoiceIds.contains(op.entityId)) {
          result.addSale(amount);
        } else if (_isInvoice(op) &&
            op.operationType == SyncOperationType.update &&
            data['action'] == 'addMultiplePayments' &&
            !createdInvoiceIds.contains(op.entityId)) {
          // Pagos con varios métodos: solo cuenta la parte en efectivo.
          final cash = (data['payments'] as List? ?? const [])
              .whereType<Map>()
              .where((p) => (p['paymentMethod'] ?? '').toString() == 'cash')
              .fold<double>(
                  0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));
          if (cash > 0) result.addSale(cash);
        } else if ((op.entityType == 'CustomerCredit' ||
                op.entityType == 'customer_credit') &&
            data['action'] == 'addPayment' &&
            isCash) {
          result.addCreditPayment(amount);
        }
      }

      final expenseIds = relevant
          .where((op) => op.entityType == 'Expense' || op.entityType == 'expense')
          .map((op) => op.entityId)
          .toSet();
      for (final expenseId in expenseIds) {
        final expense =
            await isar.isarExpenses.filter().serverIdEqualTo(expenseId).findFirst();
        if (expense == null || expense.deletedAt != null) continue;
        if (expense.isPaid && expense.paidFromValue == 'cash_register') {
          result.addExpense(expense.amount);
        }
      }
    } catch (e) {
      AppLogger.w('Caja: no se pudo sumar el efectivo sin sincronizar: $e', tag: 'CASH');
    }
    return result;
  }

  bool _isInvoice(SyncOperation op) =>
      op.entityType == 'Invoice' || op.entityType == 'invoice';

  /// Efectivo cobrado en una factura local: sus pagos en efectivo o, si no
  /// tiene el detalle de pagos, lo pagado cuando el método es efectivo.
  double _cashOfInvoice(IsarInvoice invoice) {
    final payments = IsarInvoice.decodePayments(invoice.paymentsJson);
    if (payments.isNotEmpty) {
      return payments
          .where((p) => p.paymentMethod.value == 'cash')
          .fold<double>(0, (sum, p) => sum + p.amount);
    }
    final method = invoice.toEntity().paymentMethod.value;
    return method == 'cash' ? invoice.paidAmount : 0;
  }

  // ==================== COLA ====================

  Future<List<SyncOperation>> _pendingCashRegisterOps() async {
    try {
      final ops = await IsarDatabase.instance.getPendingSyncOperations();
      return ops.where((op) => op.entityType == syncEntityType).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _enqueue(Map<String, dynamic> data) async {
    final auth = _auth;
    final organizationId = auth?.currentUser?.organizationId ?? '';
    if (organizationId.isEmpty) {
      throw StateError('No se pudo identificar la organización');
    }
    await Get.find<SyncService>().addOperation(
      entityType: syncEntityType,
      entityId: syncEntityId,
      operationType: data['action'] == 'open'
          ? SyncOperationType.create
          : SyncOperationType.update,
      data: data,
      organizationId: organizationId,
    );
  }

  /// Rechazo real del servidor (regla de negocio/validación), no una falla
  /// de red: se muestra al usuario en vez de guardar en el equipo.
  bool _isRejection(Object e) {
    if (e is! ServerException) return false;
    final code = e.statusCode;
    return code != null &&
        code >= 400 &&
        code < 500 &&
        code != 401 &&
        code != 408 &&
        code != 429;
  }

  String _message(Object e) => e is AppException ? e.message : e.toString();

  AuthController? get _auth =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  Map<String, dynamic> _decode(String payload) {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  // ==================== ALMACENAMIENTO LOCAL ====================

  Future<void> _writeCache(CashRegisterCurrentStateModel state) async {
    if (secureStorage == null) return;
    try {
      final summary = state.summary;
      final json = <String, dynamic>{
        'cashRegister': state.cashRegister != null
            ? _serializeRegister(state.cashRegister!)
            : null,
        'summary': summary is CashRegisterSummaryModel
            ? summary.toJson()
            : const CashRegisterSummaryModel(
                cashSales: 0,
                cashSalesCount: 0,
                cashExpenses: 0,
                cashExpensesCount: 0,
                cashDeposits: 0,
                cashWithdrawals: 0,
                invoicesCount: 0,
                creditNotesCount: 0,
                creditNotesTotal: 0,
              ).toJson(),
        'expectedAmount': state.expectedAmount,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await secureStorage!.write(_cacheKey, jsonEncode(json));
    } catch (_) {
      // No bloquear flujo por error de cache.
    }
  }

  Future<CashRegisterCurrentStateModel?> _readCache() async {
    if (secureStorage == null) return null;
    try {
      final raw = await secureStorage!.read(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CashRegisterCurrentStateModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _rememberInHistory(CashRegister register) async {
    final cached = await _readHistory();
    final merged = [register, ...cached.where((r) => r.id != register.id)];
    await _writeHistory(merged);
  }

  Future<void> _writeHistory(List<CashRegister> registers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _historyKey,
        jsonEncode(registers.take(100).map(_serializeRegister).toList()),
      );
    } catch (_) {}
  }

  Future<List<CashRegister>> _readHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => CashRegisterModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _serializeRegister(CashRegister r) {
    final summary = r.closingSummary;
    return {
      'id': r.id,
      'status': r.status.value,
      'openingAmount': r.openingAmount,
      'closingExpectedAmount': r.closingExpectedAmount,
      'closingActualAmount': r.closingActualAmount,
      'closingDifference': r.closingDifference,
      'closingSummary':
          summary is CashRegisterSummaryModel ? summary.toJson() : null,
      'openedAt': r.openedAt.toIso8601String(),
      'openedById': r.openedById,
      'openedBy': r.openedByName == null ? null : {'fullName': r.openedByName},
      'closedAt': r.closedAt?.toIso8601String(),
      'closedById': r.closedById,
      'closedBy': r.closedByName == null ? null : {'fullName': r.closedByName},
      'openingNotes': r.openingNotes,
      'closingNotes': r.closingNotes,
      'organizationId': r.organizationId,
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt.toIso8601String(),
      'deletedAt': r.deletedAt?.toIso8601String(),
    };
  }

  /// UUID v4: id de la caja generado en el equipo (apertura sin conexión).
  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Efectivo en la cola que el servidor aún no cuenta.
class _UnsyncedCash {
  double salesCash = 0;
  int salesCount = 0;
  double creditPaymentsCash = 0;
  int creditPaymentsCount = 0;
  double cashOut = 0;
  int cashOutCount = 0;

  double get cashIn => salesCash + creditPaymentsCash;
  int get cashInCount => salesCount + creditPaymentsCount;
  bool get isEmpty => cashIn == 0 && cashOut == 0;

  void addSale(double amount) {
    salesCash += amount;
    salesCount++;
  }

  void addCreditPayment(double amount) {
    creditPaymentsCash += amount;
    creditPaymentsCount++;
  }

  void addExpense(double amount) {
    cashOut += amount;
    cashOutCount++;
  }
}
