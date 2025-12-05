// lib/features/credit_notes/data/repositories/credit_note_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../datasources/credit_note_remote_datasource.dart';
import '../models/credit_note_model.dart';

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  final CreditNoteRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const CreditNoteRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CreditNote>> createCreditNote(
    CreateCreditNoteParams params,
  ) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para crear notas de crédito',
        ),
      );
    }

    try {
      print('📝 CreditNoteRepository: Creando nota de crédito...');
      final request = CreateCreditNoteRequestModel.fromEntity(params);
      final creditNote = await remoteDataSource.createCreditNote(request);
      print('✅ Nota de crédito creada exitosamente');
      return Right(creditNote);
    } catch (e) {
      print('❌ Error al crear nota de crédito: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> getCreditNoteById(String id) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(ConnectionFailure('Se requiere conexión a internet'));
    }

    try {
      print('📄 CreditNoteRepository: Obteniendo nota de crédito $id');
      final creditNote = await remoteDataSource.getCreditNoteById(id);
      return Right(creditNote);
    } catch (e) {
      print('❌ Error al obtener nota de crédito: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<CreditNote>>> getCreditNotes(
    QueryCreditNotesParams params,
  ) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(ConnectionFailure('Se requiere conexión a internet'));
    }

    try {
      print('📄 CreditNoteRepository: Obteniendo notas de crédito...');
      final response = await remoteDataSource.getCreditNotes(params);

      // Convertir a PaginatedResult
      final paginatedResult = PaginatedResult<CreditNote>(
        data: response.data,
        meta: PaginationMeta.fromJson(response.meta),
      );

      print('✅ ${response.data.length} notas de crédito obtenidas');
      return Right(paginatedResult);
    } catch (e) {
      print('❌ Error al obtener notas de crédito: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<CreditNote>>> getCreditNotesByInvoice(
    String invoiceId,
  ) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(ConnectionFailure('Se requiere conexión a internet'));
    }

    try {
      print(
        '📄 CreditNoteRepository: Obteniendo notas de crédito de factura $invoiceId',
      );
      final creditNotes = await remoteDataSource.getCreditNotesByInvoice(
        invoiceId,
      );
      return Right(creditNotes);
    } catch (e) {
      print('❌ Error al obtener notas de crédito de factura: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, double>> getRemainingCreditableAmount(
    String invoiceId,
  ) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(ConnectionFailure('Se requiere conexión a internet'));
    }

    try {
      print(
        '💰 CreditNoteRepository: Obteniendo monto acreditable de factura $invoiceId',
      );
      final amount = await remoteDataSource.getRemainingCreditableAmount(
        invoiceId,
      );
      return Right(amount);
    } catch (e) {
      print('❌ Error al obtener monto acreditable: $e');
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, CreditNote>> updateCreditNote(
    UpdateCreditNoteParams params,
  ) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para actualizar notas de crédito',
        ),
      );
    }

    try {
      print(
        '📝 CreditNoteRepository: Actualizando nota de crédito ${params.id}',
      );
      final request = UpdateCreditNoteRequestModel.fromEntity(params);
      final creditNote = await remoteDataSource.updateCreditNote(
        params.id,
        request,
      );
      print('✅ Nota de crédito actualizada exitosamente');
      return Right(creditNote);
    } catch (e) {
      print('❌ Error al actualizar nota de crédito: $e');
      return Left(_mapExceptionToFailure(e));
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
    if (!(await networkInfo.isConnected)) {
      return const Left(
        ConnectionFailure(
          'Se requiere conexión a internet para eliminar notas de crédito',
        ),
      );
    }

    try {
      print('🗑️ CreditNoteRepository: Eliminando nota de crédito $id');
      await remoteDataSource.deleteCreditNote(id);
      print('✅ Nota de crédito eliminada exitosamente');
      return const Right(null);
    } catch (e) {
      print('❌ Error al eliminar nota de crédito: $e');
      return Left(_mapExceptionToFailure(e));
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
    if (!(await networkInfo.isConnected)) {
      return const Left(ConnectionFailure('Se requiere conexión a internet'));
    }

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
      print('❌ Error al obtener cantidades disponibles: $e');
      return Left(_mapExceptionToFailure(e));
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
}
