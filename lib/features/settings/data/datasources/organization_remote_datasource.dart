// lib/features/settings/data/datasources/organization_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/organization_model.dart';
import '../models/create_organization_request_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> getCurrentOrganization();
  Future<List<OrganizationModel>> getAllOrganizations();
  Future<OrganizationModel> createOrganization(CreateOrganizationRequestModel request);
  Future<OrganizationModel> updateOrganization(String id, Map<String, dynamic> updates);
  Future<void> deleteOrganization(String id);
  Future<OrganizationModel> getOrganizationById(String id);
}

class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final DioClient dioClient;

  OrganizationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<OrganizationModel> getCurrentOrganization() async {
    try {
      final response = await dioClient.get(
        '/organizations/current',
      );

      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener organización actual',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener organización actual: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<OrganizationModel>> getAllOrganizations() async {
    try {
      final response = await dioClient.get(
        '/organizations',
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((item) => OrganizationModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener organizaciones',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener organizaciones: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<OrganizationModel> createOrganization(CreateOrganizationRequestModel request) async {
    try {
      final response = await dioClient.post(
        '/organizations',
        data: request.toJson(),
      );

      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al crear organización',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al crear organización: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<OrganizationModel> updateOrganization(String id, Map<String, dynamic> updates) async {
    try {
      final response = await dioClient.patch(
        '/organizations/$id',
        data: updates,
      );

      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al actualizar organización',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al actualizar organización: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteOrganization(String id) async {
    try {
      await dioClient.delete(
        '/organizations/$id',
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al eliminar organización',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al eliminar organización: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async {
    try {
      final response = await dioClient.get(
        '/organizations/$id',
      );

      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener organización',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener organización: $e',
        statusCode: 500,
      );
    }
  }
}