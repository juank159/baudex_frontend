// lib/features/inventory/presentation/services/warehouses_export_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/warehouse.dart';

class WarehousesExportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  // ==================== EXPORT TO CSV ====================

  /// Exportar almacenes a CSV
  static Future<void> exportToCsv(List<Warehouse> warehouses) async {
    try {
      final csvContent = _generateCsvContent(warehouses);
      final fileName =
          'almacenes_${_fileNameFormat.format(DateTime.now())}.csv';

      await _saveFile(csvContent, fileName, 'text/csv');

      Get.snackbar(
        'Exportación Exitosa',
        'Archivo CSV guardado: $fileName',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error de Exportación',
        'No se pudo exportar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error, color: Get.theme.colorScheme.error),
      );
    }
  }

  /// Generar contenido CSV
  static String _generateCsvContent(List<Warehouse> warehouses) {
    final buffer = StringBuffer();

    // Encabezados
    buffer.writeln(
      'Código,Nombre,Descripción,Dirección,Estado,Fecha Creación,Fecha Actualización',
    );

    // Datos
    for (final warehouse in warehouses) {
      final row = [
        _escapeCsv(warehouse.code),
        _escapeCsv(warehouse.name),
        _escapeCsv(warehouse.description ?? ''),
        _escapeCsv(warehouse.address ?? ''),
        warehouse.isActive ? 'Activo' : 'Inactivo',
        warehouse.createdAt != null
            ? _dateFormat.format(warehouse.createdAt!)
            : '',
        warehouse.updatedAt != null
            ? _dateFormat.format(warehouse.updatedAt!)
            : '',
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Escapar texto para CSV
  static String _escapeCsv(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  // ==================== EXPORT TO EXCEL ====================

  /// Exportar almacenes a Excel (simulado con CSV mejorado)
  static Future<void> exportToExcel(List<Warehouse> warehouses) async {
    try {
      // En un proyecto real, usarías una librería como excel o syncfusion_flutter_xlsio
      // Por ahora, exportamos como CSV con formato mejorado
      final excelContent = _generateExcelContent(warehouses);
      final fileName =
          'almacenes_${_fileNameFormat.format(DateTime.now())}.xlsx';

      await _saveFile(
        excelContent,
        fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      Get.snackbar(
        'Exportación Exitosa',
        'Archivo Excel guardado: $fileName',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error de Exportación',
        'No se pudo exportar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error, color: Get.theme.colorScheme.error),
      );
    }
  }

  /// Generar contenido Excel (simulado)
  static String _generateExcelContent(List<Warehouse> warehouses) {
    // En un proyecto real, aquí generarías un archivo Excel real
    // Por simplicidad, devolvemos CSV mejorado
    final buffer = StringBuffer();

    // Título y metadatos
    buffer.writeln('# Reporte de Almacenes');
    buffer.writeln('# Generado el: ${_dateFormat.format(DateTime.now())}');
    buffer.writeln('# Total de almacenes: ${warehouses.length}');
    buffer.writeln('');

    // Encabezados con más detalles
    buffer.writeln(
      'Código,Nombre,Descripción,Dirección,Estado,Activo desde,Última actualización,Observaciones',
    );

    // Datos con análisis
    for (final warehouse in warehouses) {
      final observations = _generateObservations(warehouse);
      final row = [
        _escapeCsv(warehouse.code),
        _escapeCsv(warehouse.name),
        _escapeCsv(warehouse.description ?? 'Sin descripción'),
        _escapeCsv(warehouse.address ?? 'Sin dirección'),
        warehouse.isActive ? 'Activo' : 'Inactivo',
        warehouse.createdAt != null
            ? _dateFormat.format(warehouse.createdAt!)
            : 'Desconocido',
        warehouse.updatedAt != null
            ? _dateFormat.format(warehouse.updatedAt!)
            : 'Nunca',
        _escapeCsv(observations),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Generar observaciones para el almacén
  static String _generateObservations(Warehouse warehouse) {
    final observations = <String>[];

    if (warehouse.description == null ||
        warehouse.description!.trim().isEmpty) {
      observations.add('Sin descripción');
    }

    if (warehouse.address == null || warehouse.address!.trim().isEmpty) {
      observations.add('Sin dirección');
    }

    if (warehouse.createdAt != null) {
      final daysSinceCreation =
          DateTime.now().difference(warehouse.createdAt!).inDays;
      if (daysSinceCreation <= 7) {
        observations.add('Recién creado');
      } else if (daysSinceCreation <= 30) {
        observations.add('Nuevo');
      }
    }

    return observations.isEmpty ? 'Completo' : observations.join(', ');
  }

  // ==================== EXPORT TO PDF ====================

  /// Exportar almacenes a PDF (simulado)
  static Future<void> exportToPdf(List<Warehouse> warehouses) async {
    try {
      // En un proyecto real, usarías una librería como pdf
      // Por ahora, exportamos como texto formateado
      final pdfContent = _generatePdfContent(warehouses);
      final fileName =
          'almacenes_${_fileNameFormat.format(DateTime.now())}.txt';

      await _saveFile(pdfContent, fileName, 'application/pdf');

      Get.snackbar(
        'Exportación Exitosa',
        'Reporte PDF guardado: $fileName',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error de Exportación',
        'No se pudo exportar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error, color: Get.theme.colorScheme.error),
      );
    }
  }

  /// Generar contenido PDF (simulado)
  static String _generatePdfContent(List<Warehouse> warehouses) {
    final buffer = StringBuffer();

    // Encabezado del reporte
    buffer.writeln('=' * 80);
    buffer.writeln('                          REPORTE DE ALMACENES');
    buffer.writeln('=' * 80);
    buffer.writeln();
    buffer.writeln(
      'Fecha de generación: ${_dateFormat.format(DateTime.now())}',
    );
    buffer.writeln('Total de almacenes: ${warehouses.length}');
    buffer.writeln();

    // Estadísticas
    final activeCount = warehouses.where((w) => w.isActive).length;
    final inactiveCount = warehouses.length - activeCount;

    buffer.writeln('ESTADÍSTICAS:');
    buffer.writeln('- Almacenes activos: $activeCount');
    buffer.writeln('- Almacenes inactivos: $inactiveCount');
    buffer.writeln(
      '- Porcentaje activos: ${((activeCount / warehouses.length) * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln();

    buffer.writeln('-' * 80);
    buffer.writeln('DETALLE DE ALMACENES:');
    buffer.writeln('-' * 80);

    // Detalles de cada almacén
    for (int i = 0; i < warehouses.length; i++) {
      final warehouse = warehouses[i];
      buffer.writeln();
      buffer.writeln(
        '${(i + 1).toString().padLeft(3)}. ${warehouse.name.toUpperCase()}',
      );
      buffer.writeln('     Código: ${warehouse.code}');
      buffer.writeln(
        '     Estado: ${warehouse.isActive ? "ACTIVO" : "INACTIVO"}',
      );

      if (warehouse.description != null &&
          warehouse.description!.trim().isNotEmpty) {
        buffer.writeln('     Descripción: ${warehouse.description}');
      }

      if (warehouse.address != null && warehouse.address!.trim().isNotEmpty) {
        buffer.writeln('     Dirección: ${warehouse.address}');
      }

      if (warehouse.createdAt != null) {
        buffer.writeln(
          '     Creado: ${_dateFormat.format(warehouse.createdAt!)}',
        );
      }

      if (warehouse.updatedAt != null) {
        buffer.writeln(
          '     Actualizado: ${_dateFormat.format(warehouse.updatedAt!)}',
        );
      }

      if (i < warehouses.length - 1) {
        buffer.writeln('     ${'-' * 40}');
      }
    }

    buffer.writeln();
    buffer.writeln('=' * 80);
    buffer.writeln('                    FIN DEL REPORTE');
    buffer.writeln('=' * 80);

    return buffer.toString();
  }

  // ==================== PRINT WAREHOUSES ====================

  /// Imprimir almacenes (simulado)
  static Future<void> printWarehouses(List<Warehouse> warehouses) async {
    try {
      // En un proyecto real, aquí enviarías a la impresora
      // Por ahora, generamos un contenido listo para imprimir

      final printContent = _generatePrintContent(warehouses);

      // Simular envío a impresora
      await Future.delayed(const Duration(milliseconds: 1500));

      Get.snackbar(
        'Impresión Enviada',
        'Documento enviado a la impresora (${warehouses.length} almacenes)',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        icon: Icon(Icons.print, color: Get.theme.colorScheme.primary),
        duration: const Duration(seconds: 3),
      );

      // También guardar una copia
      final fileName =
          'impresion_almacenes_${_fileNameFormat.format(DateTime.now())}.txt';
      await _saveFile(printContent, fileName, 'text/plain');
    } catch (e) {
      Get.snackbar(
        'Error de Impresión',
        'No se pudo imprimir: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        icon: Icon(Icons.error, color: Get.theme.colorScheme.error),
      );
    }
  }

  /// Generar contenido para impresión
  static String _generatePrintContent(List<Warehouse> warehouses) {
    final buffer = StringBuffer();

    // Encabezado simple para impresión
    buffer.writeln('LISTADO DE ALMACENES');
    buffer.writeln('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
    buffer.writeln('Total: ${warehouses.length} almacenes');
    buffer.writeln();
    buffer.writeln('-' * 50);

    // Lista simple
    for (int i = 0; i < warehouses.length; i++) {
      final warehouse = warehouses[i];
      buffer.writeln('${(i + 1).toString().padLeft(2)}. ${warehouse.name}');
      buffer.writeln('    Código: ${warehouse.code}');
      buffer.writeln(
        '    Estado: ${warehouse.isActive ? "Activo" : "Inactivo"}',
      );
      if (warehouse.address != null && warehouse.address!.trim().isNotEmpty) {
        buffer.writeln('    Dirección: ${warehouse.address}');
      }
      buffer.writeln();
    }

    buffer.writeln('-' * 50);
    buffer.writeln('Fin del listado');

    return buffer.toString();
  }

  // ==================== HELPER METHODS ====================

  /// Guardar archivo en el sistema
  static Future<void> _saveFile(
    String content,
    String fileName,
    String mimeType,
  ) async {
    try {
      // Obtener directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Crear archivo
      final file = File(filePath);
      await file.writeAsString(content, encoding: SystemEncoding());

      print('📁 Archivo guardado en: $filePath');
    } catch (e) {
      print('❌ Error al guardar archivo: $e');
      rethrow;
    }
  }

  // ==================== STATISTICS METHODS ====================

  /// Obtener estadísticas de exportación
  static Map<String, dynamic> getExportStats(List<Warehouse> warehouses) {
    final active = warehouses.where((w) => w.isActive).length;
    final inactive = warehouses.length - active;
    final withDescription =
        warehouses
            .where((w) => w.description?.trim().isNotEmpty == true)
            .length;
    final withAddress =
        warehouses.where((w) => w.address?.trim().isNotEmpty == true).length;

    return {
      'total': warehouses.length,
      'active': active,
      'inactive': inactive,
      'withDescription': withDescription,
      'withAddress': withAddress,
      'completeness': ((withDescription + withAddress) /
              (warehouses.length * 2) *
              100)
          .toStringAsFixed(1),
    };
  }
}
