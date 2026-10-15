// lib/features/cash_register/data/datasources/cash_register_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../domain/entities/cash_register.dart';
import '../models/cash_register_model.dart';

abstract class CashRegisterRemoteDataSource {
  Future<CashRegisterCurrentStateModel> getCurrent();
  /// [id] y [openedAt] los genera la app: permiten abrir sin conexión y
  /// que el reenvío de la misma apertura no cree otra caja.
  Future<CashRegisterModel> open({
    required double openingAmount,
    String? openingNotes,
    String? id,
    DateTime? openedAt,
  });

  /// [closedAt]: hora real del cierre en el equipo (cierre sin conexión).
  Future<CashRegisterModel> close({
    required String id,
    required double closingActualAmount,
    String? closingNotes,
    DateTime? closedAt,
  });
  Future<CashRegisterModel> findById(String id);
  Future<List<CashRegisterModel>> list({
    CashRegisterStatus? status,
    int limit,
    int offset,
  });
}

class CashRegisterRemoteDataSourceImpl implements CashRegisterRemoteDataSource {
  final DioClient dioClient;

  CashRegisterRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CashRegisterCurrentStateModel> getCurrent() async {
    try {
      final response = await dioClient.get('/cash-register/current');
      final data = _unwrap(response.data);
      return CashRegisterCurrentStateModel.fromJson(data);
    } on DioException catch (e) {
      throw _handle(e);
    }
  }

  @override
  Future<CashRegisterModel> open({
    required double openingAmount,
    String? openingNotes,
    String? id,
    DateTime? openedAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'openingAmount': openingAmount,
        if (openingNotes != null) 'openingNotes': openingNotes,
        if (id != null) 'id': id,
        if (openedAt != null) 'openedAt': openedAt.toUtc().toIso8601String(),
      };
      final response = await dioClient.post('/cash-register/open', data: body);
      final data = _unwrap(response.data);
      return CashRegisterModel.fromJson(data);
    } on DioException catch (e) {
      throw _handle(e);
    }
  }

  @override
  Future<CashRegisterModel> close({
    required String id,
    required double closingActualAmount,
    String? closingNotes,
    DateTime? closedAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'closingActualAmount': closingActualAmount,
        if (closingNotes != null) 'closingNotes': closingNotes,
        if (closedAt != null) 'closedAt': closedAt.toUtc().toIso8601String(),
      };
      final response =
          await dioClient.post('/cash-register/$id/close', data: body);
      final data = _unwrap(response.data);
      return CashRegisterModel.fromJson(data);
    } on DioException catch (e) {
      throw _handle(e);
    }
  }

  @override
  Future<CashRegisterModel> findById(String id) async {
    try {
      final response = await dioClient.get('/cash-register/$id');
      final data = _unwrap(response.data);
      return CashRegisterModel.fromJson(data);
    } on DioException catch (e) {
      throw _handle(e);
    }
  }

  @override
  Future<List<CashRegisterModel>> list({
    CashRegisterStatus? status,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final qp = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (status != null) 'status': status.value,
      };
      final response = await dioClient.get(
        '/cash-register',
        queryParameters: qp,
      );
      final data = _unwrap(response.data);
      final List itemsRaw = data['items'] is List
          ? data['items'] as List
          : const [];
      return itemsRaw
          .whereType<Map>()
          .map((e) => CashRegisterModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _handle(e);
    }
  }

  /// El backend a veces envuelve en {success, data, ...}. Desempaqueta.
  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['success'] == true && raw['data'] is Map) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      return raw;
    }
    return <String, dynamic>{};
  }

  /// Sin respuesta del servidor (sin internet, timeout) → ConnectionException:
  /// la operación se guarda en el equipo y se sincroniza después. Con
  /// respuesta → ServerException con su código, para distinguir un rechazo
  /// real (4xx: p. ej. "ya hay una caja abierta") de una falla del servidor.
  Exception _handle(DioException e) {
    final response = e.response;
    if (response == null) {
      return ConnectionException(e.message ?? 'Sin conexión con el servidor');
    }
    final status = response.statusCode ?? 0;
    final data = response.data;
    final rawMsg = data is Map ? data['message'] : null;
    final msg = rawMsg is List
        ? rawMsg.join(', ')
        : (rawMsg?.toString() ?? e.message ?? 'Error de red');
    if (status >= 500) {
      return ServerException('Error servidor: $msg', statusCode: status);
    }
    return ServerException(msg, statusCode: status);
  }
}
