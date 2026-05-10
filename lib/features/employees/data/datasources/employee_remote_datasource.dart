import 'package:dio/dio.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/employee_repository.dart';

/// Datasource remoto del módulo de empleados. Mapea 1:1 con el controller
/// `/users` del backend (ya existente, multitenant via interceptor).
abstract class EmployeeRemoteDataSource {
  Future<List<UserModel>> list(EmployeeListFilters filters);
  Future<UserModel> findById(String id);
  Future<UserModel> create({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });
  Future<UserModel> update({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
  });
  Future<UserModel> updateStatus({
    required String id,
    required UserStatus status,
  });
  Future<void> resetPassword({
    required String id,
    required String newPassword,
  });
  Future<void> delete(String id);
  Future<UserModel> restore(String id);
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final DioClient dio;
  EmployeeRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<UserModel>> list(EmployeeListFilters filters) async {
    try {
      final qp = <String, dynamic>{
        'page': filters.page,
        'limit': filters.limit,
      };
      if (filters.search?.isNotEmpty == true) qp['search'] = filters.search;
      if (filters.role != null) qp['role'] = filters.role!.value;
      if (filters.status != null) qp['status'] = filters.status!.value;

      final res = await dio.get('/users', queryParameters: qp);
      final body = res.data;
      // Backend devuelve {success, data: [...], meta}
      final list = (body is Map<String, dynamic>)
          ? (body['data'] as List? ?? [])
          : (body as List? ?? []);
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => UserModel.fromJson(m))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<UserModel> findById(String id) async {
    try {
      final res = await dio.get('/users/$id');
      return UserModel.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<UserModel> create({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role.value,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      final res = await dio.post('/users', data: body);
      return UserModel.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<UserModel> update({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (role != null) body['role'] = role.value;
      final res = await dio.patch('/users/$id', data: body);
      return UserModel.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<UserModel> updateStatus({
    required String id,
    required UserStatus status,
  }) async {
    try {
      final res = await dio.patch(
        '/users/$id/status',
        data: {'status': status.value},
      );
      return UserModel.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<void> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    try {
      await dio.patch(
        '/users/$id/password',
        data: {'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await dio.delete('/users/$id');
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  @override
  Future<UserModel> restore(String id) async {
    try {
      final res = await dio.patch('/users/$id/restore');
      return UserModel.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e));
    }
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>;
      }
      return body;
    }
    return {};
  }

  String _extractMessage(DioException e) {
    final r = e.response;
    if (r != null) {
      final data = r.data;
      if (data is Map<String, dynamic>) {
        final m = data['message'];
        if (m is String) return m;
        if (m is List && m.isNotEmpty) return m.first.toString();
      }
      return 'Error ${r.statusCode}: ${r.statusMessage ?? "desconocido"}';
    }
    return e.message ?? 'Error de red';
  }
}
