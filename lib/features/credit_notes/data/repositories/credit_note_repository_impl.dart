// lib/features/credit_notes/data/repositories/credit_note_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/core/services/conflict_resolver.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/entities/credit_note_item.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../datasources/credit_note_local_datasource.dart';
import '../datasources/credit_note_remote_datasource.dart';
import '../models/credit_note_model.dart';
import '../models/isar/isar_credit_note.dart';

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  final CreditNoteRemoteDataSource remoteDataSource;
  final CreditNoteLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const CreditNoteRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CreditNote>> createCreditNote(
    CreateCreditNoteParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        print('📝 CreditNoteRepository: Creando nota de crédito...');
        final request = CreateCreditNoteRequestModel.fromEntity(params);
        final creditNote = await remoteDataSource.createCreditNote(request);

        // Cache locally
        try {
          await localDataSource.cacheCreditNote(creditNote);
        } catch (e) {
          print('Error al guardar nota de crédito en cache: $e');
        }

        print('✅ Nota de crédito creada exitosamente');
        return Right(creditNote);
      } on ServerException catch (e) {
        print('⚠️ [CN_REPO] ServerException en create: ${e.message} - Fallback offline...');
        return _createCreditNoteOffline(params);
      } on ConnectionException catch (e) {
        print('⚠️ [CN_REPO] ConnectionException en create: ${e.message} - Fallback offline...');
        return _createCreditNoteOffline(params);
      } catch (e) {
        print('⚠️ [CN_REPO] Exception en create: $e - Fallback offline...');
        return _createCreditNoteOffline(params);
      }
    } else {
      return _createCreditNoteOffline(params);
    }
  }

  @override
  Future<Either<Failure, CreditNote>> getCreditNoteById(String id) async {
    try {
      print('📄 CreditNoteRepository: Obteniendo nota de crédito $id');
      final creditNote = await remoteDataSource.getCreditNoteById(id);

      // ⭐ FASE 1: Resolución de conflictos con ConflictResolver
      CreditNote finalCreditNote = creditNote;
      try {
        // Obtener versión local de ISAR para acceder a campos de versionamiento
        final localIsarCreditNote = await localDataSource.getIsarCreditNote(id);

        if (localIsarCreditNote != null && !localIsarCreditNote.isSynced) {
          // Hay una versión local no sincronizada, verificar conflictos
          print('🔍 Versión local de nota de crédito no sincronizada encontrada, verificando conflictos...');

          // Crear versión ISAR del servidor para comparar
          final serverIsarCreditNote = IsarCreditNote.fromEntity(creditNote);

          // Usar ConflictResolver para detectar y resolver
          final resolver = Get.find<ConflictResolver>();
          final resolution = resolver.resolveConflict<IsarCreditNote>(
            localData: localIsarCreditNote,
            serverData: serverIsarCreditNote,
            strategy: ConflictResolutionStrategy.newerWins,
            hasConflictWith: (local, server) => local.hasConflictWith(server),
            getVersion: (data) => data.version,
            getLastModifiedAt: (data) => data.lastModifiedAt,
          );

          if (resolution.hadConflict) {
            print('⚠️ CONFLICTO DETECTADO Y RESUELTO: ${resolution.message}');
            print('   Estrategia usada: ${resolution.strategy.name}');
            finalCreditNote = resolution.resolvedData.toEntity();
          } else {
            print('✅ No hay conflicto, usando datos del servidor');
          }
        } else if (localIsarCreditNote == null) {
          print('   📝 No hay versión local, usando datos del servidor');
        } else {
          print('   ✅ Versión local ya sincronizada, usando datos del servidor');
        }
      } catch (e) {
        print('⚠️ Error al verificar conflictos: $e');
      }

      // Cache la nota de crédito final (resuelta) locally
      try {
        await localDataSource.cacheCreditNote(CreditNoteModel.fromEntity(finalCreditNote));
      } catch (e) {
        print('⚠️ Error al cachear nota de crédito: $e');
      }

      return Right(finalCreditNote);
    } catch (e) {
      print('⚠️ Error del servidor en getCreditNoteById: $e - intentando cache local...');
      try {
        final cachedCreditNote = await localDataSource.getCachedCreditNote(id);
        if (cachedCreditNote != null) {
          print('✅ Nota de crédito obtenida desde cache local');
          return Right(cachedCreditNote);
        }
        return Left(CacheFailure('No hay nota de crédito con ID $id en cache local'));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<CreditNote>>> getCreditNotes(
    QueryCreditNotesParams params,
  ) async {
    try {
      print('📄 CreditNoteRepository: Obteniendo notas de crédito...');
      final response = await remoteDataSource.getCreditNotes(params);

      // Cache the results if first page and no filters
      if (params.page == 1 && params.search == null && params.status == null) {
        try {
          await localDataSource.cacheCreditNotes(response.data);
        } catch (e) {
          print('⚠️ Error al cachear notas de crédito: $e');
        }
      }

      // Convertir a PaginatedResult
      final paginatedResult = PaginatedResult<CreditNote>(
        data: response.data,
        meta: PaginationMeta.fromJson(response.meta),
      );

      print('✅ ${response.data.length} notas de crédito obtenidas');
      return Right(paginatedResult);
    } catch (e) {
      print('⚠️ Error del servidor en getCreditNotes: $e - intentando cache local...');
      try {
        final cachedCreditNotes = await localDataSource.getCachedCreditNotes();
        if (cachedCreditNotes.isNotEmpty) {
          print('✅ ${cachedCreditNotes.length} notas de crédito obtenidas desde cache local');
          return Right(PaginatedResult<CreditNote>(
            data: cachedCreditNotes,
            meta: PaginationMeta(
              page: 1,
              limit: cachedCreditNotes.length,
              totalItems: cachedCreditNotes.length,
              totalPages: 1,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
          ));
        }
        return Right(PaginatedResult<CreditNote>(
          data: const [],
          meta: PaginationMeta(
            page: 1,
            limit: 0,
            totalItems: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        ));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<CreditNote>>> getCreditNotesByInvoice(
    String invoiceId,
  ) async {
    try {
      print(
        '📄 CreditNoteRepository: Obteniendo notas de crédito de factura $invoiceId',
      );
      final creditNotes = await remoteDataSource.getCreditNotesByInvoice(
        invoiceId,
      );

      // Cache the results
      try {
        await localDataSource.cacheCreditNotes(creditNotes);
      } catch (e) {
        print('⚠️ Error al cachear notas de crédito: $e');
      }

      return Right(creditNotes);
    } catch (e) {
      print('⚠️ Error del servidor en getCreditNotesByInvoice: $e - intentando cache local...');
      try {
        final allCachedCreditNotes = await localDataSource.getCachedCreditNotes();
        final cachedCreditNotes = allCachedCreditNotes.where((cn) => cn.invoiceId == invoiceId).toList();
        if (cachedCreditNotes.isNotEmpty) {
          print('✅ ${cachedCreditNotes.length} notas de crédito de factura obtenidas desde cache local');
        }
        return Right(cachedCreditNotes);
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, double>> getRemainingCreditableAmount(
    String invoiceId,
  ) async {
    try {
      print(
        '💰 CreditNoteRepository: Obteniendo monto acreditable de factura $invoiceId',
      );
      final amount = await remoteDataSource.getRemainingCreditableAmount(
        invoiceId,
      );

      return Right(amount);
    } catch (e) {
      print('⚠️ Error del servidor en getRemainingCreditableAmount: $e');
      return Left(ServerFailure('Error al obtener monto acreditable: $e'));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> updateCreditNote(
    UpdateCreditNoteParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        print(
          '📝 CreditNoteRepository: Actualizando nota de crédito ${params.id}',
        );
        final request = UpdateCreditNoteRequestModel.fromEntity(params);
        final creditNote = await remoteDataSource.updateCreditNote(
          params.id,
          request,
        );

        // Update cache
        try {
          await localDataSource.cacheCreditNote(creditNote);
        } catch (e) {
          print('Error al actualizar nota de crédito en cache: $e');
        }

        print('✅ Nota de crédito actualizada exitosamente');
        return Right(creditNote);
      } on ServerException catch (e) {
        print('⚠️ [CN_REPO] ServerException en update: ${e.message} - Fallback offline...');
        return _updateCreditNoteOffline(params);
      } on ConnectionException catch (e) {
        print('⚠️ [CN_REPO] ConnectionException en update: ${e.message} - Fallback offline...');
        return _updateCreditNoteOffline(params);
      } catch (e) {
        print('⚠️ [CN_REPO] Exception en update: $e - Fallback offline...');
        return _updateCreditNoteOffline(params);
      }
    } else {
      return _updateCreditNoteOffline(params);
    }
  }

  @override
  Future<Either<Failure, CreditNote>> confirmCreditNote(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para confirmar notas de crédito',
        ),
      );
    }

    try {
      print('✅ CreditNoteRepository: Confirmando nota de crédito $id');
      final creditNote = await remoteDataSource.confirmCreditNote(id);
      print('✅ Nota de crédito confirmada exitosamente');
      return Right(creditNote);
    } catch (e) {
      print('❌ Error al confirmar nota de crédito: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> cancelCreditNote(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para cancelar notas de crédito',
        ),
      );
    }

    try {
      print('❌ CreditNoteRepository: Cancelando nota de crédito $id');
      final creditNote = await remoteDataSource.cancelCreditNote(id);
      print('✅ Nota de crédito cancelada exitosamente');
      return Right(creditNote);
    } catch (e) {
      print('❌ Error al cancelar nota de crédito: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCreditNote(String id) async {
    if (await networkInfo.isConnected) {
      try {
        print('🗑️ CreditNoteRepository: Eliminando nota de crédito $id');
        await remoteDataSource.deleteCreditNote(id);

        // Remove from cache
        await localDataSource.removeCachedCreditNote(id);

        print('✅ Nota de crédito eliminada exitosamente');
        return const Right(null);
      } on ServerException catch (e) {
        print('⚠️ [CN_REPO] ServerException en delete: ${e.message} - Fallback offline...');
        return _deleteCreditNoteOffline(id);
      } on ConnectionException catch (e) {
        print('⚠️ [CN_REPO] ConnectionException en delete: ${e.message} - Fallback offline...');
        return _deleteCreditNoteOffline(id);
      } catch (e) {
        print('⚠️ [CN_REPO] Exception en delete: $e - Fallback offline...');
        return _deleteCreditNoteOffline(id);
      }
    } else {
      return _deleteCreditNoteOffline(id);
    }
  }

  @override
  Future<Either<Failure, List<int>>> downloadCreditNotePdf(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure('Se requiere conexión a internet para descargar PDF'),
      );
    }

    try {
      print('📄 CreditNoteRepository: Descargando PDF de nota de crédito $id');
      final pdfBytes = await remoteDataSource.downloadCreditNotePdf(id);
      print('✅ PDF descargado: ${pdfBytes.length} bytes');
      return Right(pdfBytes);
    } catch (e) {
      print('❌ Error al descargar PDF: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> syncCreditNotes() async {
    // Implementación opcional para sincronización offline
    // Por ahora retornamos éxito ya que estamos enfocados en online-first
    return const Right(null);
  }

  @override
  Future<Either<Failure, AvailableQuantitiesResponse>> getAvailableQuantitiesForCreditNote(
    String invoiceId,
  ) async {
    try {
      print(
        '📊 CreditNoteRepository: Obteniendo cantidades disponibles para factura $invoiceId',
      );
      final response = await remoteDataSource.getAvailableQuantitiesForCreditNote(
        invoiceId,
      );

      // Convertir el modelo a entidad de dominio
      final domainResponse = AvailableQuantitiesResponse(
        invoiceId: response.invoiceId,
        invoiceNumber: response.invoiceNumber,
        invoiceTotal: response.invoiceTotal,
        remainingCreditableAmount: response.remainingCreditableAmount,
        totalCreditedAmount: response.totalCreditedAmount,
        totalDraftAmount: response.totalDraftAmount,
        items: response.items.map((item) => AvailableQuantityItem(
          invoiceItemId: item.invoiceItemId,
          productId: item.productId,
          description: item.description,
          unit: item.unit,
          unitPrice: item.unitPrice,
          originalQuantity: item.originalQuantity,
          creditedQuantity: item.creditedQuantity,
          draftQuantity: item.draftQuantity,
          availableQuantity: item.availableQuantity,
          isFullyCredited: item.isFullyCredited,
          hasDraft: item.hasDraft,
          draftCreditNoteNumbers: item.draftCreditNoteNumbers,
        )).toList(),
        draftCreditNotes: response.draftCreditNotes.map((draft) => DraftCreditNoteSummary(
          id: draft.id,
          number: draft.number,
          total: draft.total,
          type: draft.type,
          createdAt: draft.createdAt,
        )).toList(),
        canCreateFullCreditNote: response.canCreateFullCreditNote,
        canCreatePartialCreditNote: response.canCreatePartialCreditNote,
        message: response.message,
      );

      print('✅ Cantidades disponibles obtenidas: ${domainResponse.items.length} items');
      return Right(domainResponse);
    } catch (e) {
      print('⚠️ Error del servidor en getAvailableQuantitiesForCreditNote: $e');
      return Left(ServerFailure('Error al obtener cantidades disponibles: $e'));
    }
  }

  /// Mapear excepciones a failures
  Failure _mapExceptionToFailure(Object exception) {
    if (exception is ServerException) {
      if (exception.statusCode != null) {
        return ServerFailure.fromStatusCode(
          exception.statusCode!,
          exception.message,
        );
      } else {
        return ServerFailure(exception.message);
      }
    } else if (exception is ConnectionException) {
      return ConnectionFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.errors);
    } else {
      return ServerFailure('Error inesperado: ${exception.toString()}');
    }
  }

  // ==================== OFFLINE OPERATIONS ====================

  /// Create credit note offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CreditNote>> _createCreditNoteOffline(
    CreateCreditNoteParams params,
  ) async {
    print('📱 CreditNoteRepository: Creating credit note offline');
    try {
      final now = DateTime.now();
      final tempId = 'cn_offline_${now.millisecondsSinceEpoch}_${params.invoiceId.hashCode}';

      // Calculate totals from items
      double subtotal = 0;
      double taxAmount = 0;
      final taxPercentage = params.taxPercentage ?? 0;

      final List<CreditNoteItem> creditNoteItems = params.items.map((item) {
        final itemSubtotal = (item.quantity * item.unitPrice) - item.discountAmount;
        final itemTaxAmount = itemSubtotal * (taxPercentage / 100);

        subtotal += itemSubtotal;
        taxAmount += itemTaxAmount;

        // CreditNoteItem doesn't have taxPercentage, taxAmount, total, or unitCost
        // Tax is calculated at credit note level, not item level
        return CreditNoteItem(
          id: '',
          productId: item.productId,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discountPercentage: item.discountPercentage,
          discountAmount: item.discountAmount,
          subtotal: itemSubtotal,
          unit: item.unit,
          notes: item.notes,
          creditNoteId: tempId,  // Required field
          invoiceItemId: item.invoiceItemId,
          createdAt: now,  // Required field
          updatedAt: now,  // Required field
        );
      }).toList();

      final total = subtotal + taxAmount;

      // Create temporary credit note entity
      final tempCreditNote = CreditNote(
        id: tempId,
        number: 'TEMP-CN-${now.millisecondsSinceEpoch}',
        date: params.date ?? now,
        type: params.type,
        reason: params.reason,
        reasonDescription: params.reasonDescription,
        status: CreditNoteStatus.draft,
        subtotal: subtotal,
        taxPercentage: taxPercentage,
        taxAmount: taxAmount,
        total: total,
        notes: params.notes,
        terms: params.terms,
        metadata: params.metadata,
        restoreInventory: params.restoreInventory,
        inventoryRestored: false,
        invoiceId: params.invoiceId,
        customerId: '',  // Will be filled from invoice when synced
        createdById: '',  // Will be filled from current user when synced
        items: creditNoteItems,
        createdAt: now,
        updatedAt: now,
      );

      // Cache locally
      await localDataSource.cacheCreditNote(
        CreditNoteModel.fromEntity(tempCreditNote),
      );

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CreditNote',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'invoiceId': params.invoiceId,
            'type': params.type.value,
            'reason': params.reason.value,
            'reasonDescription': params.reasonDescription,
            'date': params.date?.toIso8601String(),
            'notes': params.notes,
            'terms': params.terms,
            'restoreInventory': params.restoreInventory,
            'items': params.items.map((item) => {
              'productId': item.productId,
              'invoiceItemId': item.invoiceItemId,
              'description': item.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discountPercentage': item.discountPercentage,
              'discountAmount': item.discountAmount,
              'unit': item.unit,
              'notes': item.notes,
              'unitCost': item.unitCost,
            }).toList(),
          },
          priority: 1,
        );
        print('📤 CreditNoteRepository: Operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Credit note created offline successfully');
      return Right(tempCreditNote);
    } catch (e) {
      print('❌ Error creating credit note offline: $e');
      return Left(CacheFailure('Error al crear nota de crédito offline: $e'));
    }
  }

  /// Update credit note offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CreditNote>> _updateCreditNoteOffline(
    UpdateCreditNoteParams params,
  ) async {
    print('📱 CreditNoteRepository: Updating credit note offline: ${params.id}');
    try {
      // Get cached credit note
      final cachedCreditNote = await localDataSource.getCachedCreditNote(params.id);
      if (cachedCreditNote == null) {
        return Left(CacheFailure('Nota de crédito no encontrada en cache: ${params.id}'));
      }

      final creditNote = cachedCreditNote;

      // Create updated credit note entity (only allowed fields: reason, reasonDescription, restoreInventory, notes, terms)
      final updatedCreditNote = CreditNote(
        id: params.id,
        number: creditNote.number,
        date: creditNote.date,
        type: creditNote.type,
        reason: params.reason ?? creditNote.reason,
        reasonDescription: params.reasonDescription ?? creditNote.reasonDescription,
        status: creditNote.status,
        subtotal: creditNote.subtotal,
        taxPercentage: creditNote.taxPercentage,
        taxAmount: creditNote.taxAmount,
        total: creditNote.total,
        notes: params.notes ?? creditNote.notes,
        terms: params.terms ?? creditNote.terms,
        metadata: creditNote.metadata,
        restoreInventory: params.restoreInventory ?? creditNote.restoreInventory,
        inventoryRestored: creditNote.inventoryRestored,
        inventoryRestoredAt: creditNote.inventoryRestoredAt,
        appliedAt: creditNote.appliedAt,
        appliedById: creditNote.appliedById,
        appliedBy: creditNote.appliedBy,
        invoiceId: creditNote.invoiceId,
        invoice: creditNote.invoice,
        customerId: creditNote.customerId,
        customer: creditNote.customer,
        createdById: creditNote.createdById,
        createdBy: creditNote.createdBy,
        items: creditNote.items,
        createdAt: creditNote.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: creditNote.deletedAt,
      );

      // Update cache
      await localDataSource.cacheCreditNote(
        CreditNoteModel.fromEntity(updatedCreditNote),
      );

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CreditNote',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: {
            'reason': params.reason?.value,
            'reasonDescription': params.reasonDescription,
            'notes': params.notes,
            'terms': params.terms,
            'restoreInventory': params.restoreInventory,
          },
          priority: 1,
        );
        print('📤 Update operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Credit note updated offline successfully');
      return Right(updatedCreditNote);
    } catch (e) {
      print('❌ Error updating credit note offline: $e');
      return Left(CacheFailure('Error al actualizar nota de crédito offline: $e'));
    }
  }

  /// Delete credit note offline (used as fallback when server fails or no connection)
  Future<Either<Failure, void>> _deleteCreditNoteOffline(String id) async {
    print('📱 CreditNoteRepository: Deleting credit note offline: $id');
    try {
      // Remove from cache
      await localDataSource.removeCachedCreditNote(id);

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CreditNote',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 Delete operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Credit note deleted offline successfully');
      return const Right(null);
    } catch (e) {
      print('❌ Error deleting credit note offline: $e');
      return Left(CacheFailure('Error al eliminar nota de crédito offline: $e'));
    }
  }
}
