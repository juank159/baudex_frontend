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
      print('📝 CreditNoteRemoteDataSource: Creando nota de crédito...');
      final response = await dioClient.post(
        _baseEndpoint,
        data: request.toJson(),
      );

      print('✅ Nota de crédito creada - Response type: ${response.data.runtimeType}');

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          // Respuesta envuelta
          print('📦 Respuesta envuelta detectada');
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          // Respuesta directa (tiene el id de la nota de crédito)
          print('📦 Respuesta directa detectada');
          creditNoteJson = responseData;
        } else {
          print('⚠️ Formato de respuesta inesperado: $responseData');
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        print('⚠️ Respuesta no es un Map: ${responseData.runtimeType}');
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      print('📋 Parseando nota de crédito: ${creditNoteJson['number']}');
      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      print('❌ Error Dio al crear nota de crédito: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        throw NotFoundException(
          e.response?.data['message'] ?? 'Factura no encontrada',
        );
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          e.response?.data['message'] ?? 'Datos inválidos',
        ]);
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al crear nota de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al crear nota de crédito: $e');
      throw ServerException('Error inesperado al crear nota de crédito: $e');
    }
  }

  @override
  Future<CreditNoteModel> getCreditNoteById(String id) async {
    try {
      print('📄 CreditNoteRemoteDataSource: Obteniendo nota de crédito $id');
      final response = await dioClient.get('$_baseEndpoint/$id');

      // La respuesta puede venir envuelta en {success: true, data: {...}}
      final responseData = response.data;
      Map<String, dynamic> creditNoteJson;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          // Respuesta envuelta
          print('📦 Respuesta envuelta detectada');
          creditNoteJson = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('id')) {
          // Respuesta directa (tiene el id de la nota de crédito)
          print('📦 Respuesta directa detectada');
          creditNoteJson = responseData;
        } else {
          print('⚠️ Formato de respuesta inesperado: ${responseData.keys}');
          throw ServerException('Formato de respuesta inesperado del servidor');
        }
      } else {
        print('⚠️ Respuesta no es un Map: ${responseData.runtimeType}');
        throw ServerException('Formato de respuesta inesperado del servidor');
      }

      print('📋 Parseando nota de crédito: ${creditNoteJson['number']}');
      return CreditNoteModel.fromJson(creditNoteJson);
    } on DioException catch (e) {
      print(
        '❌ Error Dio al obtener nota de crédito: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener nota de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al obtener nota de crédito: $e');
      throw ServerException('Error inesperado al obtener nota de crédito');
    }
  }

  @override
  Future<CreditNotePaginatedResponseModel> getCreditNotes(
    QueryCreditNotesParams params,
  ) async {
    try {
      print('📄 CreditNoteRemoteDataSource: Obteniendo notas de crédito...');
      final response = await dioClient.get(
        _baseEndpoint,
        queryParameters: params.toQueryParameters(),
      );

      print('✅ Notas de crédito obtenidas: ${response.data['data'].length}');
      return CreditNotePaginatedResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      print(
        '❌ Error Dio al obtener notas de crédito: ${e.response?.statusCode}',
      );
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener notas de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al obtener notas de crédito: $e');
      throw ServerException('Error inesperado al obtener notas de crédito');
    }
  }

  @override
  Future<List<CreditNoteModel>> getCreditNotesByInvoice(
    String invoiceId,
  ) async {
    try {
      print(
        '📄 CreditNoteRemoteDataSource: Obteniendo notas de crédito de factura $invoiceId',
      );
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
        print('⚠️ Formato de respuesta inesperado: ${responseData.runtimeType}');
        return [];
      }

      print('✅ Notas de crédito de factura obtenidas: ${data.length}');
      return data
          .map((json) => CreditNoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print(
        '❌ Error Dio al obtener notas de crédito de factura: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura no encontrada');
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener notas de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al obtener notas de crédito de factura: $e');
      throw ServerException('Error inesperado al obtener notas de crédito');
    }
  }

  @override
  Future<CreditNoteModel> updateCreditNote(
    String id,
    UpdateCreditNoteRequestModel request,
  ) async {
    try {
      print('📝 CreditNoteRemoteDataSource: Actualizando nota de crédito $id');
      final response = await dioClient.patch(
        '$_baseEndpoint/$id',
        data: request.toJson(),
      );

      print('✅ Nota de crédito actualizada');

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
      print(
        '❌ Error Dio al actualizar nota de crédito: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          e.response?.data['message'] ?? 'Datos inválidos',
        ]);
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al actualizar nota de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al actualizar nota de crédito: $e');
      throw ServerException('Error inesperado al actualizar nota de crédito');
    }
  }

  @override
  Future<CreditNoteModel> confirmCreditNote(String id) async {
    try {
      print('✅ CreditNoteRemoteDataSource: Confirmando nota de crédito $id');
      final response = await dioClient.post('$_baseEndpoint/$id/confirm');

      print('✅ Nota de crédito confirmada');

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
      print(
        '❌ Error Dio al confirmar nota de crédito: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          e.response?.data['message'] ?? 'No se puede confirmar',
        ]);
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al confirmar nota de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al confirmar nota de crédito: $e');
      throw ServerException('Error inesperado al confirmar nota de crédito');
    }
  }

  @override
  Future<CreditNoteModel> cancelCreditNote(String id) async {
    try {
      print('❌ CreditNoteRemoteDataSource: Cancelando nota de crédito $id');
      final response = await dioClient.post('$_baseEndpoint/$id/cancel');

      print('✅ Nota de crédito cancelada');

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
      print(
        '❌ Error Dio al cancelar nota de crédito: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          e.response?.data['message'] ?? 'No se puede cancelar',
        ]);
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al cancelar nota de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al cancelar nota de crédito: $e');
      throw ServerException('Error inesperado al cancelar nota de crédito');
    }
  }

  @override
  Future<void> deleteCreditNote(String id) async {
    try {
      print('🗑️ CreditNoteRemoteDataSource: Eliminando nota de crédito $id');
      await dioClient.delete('$_baseEndpoint/$id');
      print('✅ Nota de crédito eliminada');
    } on DioException catch (e) {
      print(
        '❌ Error Dio al eliminar nota de crédito: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      if (e.response?.statusCode == 400) {
        throw ValidationException([
          e.response?.data['message'] ?? 'No se puede eliminar',
        ]);
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al eliminar nota de crédito',
      );
    } catch (e) {
      print('❌ Error inesperado al eliminar nota de crédito: $e');
      throw ServerException('Error inesperado al eliminar nota de crédito');
    }
  }

  @override
  Future<double> getRemainingCreditableAmount(String invoiceId) async {
    try {
      print(
        '💰 CreditNoteRemoteDataSource: Obteniendo monto acreditable de factura $invoiceId',
      );
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
      print('✅ Monto acreditable: $amount');
      return amount;
    } on DioException catch (e) {
      print(
        '❌ Error Dio al obtener monto acreditable: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura no encontrada');
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener monto acreditable',
      );
    } catch (e) {
      print('❌ Error inesperado al obtener monto acreditable: $e');
      throw ServerException('Error inesperado al obtener monto acreditable');
    }
  }

  @override
  Future<List<int>> downloadCreditNotePdf(String id) async {
    try {
      print(
        '📄 CreditNoteRemoteDataSource: Descargando PDF de nota de crédito $id',
      );
      final response = await dioClient.get(
        '$_baseEndpoint/$id/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      print('✅ PDF descargado: ${response.data.length} bytes');
      return response.data as List<int>;
    } on DioException catch (e) {
      print('❌ Error Dio al descargar PDF: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Nota de crédito no encontrada');
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al descargar PDF',
      );
    } catch (e) {
      print('❌ Error inesperado al descargar PDF: $e');
      throw ServerException('Error inesperado al descargar PDF');
    }
  }

  @override
  Future<AvailableQuantitiesResponseModel> getAvailableQuantitiesForCreditNote(
    String invoiceId,
  ) async {
    try {
      print(
        '📊 CreditNoteRemoteDataSource: Obteniendo cantidades disponibles para factura $invoiceId',
      );
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

      print('✅ Cantidades disponibles obtenidas: ${data['items']?.length ?? 0} items');
      return AvailableQuantitiesResponseModel.fromJson(data);
    } on DioException catch (e) {
      print(
        '❌ Error Dio al obtener cantidades disponibles: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura no encontrada');
      }
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener cantidades disponibles',
      );
    } catch (e) {
      print('❌ Error inesperado al obtener cantidades disponibles: $e');
      throw ServerException('Error inesperado al obtener cantidades disponibles');
    }
  }
}

// Exception personalizada
class NotFoundException extends ServerException {
  const NotFoundException(super.message) : super(statusCode: 404);
}
