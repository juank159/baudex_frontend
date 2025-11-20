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
  
  /// ✅ NUEVO: Actualizar margen de ganancia para productos temporales
  Future<bool> updateProfitMargin(double marginPercentage);
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

  @override
  Future<bool> updateProfitMargin(double marginPercentage) async {
    try {
      print('🌐 Enviando PUT a /organizations/current/profit-margin con margen: $marginPercentage%');
      
      final response = await dioClient.put(
        '/organizations/current/profit-margin',
        data: {
          'marginPercentage': marginPercentage,
        },
      );

      // El backend devuelve: { success: boolean, marginPercentage: number, message: string }
      final success = response.data['success'] as bool? ?? false;
      
      print('✅ Respuesta del servidor: ${response.data}');
      
      return success;
    } on DioException catch (e) {
      print('❌ Error DioException: ${e.response?.data}');
      throw ServerException(
        e.response?.data['message'] ?? 'Error al actualizar margen de ganancia',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      print('❌ Error inesperado: $e');
      throw ServerException(
        'Error inesperado al actualizar margen de ganancia: $e',
        statusCode: 500,
      );
    }
  }
}