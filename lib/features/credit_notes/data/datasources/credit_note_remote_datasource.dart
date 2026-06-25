// lib/features/credit_notes/data/datasources/credit_note_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/credit_note_model.dart';
import '../../domain/repositories/credit_note_repository.dart';

abstract class CreditNoteRemoteDataSource {
  Future<CreditNoteModel> createCreditNote(
    CreateCreditNoteRequestModel request,
  );
  Future<CreditNoteModel> getCreditNoteById(String id);
  Future<CreditNotePaginatedResponseModel> getCreditNotes(
    QueryCreditNotesParams params,
  );
  Future<List<CreditNoteModel>> getCreditNotesByInvoice(String invoiceId);
  Future<CreditNoteModel> updateCreditNote(
    String id,
    UpdateCreditNoteRequestModel request,
  );
  Future<CreditNoteModel> confirmCreditNote(String id);
  Future<CreditNoteModel> cancelCreditNote(String id);
  Future<void> deleteCreditNote(String id);
  Future<double> getRemainingCreditableAmount(String invoiceId);
  Future<List<int>> downloadCreditNotePdf(String id);
  Future<AvailableQuantitiesResponseModel> getAvailableQuantitiesForCreditNote(String invoiceId);
}

class CreditNoteRemoteDataSourceImpl implements CreditNoteRemoteDataSource {
  final DioClient dioClient;
  static const String _baseEndpoint = '/credit-notes';

  const CreditNoteRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CreditNoteModel> createCreditNote(
    CreateCreditNoteRequestModel request,
  ) async {
    try {
      final response = await dioClient.post(
        _baseEndpoint,
        data: request.toJson(),
      );

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          // Respuesta envuelta
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          // Respuesta directa (tiene el id de la nota de crédito)
          creditNoteJson = responseData;
        } else {
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException(
          errMsg ?? 'Factura no encontrada',
        );
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          errMsg ?? 'Datos inválidos',
        ]);
      }
      throw ServerException(
        errMsg ?? 'Error al crear nota de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al crear nota de crédito: $e');
    }
  }

  @override
  Future<CreditNoteModel> getCreditNoteById(String id) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/$id');

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          // Respuesta envuelta
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          // Respuesta directa (tiene el id de la nota de crédito)
          creditNoteJson = responseData;
        } else {
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      throw ServerException(
        errMsg ?? 'Error al obtener nota de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener nota de crédito');
    }
  }

  @override
  Future<CreditNotePaginatedResponseModel> getCreditNotes(
    QueryCreditNotesParams params,
  ) async {
    try {
      final response = await dioClient.get(
        _baseEndpoint,
        queryParameters: params.toQueryParameters(),
      );

      return CreditNotePaginatedResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final errData = e.response?.data;
      throw ServerException(
        (errData is Map ? errData['message']?.toString() : errData?.toString()) ?? 'Error al obtener notas de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener notas de crédito');
    }
  }

  @override
  Future<List<CreditNoteModel>> getCreditNotesByInvoice(
    String invoiceId,
  ) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/invoice/$invoiceId');

      // La respuesta viene envuelta en {success: true, data: [...]}
      final responseData = response.data;
      List<dynamic> data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        // Respuesta envuelta: {"success": true, "data": [...]}
        data = responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        // Respuesta directa: [...]
        data = responseData;
      } else {
        return [];
      }

      return data
          .map((json) => CreditNoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura no encontrada');
      }
      throw ServerException(
        errMsg ?? 'Error al obtener notas de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener notas de crédito');
    }
  }

  @override
  Future<CreditNoteModel> updateCreditNote(
    String id,
    UpdateCreditNoteRequestModel request,
  ) async {
    try {
      final response = await dioClient.patch(
        '$_baseEndpoint/$id',
        data: request.toJson(),
      );

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          creditNoteJson = responseData;
        } else {
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          errMsg ?? 'Datos inválidos',
        ]);
      }
      throw ServerException(
        errMsg ?? 'Error al actualizar nota de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al actualizar nota de crédito');
    }
  }

  @override
  Future<CreditNoteModel> confirmCreditNote(String id) async {
    try {
      final response = await dioClient.post('$_baseEndpoint/$id/confirm');

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          creditNoteJson = responseData;
        } else {
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          errMsg ?? 'No se puede confirmar',
        ]);
      }
      throw ServerException(
        errMsg ?? 'Error al confirmar nota de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al confirmar nota de crédito');
    }
  }

  @override
  Future<CreditNoteModel> cancelCreditNote(String id) async {
    try {
      final response = await dioClient.post('$_baseEndpoint/$id/cancel');

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          creditNoteJson = responseData;
        } else {
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          errMsg ?? 'No se puede cancelar',
        ]);
      }
      throw ServerException(
        errMsg ?? 'Error al cancelar nota de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al cancelar nota de crédito');
    }
  }

  @override
  Future<void> deleteCreditNote(String id) async {
    try {
      await dioClient.delete('$_baseEndpoint/$id');
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          errMsg ?? 'No se puede eliminar',
        ]);
      }
      throw ServerException(
        errMsg ?? 'Error al eliminar nota de crédito',
      );
    } catch (e) {
      throw ServerException('Error inesperado al eliminar nota de crédito');
    }
  }

  @override
  Future<double> getRemainingCreditableAmount(String invoiceId) async {
    try {
      final response = await dioClient.get(
        '$_baseEndpoint/invoice/$invoiceId/remaining-creditable',
      );

      // La respuesta viene envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        // Respuesta envuelta: {"success": true, "data": {"invoiceId": "...", "remainingCreditableAmount": 1100}}
        data = responseData['data'] as Map<String, dynamic>;
      } else {
        // Respuesta directa
        data = responseData as Map<String, dynamic>;
      }

      final amount = (data['remainingCreditableAmount'] as num?)?.toDouble() ?? 0.0;
      return amount;
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura no encontrada');
      }
      throw ServerException(
        errMsg ?? 'Error al obtener monto acreditable',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener monto acreditable');
    }
  }

  @override
  Future<List<int>> downloadCreditNotePdf(String id) async {
    try {
      final response = await dioClient.get(
        '$_baseEndpoint/$id/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data as List<int>;
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      throw ServerException(
        errMsg ?? 'Error al descargar PDF',
      );
    } catch (e) {
      throw ServerException('Error inesperado al descargar PDF');
    }
  }

  @override
  Future<AvailableQuantitiesResponseModel> getAvailableQuantitiesForCreditNote(
    String invoiceId,
  ) async {
    try {
      final response = await dioClient.get(
        '$_baseEndpoint/invoice/$invoiceId/available-quantities',
      );

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        // Respuesta envuelta
        data = responseData['data'] as Map<String, dynamic>;
      } else {
        // Respuesta directa
        data = responseData as Map<String, dynamic>;
      }

      return AvailableQuantitiesResponseModel.fromJson(data);
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = (errData is Map ? errData['message']?.toString() : errData?.toString());
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura no encontrada');
      }
      throw ServerException(
        errMsg ?? 'Error al obtener cantidades disponibles',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener cantidades disponibles');
    }
  }
}

// Exception personalizada
class NotFoundException extends ServerException {
  const NotFoundException(super.message) : super(statusCode: 404);
}
