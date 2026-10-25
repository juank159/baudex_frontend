// lib/features/credit_notes/data/repositories/credit_note_offline_repository.dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../models/isar/isar_credit_note.dart';
import '../credit_note_local_effects.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';

/// Implementación offline del repositorio de notas de crédito usando ISAR
///
/// Proporciona todas las operaciones CRUD para notas de crédito de forma offline-first
class CreditNoteOfflineRepository implements CreditNoteRepository {
  final IsarDatabase _database;

  CreditNoteOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<CreditNote>>> getCreditNotes(
    QueryCreditNotesParams params,
  ) async {
    try {
      var query = _isar.isarCreditNotes.filter().deletedAtIsNull();

      // Apply search filter
      if (params.search != null && params.search!.isNotEmpty) {
        query = query.and().numberContains(params.search!, caseSensitive: false);
      }

      // Apply status filter
      if (params.status != null) {
        final isarStatus = _mapCreditNoteStatus(params.status!);
        query = query.and().statusEqualTo(isarStatus);
      }

      // Apply type filter
      if (params.type != null) {
        final isarType = _mapCreditNoteType(params.type!);
        query = query.and().typeEqualTo(isarType);
      }

      // Apply reason filter
      if (params.reason != null) {
        final isarReason = _mapCreditNoteReason(params.reason!);
        query = query.and().reasonEqualTo(isarReason);
      }

      // Apply invoice filter
      if (params.invoiceId != null) {
        query = query.and().invoiceIdEqualTo(params.invoiceId!);
      }

      // Apply customer filter
      if (params.customerId != null) {
        query = query.and().customerIdEqualTo(params.customerId!);
      }

      // Apply date range filters
      if (params.startDate != null) {
        query = query.and().dateGreaterThan(params.startDate!, include: true);
      }
      if (params.endDate != null) {
        query = query.and().dateLessThan(params.endDate!, include: true);
      }

      // Obtener todos los resultados
      final allResults = await query.findAll() as List<IsarCreditNote>;
      final totalItems = allResults.length;

      // Apply amount filters in Dart
      var filteredResults = allResults;
      if (params.minAmount != null) {
        filteredResults = filteredResults.where((cn) => cn.total >= params.minAmount!).toList();
      }
      if (params.maxAmount != null) {
        filteredResults = filteredResults.where((cn) => cn.total <= params.maxAmount!).toList();
      }

      // Ordenar en Dart
      filteredResults.sort((a, b) {
        int comparison = 0;
        switch (params.sortBy) {
          case 'number':
            comparison = a.number.compareTo(b.number);
            break;
          case 'total':
            comparison = a.total.compareTo(b.total);
            break;
          case 'date':
            comparison = a.date.compareTo(b.date);
            break;
          case 'createdAt':
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }
        return params.sortOrder.toUpperCase() == 'DESC' ? -comparison : comparison;
      });

      // Paginar manualmente
      final offset = (params.page - 1) * params.limit;
      final start = offset.clamp(0, filteredResults.length);
      final end = (start + params.limit).clamp(0, filteredResults.length);
      final pagedResults = filteredResults.sublist(start, end);

      final creditNotes = pagedResults.map((isar) => isar.toEntity()).toList();

      final totalPages = (totalItems / params.limit).ceil();
      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      return Right(PaginatedResult(data: creditNotes, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading credit notes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> getCreditNoteById(String id) async {
    try {
      final isarCreditNote = await _isar.isarCreditNotes
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCreditNote == null) {
        return Left(CacheFailure('Credit note not found'));
      }

      return Right(isarCreditNote.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading credit note: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CreditNote>>> getCreditNotesByInvoice(
    String invoiceId,
  ) async {
    try {
      final isarCreditNotes = await _isar.isarCreditNotes
          .filter()
          .invoiceIdEqualTo(invoiceId)
          .and()
          .deletedAtIsNull()
          .sortByDateDesc()
          .findAll() as List<IsarCreditNote>;

      final creditNotes = isarCreditNotes.map((isar) => isar.toEntity()).toList();
      return Right(creditNotes);
    } catch (e) {
      return Left(CacheFailure('Error loading credit notes by invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getRemainingCreditableAmount(
    String invoiceId,
  ) async {
    try {
      // Total de la factura guardada en el equipo. Si no está, se responde
      // error para que se le pregunte al servidor (nunca un valor inventado).
      final invoice = await _isar.isarInvoices
          .filter()
          .serverIdEqualTo(invoiceId)
          .findFirst();
      if (invoice == null) {
        return Left(CacheFailure('Factura $invoiceId no está en el equipo'));
      }

      // Obtener todas las notas de crédito para esta factura
      final creditNotesResult = await getCreditNotesByInvoice(invoiceId);

      return creditNotesResult.fold(
        (failure) => Left(failure),
        (creditNotes) {
          // Sumar el total de todas las notas de crédito confirmadas
          final totalCredited = creditNotes
              .where((cn) => cn.status == CreditNoteStatus.confirmed)
              .fold<double>(0, (sum, cn) => sum + cn.total);

          // Igual que el servidor: total de la factura - notas confirmadas.
          final remaining = invoice.total - totalCredited;
          return Right(remaining > 0 ? remaining : 0.0);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Error calculating remaining creditable amount: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AvailableQuantitiesResponse>> getAvailableQuantitiesForCreditNote(
    String invoiceId,
  ) async {
    // Este repositorio no calcula cantidades disponibles: lo hace
    // CreditNoteRepositoryImpl (servidor o base del equipo). Responder error
    // y NUNCA una respuesta vacía que parezca real (bloqueaba las notas).
    return Left(CacheFailure(
      'Cantidades disponibles de $invoiceId: usar CreditNoteRepositoryImpl',
    ));
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, CreditNote>> createCreditNote(
    CreateCreditNoteParams params,
  ) async {
    try {
      final now = DateTime.now();
      final serverId = 'creditnote_offline_${now.millisecondsSinceEpoch}_${params.invoiceId.hashCode}';
      final number = 'NC-OFFLINE-${now.millisecondsSinceEpoch.toString().substring(7)}';

      // Totales igual que el servidor: el precio ya incluye el IVA de la
      // factura; total = Σ(cantidad × precio − descuento) y de ahí se separa
      // el IVA. (Antes se sumaba un 19% encima y el total no cuadraba.)
      final invoiceForTax = await _isar.isarInvoices
          .filter()
          .serverIdEqualTo(params.invoiceId)
          .findFirst();
      final taxPercentage =
          invoiceForTax?.taxPercentage ?? params.taxPercentage ?? 0;
      double total = 0;
      for (final item in params.items) {
        total += item.quantity * item.unitPrice - item.discountAmount;
      }
      total = (total * 100).roundToDouble() / 100;
      final subtotal =
          ((total / (1 + taxPercentage / 100)) * 100).roundToDouble() / 100;
      final taxAmount = ((total - subtotal) * 100).roundToDouble() / 100;

      // Serializar items a JSON
      final itemsJson = jsonEncode(params.items.map((item) => {
        'id': 'item_${now.millisecondsSinceEpoch}_${item.description.hashCode}',
        'description': item.description,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'discountPercentage': item.discountPercentage,
        'discountAmount': item.discountAmount,
        'subtotal': item.quantity * item.unitPrice - item.discountAmount,
        'unit': item.unit,
        'notes': item.notes,
        'creditNoteId': serverId,
        'productId': item.productId,
        'invoiceItemId': item.invoiceItemId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }).toList());

      final isarCreditNote = IsarCreditNote.create(
        serverId: serverId,
        number: number,
        date: params.date ?? now,
        type: _mapCreditNoteType(params.type),
        reason: _mapCreditNoteReason(params.reason),
        reasonDescription: params.reasonDescription,
        status: IsarCreditNoteStatus.draft,
        subtotal: subtotal,
        taxPercentage: taxPercentage,
        taxAmount: taxAmount,
        total: total,
        notes: params.notes,
        terms: params.terms,
        metadataJson: params.metadata != null ? jsonEncode(params.metadata) : null,
        restoreInventory: params.restoreInventory,
        inventoryRestored: false,
        invoiceId: params.invoiceId,
        customerId: '', // Se obtiene de la factura en el servidor
        createdById: 'offline',
        itemsJson: itemsJson,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _isar.writeTxn(() async {
        await _isar.isarCreditNotes.put(isarCreditNote);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CreditNote',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'invoiceId': params.invoiceId,
            'type': params.type.value,
            'reason': params.reason.value,
            'reasonDescription': params.reasonDescription,
            'date': params.date?.toIso8601String(),
            'items': params.items.map((item) => {
              'invoiceItemId': item.invoiceItemId,
              'productId': item.productId,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'description': item.description,
              'discountPercentage': item.discountPercentage,
              'discountAmount': item.discountAmount,
              'unit': item.unit,
              'unitCost': item.unitCost,
              'notes': item.notes,
            }).toList(),
            'restoreInventory': params.restoreInventory,
            'notes': params.notes,
            'terms': params.terms,
          },
        );
      } catch (e) {
        // Sin la operación en la cola la nota nunca llegaría al servidor:
        // se quita del equipo y se avisa (no se devolvió inventario aún).
        await _isar.writeTxn(() async {
          await _isar.isarCreditNotes.delete(isarCreditNote.id);
        });
        return Left(CacheFailure(
          'No se pudo guardar la nota crédito para sincronizar. No se creó: $e',
        ));
      }

      // Con devolución de inventario la nota se aplica de una vez (igual que
      // con internet, donde se confirma al crearla; al sincronizar el
      // servidor la confirma). Sin devolución queda en borrador.
      if (params.restoreInventory) {
        final units = await CreditNoteLocalEffects.baseUnitsByProduct(
          _isar,
          params.invoiceId,
          [
            for (final item in params.items)
              CreditNoteLine(
                productId: item.productId,
                invoiceItemId: item.invoiceItemId,
                quantity: item.quantity,
              ),
          ],
        );
        await CreditNoteLocalEffects.restoreInventory(
          _isar,
          units,
          markUnsynced: true,
          modifiedBy: 'offline_credit_note',
        );
        isarCreditNote.status = IsarCreditNoteStatus.confirmed;
        isarCreditNote.inventoryRestored = true;
        isarCreditNote.inventoryRestoredAt = now;
        isarCreditNote.appliedAt = now;
        await _isar.writeTxn(() async {
          await _isar.isarCreditNotes.put(isarCreditNote);
        });
        await CreditNoteLocalEffects.applyInvoiceStatus(_isar, params.invoiceId);
      }

      return Right(isarCreditNote.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating credit note: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> updateCreditNote(
    UpdateCreditNoteParams params,
  ) async {
    try {
      final isarCreditNote = await _isar.isarCreditNotes
          .filter()
          .serverIdEqualTo(params.id)
          .findFirst();

      if (isarCreditNote == null) {
        return Left(CacheFailure('Credit note not found'));
      }

      // Solo se pueden actualizar notas en estado draft
      if (isarCreditNote.status != IsarCreditNoteStatus.draft) {
        return Left(CacheFailure('Only draft credit notes can be updated'));
      }

      // Update fields
      if (params.reason != null) {
        isarCreditNote.reason = _mapCreditNoteReason(params.reason!);
      }
      if (params.reasonDescription != null) {
        isarCreditNote.reasonDescription = params.reasonDescription;
      }
      if (params.restoreInventory != null) {
        isarCreditNote.restoreInventory = params.restoreInventory!;
      }
      if (params.notes != null) {
        isarCreditNote.notes = params.notes;
      }
      if (params.terms != null) {
        isarCreditNote.terms = params.terms;
      }

      isarCreditNote.updatedAt = DateTime.now();
      isarCreditNote.isSynced = false;
      isarCreditNote.incrementVersion();

      await _isar.writeTxn(() async {
        await _isar.isarCreditNotes.put(isarCreditNote);
      });

      // Add to sync queue (solo si no es offline)
      if (!params.id.startsWith('creditnote_offline_')) {
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'CreditNote',
            entityId: params.id,
            operationType: SyncOperationType.update,
            data: {
              'reason': params.reason?.value,
              'reasonDescription': params.reasonDescription,
              'restoreInventory': params.restoreInventory,
              'notes': params.notes,
              'terms': params.terms,
            },
          );
        } catch (e) {
          // Log pero no fallar
        }
      }

      return Right(isarCreditNote.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating credit note: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> confirmCreditNote(String id) async {
    try {
      final isarCreditNote = await _isar.isarCreditNotes
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCreditNote == null) {
        return Left(CacheFailure('Nota crédito no encontrada en el equipo'));
      }
      if (isarCreditNote.status != IsarCreditNoteStatus.draft) {
        return Left(ServerFailure(
          'Solo se pueden confirmar notas de crédito en borrador',
        ));
      }

      final lines = [
        for (final item in isarCreditNote.toEntity().items)
          CreditNoteLine(
            productId: item.productId,
            invoiceItemId: item.invoiceItemId,
            quantity: item.quantity,
          ),
      ];
      final restores =
          isarCreditNote.restoreInventory && !isarCreditNote.inventoryRestored;

      // Primero a la cola: si no se puede, no se toca nada.
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CreditNote',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            'action': 'confirm',
            // Productos que esta nota devuelve: la descarga no los pisa
            // hasta que el servidor la confirme.
            'items': [
              for (final l in lines)
                if (l.productId != null) {'productId': l.productId},
            ],
          },
        );
      } catch (e) {
        return Left(CacheFailure(
          'No se pudo guardar la confirmación para sincronizar. No se confirmó: $e',
        ));
      }

      final now = DateTime.now();
      if (restores) {
        final units = await CreditNoteLocalEffects.baseUnitsByProduct(
          _isar,
          isarCreditNote.invoiceId,
          lines,
        );
        await CreditNoteLocalEffects.restoreInventory(
          _isar,
          units,
          markUnsynced: true,
          modifiedBy: 'offline_credit_note',
        );
        isarCreditNote.inventoryRestored = true;
        isarCreditNote.inventoryRestoredAt = now;
      }
      isarCreditNote.status = IsarCreditNoteStatus.confirmed;
      isarCreditNote.appliedAt = now;
      isarCreditNote.updatedAt = now;
      isarCreditNote.isSynced = false;
      isarCreditNote.incrementVersion();
      await _isar.writeTxn(() async {
        await _isar.isarCreditNotes.put(isarCreditNote);
      });
      await CreditNoteLocalEffects.applyInvoiceStatus(_isar, isarCreditNote.invoiceId);

      return Right(isarCreditNote.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error al confirmar la nota crédito sin conexión: $e'));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> cancelCreditNote(String id) async {
    try {
      final isarCreditNote = await _isar.isarCreditNotes
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCreditNote == null) {
        return Left(CacheFailure('Nota crédito no encontrada en el equipo'));
      }
      if (isarCreditNote.status != IsarCreditNoteStatus.draft) {
        return Left(ServerFailure(
          'Solo se pueden cancelar notas de crédito en borrador',
        ));
      }

      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CreditNote',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'action': 'cancel'},
        );
      } catch (e) {
        return Left(CacheFailure(
          'No se pudo guardar la cancelación para sincronizar. No se canceló: $e',
        ));
      }

      isarCreditNote.status = IsarCreditNoteStatus.cancelled;
      isarCreditNote.updatedAt = DateTime.now();
      isarCreditNote.isSynced = false;
      isarCreditNote.incrementVersion();

      await _isar.writeTxn(() async {
        await _isar.isarCreditNotes.put(isarCreditNote);
      });

      return Right(isarCreditNote.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error al cancelar la nota crédito sin conexión: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCreditNote(String id) async {
    try {
      final isarCreditNote = await _isar.isarCreditNotes
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCreditNote == null) {
        return Left(CacheFailure('Credit note not found'));
      }

      // Soft delete
      isarCreditNote.deletedAt = DateTime.now();
      isarCreditNote.isSynced = false;
      isarCreditNote.incrementVersion();

      await _isar.writeTxn(() async {
        await _isar.isarCreditNotes.put(isarCreditNote);
      });

      // Add to sync queue (solo si no es offline)
      if (!id.startsWith('creditnote_offline_')) {
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'CreditNote',
            entityId: id,
            operationType: SyncOperationType.delete,
            data: {'deleted': true},
          );
        } catch (e) {
          // Log pero no fallar
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting credit note: ${e.toString()}'));
    }
  }

  // ==================== PDF OPERATIONS ====================

  @override
  Future<Either<Failure, List<int>>> downloadCreditNotePdf(String id) async {
    // PDF requiere conexión al servidor
    return Left(CacheFailure('PDF generation requires server connection'));
  }

  // ==================== SYNC OPERATIONS ====================

  @override
  Future<Either<Failure, void>> syncCreditNotes() async {
    // Sync es manejado por SyncService
    return const Right(null);
  }

  /// Get credit notes that need to be synced with the server
  Future<Either<Failure, List<CreditNote>>> getUnsyncedCreditNotes() async {
    try {
      final isarCreditNotes = await _isar.isarCreditNotes
          .filter()
          .isSyncedEqualTo(false)
          .findAll() as List<IsarCreditNote>;

      final creditNotes = isarCreditNotes.map((isar) => isar.toEntity()).toList();
      return Right(creditNotes);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced credit notes: ${e.toString()}'));
    }
  }

  /// Mark credit notes as synced after successful server sync
  Future<Either<Failure, Unit>> markCreditNotesAsSynced(List<String> ids) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in ids) {
          final isarCreditNote = await _isar.isarCreditNotes
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarCreditNote != null) {
            isarCreditNote.isSynced = true;
            isarCreditNote.lastSyncAt = DateTime.now();
            await _isar.isarCreditNotes.put(isarCreditNote);
          }
        }
      });

      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error marking credit notes as synced: ${e.toString()}'));
    }
  }

  // ==================== CACHE OPERATIONS ====================

  /// Get all cached credit notes
  Future<Either<Failure, List<CreditNote>>> getCachedCreditNotes() async {
    try {
      final isarCreditNotes = await _isar.isarCreditNotes
          .filter()
          .deletedAtIsNull()
          .sortByDateDesc()
          .findAll() as List<IsarCreditNote>;

      final creditNotes = isarCreditNotes.map((isar) => isar.toEntity()).toList();
      return Right(creditNotes);
    } catch (e) {
      return Left(CacheFailure('Error loading cached credit notes: ${e.toString()}'));
    }
  }

  /// Clear all cached credit notes
  Future<Either<Failure, Unit>> clearCreditNoteCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarCreditNotes.clear();
      });

      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error clearing credit note cache: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  static IsarCreditNoteStatus _mapCreditNoteStatus(CreditNoteStatus status) {
    switch (status) {
      case CreditNoteStatus.draft:
        return IsarCreditNoteStatus.draft;
      case CreditNoteStatus.confirmed:
        return IsarCreditNoteStatus.confirmed;
      case CreditNoteStatus.cancelled:
        return IsarCreditNoteStatus.cancelled;
    }
  }

  static IsarCreditNoteType _mapCreditNoteType(CreditNoteType type) {
    switch (type) {
      case CreditNoteType.full:
        return IsarCreditNoteType.full;
      case CreditNoteType.partial:
        return IsarCreditNoteType.partial;
    }
  }

  static IsarCreditNoteReason _mapCreditNoteReason(CreditNoteReason reason) {
    switch (reason) {
      case CreditNoteReason.returnedGoods:
        return IsarCreditNoteReason.returnedGoods;
      case CreditNoteReason.damagedGoods:
        return IsarCreditNoteReason.damagedGoods;
      case CreditNoteReason.billingError:
        return IsarCreditNoteReason.billingError;
      case CreditNoteReason.priceAdjustment:
        return IsarCreditNoteReason.priceAdjustment;
      case CreditNoteReason.orderCancellation:
        return IsarCreditNoteReason.orderCancellation;
      case CreditNoteReason.customerDissatisfaction:
        return IsarCreditNoteReason.customerDissatisfaction;
      case CreditNoteReason.inventoryAdjustment:
        return IsarCreditNoteReason.inventoryAdjustment;
      case CreditNoteReason.discountGranted:
        return IsarCreditNoteReason.discountGranted;
      case CreditNoteReason.other:
        return IsarCreditNoteReason.other;
    }
  }
}
