// lib/features/settings/data/datasources/organization_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/organization_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> getCurrentOrganization();
  Future<OrganizationModel> updateCurrentOrganization(Map<String, dynamic> updates);
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
  Future<OrganizationModel> updateCurrentOrganization(Map<String, dynamic> updates) async {
    try {
      final response = await dioClient.patch(
        '/organizations/current', // Usar el endpoint 'current' que no requiere admin
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