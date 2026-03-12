// lib/features/settings/data/datasources/printer_settings_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/printer_settings.dart';

/// Contrato para el datasource remoto de configuración de impresoras
abstract class PrinterSettingsRemoteDataSource {
  /// Obtener todas las impresoras del tenant
  Future<List<PrinterSettings>> getAllPrinterSettings();

  /// Obtener impresora por ID
  Future<PrinterSettings> getPrinterSettingById(String id);

  /// Crear nueva impresora
  Future<PrinterSettings> createPrinterSetting(Map<String, dynamic> data);

  /// Actualizar impresora
  Future<PrinterSettings> updatePrinterSetting(String id, Map<String, dynamic> data);

  /// Eliminar impresora
  Future<void> deletePrinterSetting(String id);

  /// Establecer impresora como predeterminada
  Future<PrinterSettings> setDefaultPrinter(String id);
}

/// Implementación del datasource remoto usando Dio
class PrinterSettingsRemoteDataSourceImpl implements PrinterSettingsRemoteDataSource {
  final DioClient dioClient;

  const PrinterSettingsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<PrinterSettings>> getAllPrinterSettings() async {
    try {
      final response = await dioClient.get(ApiConstants.printerSettings);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener impresoras: $e');
    }
  }

  @override
  Future<PrinterSettings> getPrinterSettingById(String id) async {
    try {
      final response = await dioClient.get(ApiConstants.printerSettingById(id));

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        return _fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener impresora: $e');
    }
  }

  @override
  Future<PrinterSettings> createPrinterSetting(Map<String, dynamic> data) async {
    try {
      final response = await dioClient.post(
        ApiConstants.printerSettings,
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = _extractData(response.data);
        return _fromJson(responseData);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al crear impresora: $e');
    }
  }

  @override
  Future<PrinterSettings> updatePrinterSetting(String id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.printerSettingById(id),
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = _extractData(response.data);
        return _fromJson(responseData);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al actualizar impresora: $e');
    }
  }

  @override
  Future<void> deletePrinterSetting(String id) async {
    try {
      final response = await dioClient.delete(ApiConstants.printerSettingById(id));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al eliminar impresora: $e');
    }
  }

  @override
  Future<PrinterSettings> setDefaultPrinter(String id) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.printerSettingSetDefault(id),
      );

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        return _fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al establecer impresora predeterminada: $e');
    }
  }

  // ==================== HELPERS ====================

  PrinterSettings _fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      connectionType: _parseConnectionType(json['connectionType'] ?? json['connection_type']),
      ipAddress: json['ipAddress'] ?? json['ip_address'],
      port: json['port'],
      usbPath: json['usbPath'] ?? json['usb_path'],
      paperSize: _parsePaperSize(json['paperSize'] ?? json['paper_size']),
      autoCut: json['autoCut'] ?? json['auto_cut'] ?? true,
      cashDrawer: json['cashDrawer'] ?? json['cash_drawer'] ?? false,
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now()),
    );
  }

  PrinterConnectionType _parseConnectionType(String? value) {
    switch (value) {
      case 'usb':
        return PrinterConnectionType.usb;
      default:
        return PrinterConnectionType.network;
    }
  }

  PaperSize _parsePaperSize(String? value) {
    switch (value) {
      case 'mm58':
        return PaperSize.mm58;
      default:
        return PaperSize.mm80;
    }
  }

  dynamic _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  ServerException _handleErrorResponse(Response response) {
    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String message = 'Error del servidor';
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    }

    return ServerException(message, statusCode: statusCode);
  }

  ServerException _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return ServerException('Tiempo de conexión agotado');
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return ServerException('Tiempo de respuesta agotado');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ServerException('Error de conexión al servidor');
    }
    if (e.response != null) {
      return _handleErrorResponse(e.response!);
    }
    return ServerException('Error de red: ${e.message}');
  }
}
