// lib/features/cash_register/data/datasources/cash_register_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../domain/entities/cash_register.dart';
import '../models/cash_register_model.dart';

abstract class CashRegisterRemoteDataSource {
  Future<CashRegisterCurrentStateModel> getCurrent();
  Future<CashRegisterModel> open({
    required double openingAmount,
    String? openingNotes,
  });
  Future<CashRegisterModel> close({
    required String id,
    required double closingActualAmount,
    String? closingNotes,
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
  }) async {
    try {
      final body = <String, dynamic>{
        'openingAmount': openingAmount,
        if (openingNotes != null) 'openingNotes': openingNotes,
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
  }) async {
    try {
      final body = <String, dynamic>{
        'closingActualAmount': closingActualAmount,
        if (closingNotes != null) 'closingNotes': closingNotes,
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

  Exception _handle(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final msg = (e.response?.data is Map &&
            (e.response?.data as Map)['message'] != null)
        ? (e.response?.data as Map)['message'].toString()
        : (e.message ?? 'Error de red');
    if (status >= 500) return ServerException('Error servidor: $msg');
    return ServerException(msg);
  }
}
