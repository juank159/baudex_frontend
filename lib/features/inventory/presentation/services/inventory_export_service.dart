// lib/features/inventory/presentation/services/inventory_export_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../domain/entities/inventory_balance.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/entities/kardex_entry.dart';
import '../../domain/entities/kardex_report.dart';
import '../../domain/entities/inventory_batch.dart';
import '../../domain/entities/warehouse.dart';

class InventoryExportService {
  static const String companyName = 'BAUDEX';

  // ==================== EXCEL EXPORTS ====================

  static Future<void> exportBalancesToExcel(
    List<InventoryBalance> balances, {
    Map<String, String>? filterInfo,
    Map<String, dynamic>? summary,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventario - Balances'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Calculate summary
      final totalProducts = balances.length;
      final totalValue = balances.fold(
        0.0,
        (sum, balance) => sum + balance.totalValue,
      );

      // Add summary section
      int currentRow = 0;

      // Company header
      final companyCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      companyCell.value = TextCellValue(companyName);
      companyCell.cellStyle = CellStyle(bold: true, fontSize: 16);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow++;

      // Title
      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      titleCell.value = TextCellValue('Reporte de Balances de Inventario');
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow++;

      // Date
      final dateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      dateCell.value = TextCellValue(
        'Fecha: ${AppFormatters.formatDateTime(DateTime.now())}',
      );
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow++;

      // Summary
      final summaryCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      summaryCell.value = TextCellValue(
        'Productos: $totalProducts    Valor: ${AppFormatters.formatCurrency(totalValue)}',
      );
      summaryCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow += 2; // Extra space

      // Header
      final headers = [
        'Producto',
        'Stock Total',
        'Stock Disponible',
        'Stock Reservado',
        'Valor Total',
        'Costo Promedio',
        'Última Actualización',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
      currentRow++;

      // Add data
      for (int i = 0; i < balances.length; i++) {
        final balance = balances[i];
        final rowIndex = currentRow + i;

        final rowData = [
          balance.productName,
          balance.totalQuantity.toString(),
          balance.availableQuantity.toString(),
          balance.reservedQuantity.toString(),
          AppFormatters.formatCurrency(balance.totalValue),
          AppFormatters.formatCurrency(balance.averageCost),
          AppFormatters.formatDateTime(balance.lastUpdated),
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      await _saveAndShareExcel(excel, 'inventario_balances', shareOnly: true);
    } catch (e) {
      throw Exception('Error exportando balances a Excel: $e');
    }
  }

  static Future<String> downloadBalancesToExcel(
    List<InventoryBalance> balances, {
    Map<String, String>? filterInfo,
    Map<String, dynamic>? summary,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventario - Balances'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Calculate summary
      final totalProducts = balances.length;
      final totalValue = balances.fold(
        0.0,
        (sum, balance) => sum + balance.totalValue,
      );

      // Add summary section
      int currentRow = 0;

      // Company header
      final companyCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      companyCell.value = TextCellValue(companyName);
      companyCell.cellStyle = CellStyle(bold: true, fontSize: 16);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow++;

      // Title
      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      titleCell.value = TextCellValue('Reporte de Balances de Inventario');
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow++;

      // Date
      final dateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      dateCell.value = TextCellValue(
        'Fecha: ${AppFormatters.formatDateTime(DateTime.now())}',
      );
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow++;

      // Summary
      final summaryCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      summaryCell.value = TextCellValue(
        'Productos: $totalProducts    Valor: ${AppFormatters.formatCurrency(totalValue)}',
      );
      summaryCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      currentRow += 2; // Extra space

      // Header
      final headers = [
        'Producto',
        'Stock Total',
        'Stock Disponible',
        'Stock Reservado',
        'Valor Total',
        'Costo Promedio',
        'Última Actualización',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
      currentRow++;

      // Add data
      for (int i = 0; i < balances.length; i++) {
        final balance = balances[i];
        final rowIndex = currentRow + i;

        final rowData = [
          balance.productName,
          balance.totalQuantity.toString(),
          balance.availableQuantity.toString(),
          balance.reservedQuantity.toString(),
          AppFormatters.formatCurrency(balance.totalValue),
          AppFormatters.formatCurrency(balance.averageCost),
          AppFormatters.formatDateTime(balance.lastUpdated),
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      return await _saveExcelWithPicker(excel, 'inventario_balances');
    } catch (e) {
      throw Exception('Error descargando balances a Excel: $e');
    }
  }

  static Future<void> exportMovementsToExcel(
    List<InventoryMovement> movements,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Inventario - Movimientos'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Header
      final headers = [
        'Fecha',
        'Producto',
        'SKU',
        'Tipo',
        'Razón',
        'Cantidad',
        'Costo Unitario',
        'Costo Total',
        'Estado',
        'Almacén',
        'Referencia',
        'Notas',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data
      for (int i = 0; i < movements.length; i++) {
        final movement = movements[i];
        final rowIndex = i + 1;

        final rowData = [
          AppFormatters.formatDate(movement.movementDate),
          movement.productName,
          movement.productSku,
          movement.type.displayType,
          movement.reason.displayReason,
          movement.displayQuantity,
          AppFormatters.formatCurrency(movement.unitCost),
          AppFormatters.formatCurrency(movement.totalCost),
          movement.status.displayStatus,
          movement.warehouseName ?? 'N/A',
          movement.hasReference
              ? '${movement.referenceType} - ${movement.referenceId}'
              : 'N/A',
          movement.notes ?? '',
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          // Color coding for quantity
          if (j == 5) {
            // Quantity column
            if (movement.type == InventoryMovementType.inbound) {
              cell.cellStyle = CellStyle();
            } else if (movement.type == InventoryMovementType.outbound) {
              cell.cellStyle = CellStyle();
            }
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      await _saveAndShareExcel(
        excel,
        'transferencias_inventario',
        shareOnly: true,
      );
    } catch (e) {
      throw Exception('Error exportando movimientos a Excel: $e');
    }
  }

  static Future<void> exportKardexFromEntriestoExcel(
    String productName,
    List<KardexEntry> entries,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Kardex - $productName'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Header with product info
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue('KARDEX DE PRODUCTO: $productName');
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0),
      );

      // Headers
      final headers = [
        'Fecha',
        'Documento',
        'Descripción',
        'Entrada',
        'Salida',
        'Saldo',
        'Costo Entrada',
        'Costo Salida',
        'Valor Total',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final rowIndex = i + 3;

        final rowData = [
          AppFormatters.formatDate(entry.date),
          '${entry.documentType} - ${entry.documentNumber}',
          entry.description,
          entry.quantityIn > 0 ? entry.quantityIn.toString() : '',
          entry.quantityOut > 0 ? entry.quantityOut.toString() : '',
          entry.balance.toString(),
          entry.unitCostIn > 0
              ? AppFormatters.formatCurrency(entry.unitCostIn)
              : '',
          entry.unitCostOut > 0
              ? AppFormatters.formatCurrency(entry.unitCostOut)
              : '',
          AppFormatters.formatCurrency(entry.totalValue),
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          // Color coding for quantities
          if (j == 3 && entry.quantityIn > 0) {
            // Entrada
            cell.cellStyle = CellStyle();
          } else if (j == 4 && entry.quantityOut > 0) {
            // Salida
            cell.cellStyle = CellStyle();
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      await _saveAndShareExcel(
        excel,
        'kardex_${productName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      throw Exception('Error exportando kardex a Excel: $e');
    }
  }

  static Future<void> exportKardexToExcel(
    String productName,
    List<InventoryMovement> movements,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Kardex - $productName'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Header with product info
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue('KARDEX DE PRODUCTO: $productName');
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
      );

      // Headers
      final headers = [
        'Fecha',
        'Tipo',
        'Razón',
        'Entrada',
        'Salida',
        'Saldo',
        'Costo Unit.',
        'Valor Total',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Calculate running balance
      int runningBalance = 0;

      // Add data
      for (int i = 0; i < movements.length; i++) {
        final movement = movements[i];
        final rowIndex = i + 3;

        // Update running balance
        runningBalance += movement.quantity;

        final entrada =
            movement.type == InventoryMovementType.inbound
                ? movement.quantity.toString()
                : '';
        final salida =
            movement.type == InventoryMovementType.outbound
                ? movement.quantity.abs().toString()
                : '';

        final rowData = [
          AppFormatters.formatDate(movement.movementDate),
          movement.type.displayType,
          movement.reason.displayReason,
          entrada,
          salida,
          runningBalance.toString(),
          AppFormatters.formatCurrency(movement.unitCost),
          AppFormatters.formatCurrency(movement.totalCost),
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      await _saveAndShareExcel(
        excel,
        'kardex_${productName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      throw Exception('Error exportando kardex a Excel: $e');
    }
  }

  // ==================== PDF EXPORTS ====================

  static Future<void> exportBalancesToPDF(
    List<InventoryBalance> balances, {
    Map<String, String>? filterInfo,
    Map<String, dynamic>? summary,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Balances de Inventario'),
                pw.SizedBox(height: 20),
                _buildBalancesTable(balances),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      await _saveAndSharePDF(pdf, 'inventario_balances', shareOnly: true);
    } catch (e) {
      throw Exception('Error exportando balances a PDF: $e');
    }
  }

  static Future<String> downloadBalancesToPDF(
    List<InventoryBalance> balances, {
    Map<String, String>? filterInfo,
    Map<String, dynamic>? summary,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Balances de Inventario'),
                pw.SizedBox(height: 20),
                _buildBalancesTable(balances),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      return await _savePDFWithPicker(pdf, 'inventario_balances');
    } catch (e) {
      throw Exception('Error descargando balances a PDF: $e');
    }
  }

  static Future<void> exportMovementsToPDF(
    List<InventoryMovement> movements,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Movimientos de Inventario'),
                pw.SizedBox(height: 20),
                _buildMovementsTable(movements),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      await _saveAndSharePDF(pdf, 'transferencias_inventario', shareOnly: true);
    } catch (e) {
      throw Exception('Error exportando movimientos a PDF: $e');
    }
  }

  static Future<String> downloadMovementsToExcel(
    List<InventoryMovement> movements, {
    List<Warehouse>? warehouses,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Transferencias de Inventario'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Add company header and title
      int currentRow = 0;

      // Company header
      final companyCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      companyCell.value = TextCellValue(companyName);
      companyCell.cellStyle = CellStyle(bold: true, fontSize: 16);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
      );
      currentRow++;

      // Title
      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      titleCell.value = TextCellValue(
        'Reporte de Transferencias de Inventario',
      );
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
      );
      currentRow++;

      // Date
      final dateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      dateCell.value = TextCellValue(
        'Fecha: ${AppFormatters.formatDateTime(DateTime.now())}',
      );
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
      );
      currentRow++;

      // Group and process movements to avoid duplicates
      final processedMovements = _processTransferMovements(movements);

      // Summary
      final summaryCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      summaryCell.value = TextCellValue(
        'Total de Transferencias: ${processedMovements.length}',
      );
      summaryCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
      );
      currentRow += 2; // Extra space

      // Header
      final headers = [
        'Fecha',
        'Producto',
        'Almacén Origen',
        'Almacén Destino',
        'Cantidad',
        'Estado',
        'Notas',
        'Tipo de Movimiento',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
      currentRow++;

      // Add data
      for (int i = 0; i < processedMovements.length; i++) {
        final movement = processedMovements[i];
        final rowIndex = currentRow + i;

        // Extract warehouse names for transfers using better logic
        String almacenOrigen = _extractWarehouseName(
          movement,
          isOrigin: true,
          warehouses: warehouses,
        );
        String almacenDestino = _extractWarehouseName(
          movement,
          isOrigin: false,
          warehouses: warehouses,
        );

        // Get status in Spanish
        String estadoEspanol = '';
        switch (movement.status.name) {
          case 'pending':
            estadoEspanol = 'Pendiente';
            break;
          case 'confirmed':
            estadoEspanol = 'Confirmada';
            break;
          case 'cancelled':
            estadoEspanol = 'Cancelada';
            break;
          default:
            estadoEspanol = movement.status.name;
        }

        // Get movement type in Spanish
        String tipoMovimiento = '';
        switch (movement.type.name) {
          case 'transfer_in':
            tipoMovimiento = 'Entrada por Transferencia';
            break;
          case 'transfer_out':
            tipoMovimiento = 'Salida por Transferencia';
            break;
          case 'inbound':
            tipoMovimiento = 'Entrada';
            break;
          case 'outbound':
            tipoMovimiento = 'Salida';
            break;
          default:
            tipoMovimiento = movement.type.name;
        }

        final rowData = [
          AppFormatters.formatDate(movement.createdAt),
          movement.productName,
          almacenOrigen,
          almacenDestino,
          movement.quantity.toString(),
          estadoEspanol,
          movement.notes ?? '',
          tipoMovimiento,
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          // Color coding for quantity
          if (j == 4) {
            // Quantity column
            if (movement.type == InventoryMovementType.transferIn ||
                movement.type == InventoryMovementType.inbound) {
              cell.cellStyle = CellStyle();
            } else if (movement.type == InventoryMovementType.transferOut ||
                movement.type == InventoryMovementType.outbound) {
              cell.cellStyle = CellStyle();
            }
          }
          // Color coding for status
          if (j == 5) {
            // Status column
            if (movement.status.name == 'confirmed') {
              cell.cellStyle = CellStyle();
            } else if (movement.status.name == 'cancelled') {
              cell.cellStyle = CellStyle();
            } else if (movement.status.name == 'pending') {
              cell.cellStyle = CellStyle();
            }
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      return await _saveExcelWithPicker(
        excel,
        'Transferencias_Inventario_${AppFormatters.formatDate(DateTime.now()).replaceAll('/', '-')}',
      );
    } catch (e) {
      throw Exception('Error descargando movimientos a Excel: $e');
    }
  }

  static Future<String> downloadMovementsToPDF(
    List<InventoryMovement> movements, {
    List<Warehouse>? warehouses,
  }) async {
    try {
      final processedMovements = _processTransferMovements(movements);
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Transferencias de Inventario'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total de Transferencias: ${processedMovements.length}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildTransfersTable(processedMovements, warehouses),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      return await _savePDFWithPicker(
        pdf,
        'Transferencias_Inventario_${AppFormatters.formatDate(DateTime.now()).replaceAll('/', '-')}',
      );
    } catch (e) {
      throw Exception('Error descargando movimientos a PDF: $e');
    }
  }

  static Future<void> exportKardexFromEntriesToPDF(
    String productName,
    List<KardexEntry> entries,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Kardex de Producto'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Producto: $productName',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildKardexEntriesTable(entries),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      await _saveAndSharePDF(pdf, 'kardex_${productName.replaceAll(' ', '_')}');
    } catch (e) {
      throw Exception('Error exportando kardex a PDF: $e');
    }
  }

  static Future<void> exportKardexToPDF(
    String productName,
    List<InventoryMovement> movements,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Kardex de Producto'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Producto: $productName',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildKardexTable(movements),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      await _saveAndSharePDF(pdf, 'kardex_${productName.replaceAll(' ', '_')}');
    } catch (e) {
      throw Exception('Error exportando kardex a PDF: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  static pw.Widget _buildPDFHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              companyName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.helvetica(),
              ),
            ),
            pw.Text(
              'Generado: ${AppFormatters.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, font: pw.Font.helvetica()),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            font: pw.Font.helvetica(),
          ),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildPDFFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'Reporte generado automaticamente por $companyName',
          style: pw.TextStyle(fontSize: 8, font: pw.Font.helvetica()),
        ),
      ],
    );
  }

  static pw.Widget _buildBalancesTable(List<InventoryBalance> balances) {
    // Calculate summary
    final totalProducts = balances.length;
    final totalValue = balances.fold(
      0.0,
      (sum, balance) => sum + balance.totalValue,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Summary section
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Productos: $totalProducts',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: pw.Font.helvetica(),
                ),
              ),
              pw.Text(
                'Valor: ${AppFormatters.formatCurrency(totalValue)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: pw.Font.helvetica(),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Table
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Producto', isHeader: true),
                _buildTableCell('Stock Total', isHeader: true),
                _buildTableCell('Disponible', isHeader: true),
                _buildTableCell('Reservado', isHeader: true),
                _buildTableCell('Valor Total', isHeader: true),
                _buildTableCell('Costo Promedio', isHeader: true),
              ],
            ),
            // Data rows
            ...balances.map(
              (balance) => pw.TableRow(
                children: [
                  _buildTableCell(balance.productName),
                  _buildTableCell(balance.totalQuantity.toString()),
                  _buildTableCell(balance.availableQuantity.toString()),
                  _buildTableCell(balance.reservedQuantity.toString()),
                  _buildTableCell(
                    AppFormatters.formatCurrency(balance.totalValue),
                  ),
                  _buildTableCell(
                    AppFormatters.formatCurrency(balance.averageCost),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMovementsTable(List<InventoryMovement> movements) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Producto', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Razón', isHeader: true),
            _buildTableCell('Cantidad', isHeader: true),
            _buildTableCell('Costo Total', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
          ],
        ),
        // Data rows
        ...movements.map(
          (movement) => pw.TableRow(
            children: [
              _buildTableCell(AppFormatters.formatDate(movement.movementDate)),
              _buildTableCell(movement.productName),
              _buildTableCell(movement.type.displayType),
              _buildTableCell(movement.reason.displayReason),
              _buildTableCell(movement.displayQuantity),
              _buildTableCell(AppFormatters.formatCurrency(movement.totalCost)),
              _buildTableCell(movement.status.displayStatus),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransfersTable(
    List<InventoryMovement> movements,
    List<Warehouse>? warehouses,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5), // Fecha
        1: const pw.FlexColumnWidth(2.5), // Producto
        2: const pw.FlexColumnWidth(2), // Almacén Origen
        3: const pw.FlexColumnWidth(2), // Almacén Destino
        4: const pw.FlexColumnWidth(1), // Cantidad
        5: const pw.FlexColumnWidth(1.5), // Estado
        6: const pw.FlexColumnWidth(1.5), // Tipo
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Producto', isHeader: true),
            _buildTableCell('Almacén Origen', isHeader: true),
            _buildTableCell('Almacén Destino', isHeader: true),
            _buildTableCell('Cantidad', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
          ],
        ),
        // Data rows
        ...movements.map((movement) {
          // Extract warehouse names for transfers using better logic
          String almacenOrigen = _extractWarehouseName(
            movement,
            isOrigin: true,
            warehouses: warehouses,
          );
          String almacenDestino = _extractWarehouseName(
            movement,
            isOrigin: false,
            warehouses: warehouses,
          );

          // Get status in Spanish
          String estadoEspanol = '';
          switch (movement.status.name) {
            case 'pending':
              estadoEspanol = 'Pendiente';
              break;
            case 'confirmed':
              estadoEspanol = 'Confirmada';
              break;
            case 'cancelled':
              estadoEspanol = 'Cancelada';
              break;
            default:
              estadoEspanol = movement.status.name;
          }

          // Get movement type in Spanish
          String tipoMovimiento = '';
          switch (movement.type.name) {
            case 'transfer_in':
              tipoMovimiento = 'Entrada por Transferencia';
              break;
            case 'transfer_out':
              tipoMovimiento = 'Salida por Transferencia';
              break;
            case 'inbound':
              tipoMovimiento = 'Entrada';
              break;
            case 'outbound':
              tipoMovimiento = 'Salida';
              break;
            default:
              tipoMovimiento = movement.type.name;
          }

          return pw.TableRow(
            children: [
              _buildTableCell(AppFormatters.formatDate(movement.createdAt)),
              _buildTableCell(movement.productName),
              _buildTableCell(almacenOrigen),
              _buildTableCell(almacenDestino),
              _buildTableCell(movement.quantity.toString()),
              _buildTableCell(estadoEspanol),
              _buildTableCell(tipoMovimiento),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildKardexTable(List<InventoryMovement> movements) {
    int runningBalance = 0;

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Razón', isHeader: true),
            _buildTableCell('Entrada', isHeader: true),
            _buildTableCell('Salida', isHeader: true),
            _buildTableCell('Saldo', isHeader: true),
            _buildTableCell('Valor', isHeader: true),
          ],
        ),
        // Data rows
        ...movements.map((movement) {
          runningBalance += movement.quantity;

          final entrada =
              movement.type == InventoryMovementType.inbound
                  ? movement.quantity.toString()
                  : '';
          final salida =
              movement.type == InventoryMovementType.outbound
                  ? movement.quantity.abs().toString()
                  : '';

          return pw.TableRow(
            children: [
              _buildTableCell(AppFormatters.formatDate(movement.movementDate)),
              _buildTableCell(movement.reason.displayReason),
              _buildTableCell(entrada),
              _buildTableCell(salida),
              _buildTableCell(runningBalance.toString()),
              _buildTableCell(AppFormatters.formatCurrency(movement.totalCost)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font:
              pw.Font.helvetica(), // Use basic font that supports Unicode better
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static Future<String> _saveAndShareExcel(
    Excel excel,
    String filename, {
    bool shareOnly = false,
  }) async {
    try {
      final bytes = excel.encode();
      if (bytes == null) throw Exception('No se pudo generar el archivo Excel');

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.xlsx');
      await file.writeAsBytes(bytes);

      if (shareOnly) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Reporte de inventario exportado',
          subject: 'Reporte - $filename',
        );
      }

      return file.path;
    } catch (e) {
      throw Exception('Error guardando archivo Excel: $e');
    }
  }

  static pw.Widget _buildKardexEntriesTable(List<KardexEntry> entries) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Documento', isHeader: true),
            _buildTableCell('Descripción', isHeader: true),
            _buildTableCell('Entrada', isHeader: true),
            _buildTableCell('Salida', isHeader: true),
            _buildTableCell('Saldo', isHeader: true),
            _buildTableCell('Valor', isHeader: true),
          ],
        ),
        // Data rows
        ...entries.map(
          (entry) => pw.TableRow(
            children: [
              _buildTableCell(AppFormatters.formatDate(entry.date)),
              _buildTableCell(
                '${entry.documentType} - ${entry.documentNumber}',
              ),
              _buildTableCell(entry.description),
              _buildTableCell(
                entry.quantityIn > 0 ? entry.quantityIn.toString() : '',
              ),
              _buildTableCell(
                entry.quantityOut > 0 ? entry.quantityOut.toString() : '',
              ),
              _buildTableCell(entry.balance.toString()),
              _buildTableCell(AppFormatters.formatCurrency(entry.totalValue)),
            ],
          ),
        ),
      ],
    );
  }

  static Future<String> _saveAndSharePDF(
    pw.Document pdf,
    String filename, {
    bool shareOnly = false,
  }) async {
    try {
      final bytes = await pdf.save();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.pdf');
      await file.writeAsBytes(bytes);

      if (shareOnly) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Reporte de inventario exportado',
          subject: 'Reporte - $filename',
        );
      }

      return file.path;
    } catch (e) {
      throw Exception('Error guardando archivo PDF: $e');
    }
  }

  // ==================== AGING REPORTS ====================

  static Future<void> exportAgingDataToExcel(
    List<Map<String, dynamic>> agingData,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Reporte de Antigüedad'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Header
      final headers = [
        'Producto',
        'SKU',
        'Categoría',
        'Stock Total',
        'Días Promedio',
        'Valor Total',
        'Estado',
        'Última Entrada',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data
      for (int i = 0; i < agingData.length; i++) {
        final item = agingData[i];
        final rowIndex = i + 1;

        final rowData = [
          item['productName']?.toString() ?? '',
          item['productSku']?.toString() ?? '',
          item['categoryName']?.toString() ?? '',
          item['totalStock']?.toString() ?? '0',
          item['averageAgeDays']?.toString() ?? '0',
          AppFormatters.formatCurrency((item['totalValue'] ?? 0.0).toDouble()),
          _getAgingStatus((item['averageAgeDays'] ?? 0) as int),
          item['lastReceiptDate'] != null
              ? AppFormatters.formatDate(
                DateTime.parse(item['lastReceiptDate']),
              )
              : 'N/A',
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          // Color coding for aging status
          if (j == 6) {
            // Status column
            final ageDays = (item['averageAgeDays'] ?? 0) as int;
            if (ageDays > 180) {
              cell.cellStyle = CellStyle();
            } else if (ageDays > 90) {
              cell.cellStyle = CellStyle();
            } else {
              cell.cellStyle = CellStyle();
            }
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      await _saveAndShareExcel(excel, 'reporte_antiguedad_inventario');
    } catch (e) {
      throw Exception('Error exportando reporte de antigüedad a Excel: $e');
    }
  }

  static Future<void> exportAgingDataToPDF(
    List<Map<String, dynamic>> agingData,
    dynamic agingSummary,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Antigüedad de Inventario'),
                pw.SizedBox(height: 10),
                if (agingSummary != null)
                  _buildAgingSummarySection(agingSummary),
                pw.SizedBox(height: 20),
                _buildAgingDataTable(agingData),
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      await _saveAndSharePDF(pdf, 'reporte_antiguedad_inventario');
    } catch (e) {
      throw Exception('Error exportando reporte de antigüedad a PDF: $e');
    }
  }

  static pw.Widget _buildAgingSummarySection(dynamic summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen del Reporte',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: pw.Font.helvetica(),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total de productos: ${summary.totalProducts}'),
              pw.Text(
                'Valor total: ${AppFormatters.formatCurrency(summary.totalValue)}',
              ),
              pw.Text('Antigüedad promedio: ${summary.averageAgeDays} días'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAgingDataTable(List<Map<String, dynamic>> agingData) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Producto', isHeader: true),
            _buildTableCell('SKU', isHeader: true),
            _buildTableCell('Categoría', isHeader: true),
            _buildTableCell('Stock', isHeader: true),
            _buildTableCell('Días', isHeader: true),
            _buildTableCell('Valor Total', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
          ],
        ),
        // Data rows
        ...agingData.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item['productName']?.toString() ?? ''),
              _buildTableCell(item['productSku']?.toString() ?? ''),
              _buildTableCell(item['categoryName']?.toString() ?? ''),
              _buildTableCell(item['totalStock']?.toString() ?? '0'),
              _buildTableCell(item['averageAgeDays']?.toString() ?? '0'),
              _buildTableCell(
                AppFormatters.formatCurrency(
                  (item['totalValue'] ?? 0.0).toDouble(),
                ),
              ),
              _buildTableCell(
                _getAgingStatus((item['averageAgeDays'] ?? 0) as int),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _getAgingStatus(int ageDays) {
    if (ageDays > 180) return 'Muy Antiguo';
    if (ageDays > 90) return 'Antiguo';
    if (ageDays > 30) return 'Moderado';
    return 'Reciente';
  }

  // ==================== HELPER METHODS FOR BATCH DATA ====================

  static Future<Map<String, String>> _getSupplierNames(
    List<InventoryBatch> batches,
  ) async {
    try {
      final dio = Get.find<DioClient>().dio;
      final Map<String, String> supplierNames = {};

      // Get unique purchase order IDs to fetch supplier info from there
      final uniqueOrderIds =
          batches
              .where(
                (batch) =>
                    batch.purchaseOrderId != null &&
                    batch.purchaseOrderId!.isNotEmpty,
              )
              .map((batch) => batch.purchaseOrderId!)
              .toSet();

      // Fetch supplier names from purchase orders
      for (final orderId in uniqueOrderIds) {
        try {
          final response = await dio.get('/purchase-orders/$orderId');
          if (response.statusCode == 200 && response.data['success'] == true) {
            final orderData = response.data['data'];
            final supplierName = orderData['supplier']?['name'];
            if (supplierName != null) {
              // Map this supplier name to all batches from this purchase order
              final batchesFromThisOrder = batches.where(
                (batch) => batch.purchaseOrderId == orderId,
              );
              for (final batch in batchesFromThisOrder) {
                supplierNames[batch.id] = supplierName;
              }
            }
          }
        } catch (e) {
          print('❌ Error obteniendo datos de orden $orderId: $e');
        }
      }

      return supplierNames;
    } catch (e) {
      print('❌ Error obteniendo nombres de proveedores: $e');
      return {};
    }
  }

  static Future<Map<String, String>> _getPurchaseOrderNumbers(
    List<InventoryBatch> batches,
  ) async {
    try {
      final dio = Get.find<DioClient>().dio;
      final Map<String, String> orderNumbers = {};

      // Get unique purchase order IDs
      final uniqueOrderIds =
          batches
              .where(
                (batch) =>
                    batch.purchaseOrderId != null &&
                    batch.purchaseOrderId!.isNotEmpty,
              )
              .map((batch) => batch.purchaseOrderId!)
              .toSet();

      // Fetch purchase order numbers directly via API
      for (final orderId in uniqueOrderIds) {
        try {
          final response = await dio.get('/purchase-orders/$orderId');
          if (response.statusCode == 200 && response.data['success'] == true) {
            final orderData = response.data['data'];
            orderNumbers[orderId] =
                orderData['orderNumber'] ?? 'PO-${orderId.substring(0, 8)}';
          } else {
            orderNumbers[orderId] = 'PO-${orderId.substring(0, 8)}';
          }
        } catch (e) {
          print('❌ Error obteniendo orden $orderId: $e');
          orderNumbers[orderId] = 'PO-${orderId.substring(0, 8)}';
        }
      }

      return orderNumbers;
    } catch (e) {
      print('❌ Error obteniendo números de órdenes: $e');
      return {};
    }
  }

  // ==================== BATCH EXPORTS ====================

  static Future<void> exportBatchesToExcel(
    List<InventoryBatch> batches,
    String productName,
  ) async {
    try {
      // Obtain real supplier names and purchase order numbers
      final supplierNames = await _getSupplierNames(batches);
      final orderNumbers = await _getPurchaseOrderNumbers(batches);

      final excel = Excel.createExcel();
      final sheet = excel['Lotes - $productName'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Header
      final headers = [
        'Número de Lote',
        'Fecha de Entrada',
        'Fecha de Vencimiento',
        'Cantidad Inicial',
        'Cantidad Actual',
        'Cantidad Consumida',
        'Costo Unitario',
        'Valor Total',
        'Valor Consumido',
        'Valor Actual',
        'Estado',
        'Días en Stock',
        'Proveedor',
        'Orden de Compra',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        final rowIndex = i + 1;

        final rowData = [
          batch.batchNumber,
          AppFormatters.formatDate(batch.entryDate),
          batch.hasExpiry
              ? AppFormatters.formatDate(batch.expiryDate!)
              : 'Sin vencimiento',
          batch.originalQuantity.toString(),
          batch.currentQuantity.toString(),
          (batch.originalQuantity - batch.currentQuantity).toString(),
          AppFormatters.formatCurrency(batch.unitCost),
          AppFormatters.formatCurrency(batch.totalCost),
          AppFormatters.formatCurrency(batch.consumedValue),
          AppFormatters.formatCurrency(batch.currentValue),
          _getBatchStatusText(batch),
          batch.daysInStock.toString(),
          supplierNames[batch.id] ?? batch.supplierName ?? 'N/A',
          batch.purchaseOrderId != null
              ? (orderNumbers[batch.purchaseOrderId!] ??
                  batch.purchaseOrderNumber ??
                  'N/A')
              : 'N/A',
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          // Color coding for status
          if (j == 10) {
            // Status column (now at index 10)
            if (batch.isExpiredByDate) {
              cell.cellStyle = CellStyle();
            } else if (batch.isNearExpiry) {
              cell.cellStyle = CellStyle();
            } else if (batch.isActive) {
              cell.cellStyle = CellStyle();
            }
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      await _saveAndShareExcel(
        excel,
        'lotes_${productName.replaceAll(' ', '_')}',
        shareOnly: true,
      );
    } catch (e) {
      throw Exception('Error exportando lotes a Excel: $e');
    }
  }

  static Future<String> downloadBatchesToExcel(
    List<InventoryBatch> batches,
    String productName,
  ) async {
    try {
      // Obtain real supplier names and purchase order numbers
      final supplierNames = await _getSupplierNames(batches);
      final orderNumbers = await _getPurchaseOrderNumbers(batches);

      final excel = Excel.createExcel();
      final sheet = excel['Lotes - $productName'];

      // Remove default sheet
      excel.delete('Sheet1');

      // Header
      final headers = [
        'Número de Lote',
        'Fecha de Entrada',
        'Fecha de Vencimiento',
        'Cantidad Inicial',
        'Cantidad Actual',
        'Cantidad Consumida',
        'Costo Unitario',
        'Valor Total',
        'Valor Consumido',
        'Valor Actual',
        'Estado',
        'Días en Stock',
        'Proveedor',
        'Orden de Compra',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Add data
      for (int i = 0; i < batches.length; i++) {
        final batch = batches[i];
        final rowIndex = i + 1;

        final rowData = [
          batch.batchNumber,
          AppFormatters.formatDate(batch.entryDate),
          batch.hasExpiry
              ? AppFormatters.formatDate(batch.expiryDate!)
              : 'Sin vencimiento',
          batch.originalQuantity.toString(),
          batch.currentQuantity.toString(),
          (batch.originalQuantity - batch.currentQuantity).toString(),
          AppFormatters.formatCurrency(batch.unitCost),
          AppFormatters.formatCurrency(batch.totalCost),
          AppFormatters.formatCurrency(batch.consumedValue),
          AppFormatters.formatCurrency(batch.currentValue),
          _getBatchStatusText(batch),
          batch.daysInStock.toString(),
          supplierNames[batch.id] ?? batch.supplierName ?? 'N/A',
          batch.purchaseOrderId != null
              ? (orderNumbers[batch.purchaseOrderId!] ??
                  batch.purchaseOrderNumber ??
                  'N/A')
              : 'N/A',
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);

          // Color coding for status
          if (j == 10) {
            // Status column (now at index 10)
            if (batch.isExpiredByDate) {
              cell.cellStyle = CellStyle();
            } else if (batch.isNearExpiry) {
              cell.cellStyle = CellStyle();
            } else if (batch.isActive) {
              cell.cellStyle = CellStyle();
            }
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      return await _saveExcelWithPicker(
        excel,
        'lotes_${productName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      throw Exception('Error descargando lotes a Excel: $e');
    }
  }

  static Future<void> exportBatchesToPDF(
    List<InventoryBatch> batches,
    String productName,
  ) async {
    try {
      final pdf = pw.Document();

      // Build the table with all columns (async)
      final batchesTable = await _buildBatchesTable(batches);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Lotes de Inventario'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Producto: $productName',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 20),
                batchesTable,
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      await _saveAndSharePDF(
        pdf,
        'lotes_${productName.replaceAll(' ', '_')}',
        shareOnly: true,
      );
    } catch (e) {
      throw Exception('Error exportando lotes a PDF: $e');
    }
  }

  static Future<String> downloadBatchesToPDF(
    List<InventoryBatch> batches,
    String productName,
  ) async {
    try {
      final pdf = pw.Document();

      // Build the table with all columns (async)
      final batchesTable = await _buildBatchesTable(batches);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build:
              (context) => [
                _buildPDFHeader('Reporte de Lotes de Inventario'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Producto: $productName',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 20),
                batchesTable,
                pw.SizedBox(height: 20),
                _buildPDFFooter(),
              ],
        ),
      );

      return await _savePDFWithPicker(
        pdf,
        'lotes_${productName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      throw Exception('Error descargando lotes a PDF: $e');
    }
  }

  static Future<pw.Widget> _buildBatchesTable(
    List<InventoryBatch> batches,
  ) async {
    // Obtain real supplier names and purchase order numbers
    final supplierNames = await _getSupplierNames(batches);
    final orderNumbers = await _getPurchaseOrderNumbers(batches);

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.3),
        7: const pw.FlexColumnWidth(1.3),
        8: const pw.FlexColumnWidth(1.3),
        9: const pw.FlexColumnWidth(1.3),
        10: const pw.FlexColumnWidth(1.2),
        11: const pw.FlexColumnWidth(1.0),
        12: const pw.FlexColumnWidth(1.5),
        13: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Número de Lote', isHeader: true),
            _buildTableCell('Fecha Entrada', isHeader: true),
            _buildTableCell('Vencimiento', isHeader: true),
            _buildTableCell('Cant. Inicial', isHeader: true),
            _buildTableCell('Cant. Actual', isHeader: true),
            _buildTableCell('Cant. Consumida', isHeader: true),
            _buildTableCell('Costo Unitario', isHeader: true),
            _buildTableCell('Valor Total', isHeader: true),
            _buildTableCell('Valor Consumido', isHeader: true),
            _buildTableCell('Valor Actual', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
            _buildTableCell('Días Stock', isHeader: true),
            _buildTableCell('Proveedor', isHeader: true),
            _buildTableCell('Orden Compra', isHeader: true),
          ],
        ),
        // Data rows
        ...batches.map(
          (batch) => pw.TableRow(
            children: [
              _buildTableCell(batch.batchNumber),
              _buildTableCell(AppFormatters.formatDate(batch.entryDate)),
              _buildTableCell(
                batch.hasExpiry
                    ? AppFormatters.formatDate(batch.expiryDate!)
                    : 'Sin vencimiento',
              ),
              _buildTableCell(batch.originalQuantity.toString()),
              _buildTableCell(batch.currentQuantity.toString()),
              _buildTableCell(
                (batch.originalQuantity - batch.currentQuantity).toString(),
              ),
              _buildTableCell(AppFormatters.formatCurrency(batch.unitCost)),
              _buildTableCell(AppFormatters.formatCurrency(batch.totalCost)),
              _buildTableCell(
                AppFormatters.formatCurrency(batch.consumedValue),
              ),
              _buildTableCell(AppFormatters.formatCurrency(batch.currentValue)),
              _buildTableCell(_getBatchStatusText(batch)),
              _buildTableCell(batch.daysInStock.toString()),
              _buildTableCell(
                supplierNames[batch.id] ?? batch.supplierName ?? 'N/A',
              ),
              _buildTableCell(
                batch.purchaseOrderId != null
                    ? (orderNumbers[batch.purchaseOrderId!] ??
                        batch.purchaseOrderNumber ??
                        'N/A')
                    : 'N/A',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _getBatchStatusText(InventoryBatch batch) {
    if (batch.isExpiredByDate) return 'Vencido';
    if (batch.isNearExpiry) return 'Próximo a vencer';
    if (batch.isConsumed) return 'Consumido';
    if (batch.isActive) return 'Activo';
    return 'Inactivo';
  }

  // ==================== FILE PICKER METHODS ====================

  /// Procesa movimientos de transferencia para evitar duplicados y mejorar claridad
  static List<InventoryMovement> _processTransferMovements(
    List<InventoryMovement> movements,
  ) {
    final Map<String, InventoryMovement> processedTransfers = {};
    final List<InventoryMovement> nonTransferMovements = [];

    for (final movement in movements) {
      if (movement.type == InventoryMovementType.transferOut ||
          movement.type == InventoryMovementType.transferIn) {
        // Para transferencias, usar un identificador único basado en metadata o fecha+producto
        String transferKey = '';

        if (movement.metadata != null) {
          // Intentar usar transferId o combinación de almacenes
          final transferId = movement.metadata!['transferId'] as String?;
          final originWarehouse =
              movement.metadata!['originWarehouse'] as String?;
          final destinationWarehouse =
              movement.metadata!['destinationWarehouse'] as String?;

          if (transferId != null) {
            transferKey = transferId;
          } else if (originWarehouse != null && destinationWarehouse != null) {
            transferKey =
                '${movement.productId}_${originWarehouse}_${destinationWarehouse}_${movement.createdAt.millisecondsSinceEpoch ~/ 1000}';
          } else {
            transferKey =
                '${movement.productId}_${movement.createdAt.millisecondsSinceEpoch ~/ 1000}';
          }
        } else {
          transferKey =
              '${movement.productId}_${movement.createdAt.millisecondsSinceEpoch ~/ 1000}';
        }

        // Solo agregar el primer movimiento de transferencia encontrado
        if (!processedTransfers.containsKey(transferKey)) {
          // Preferir transfer_out sobre transfer_in para mostrar la perspectiva del origen
          processedTransfers[transferKey] = movement;
        } else {
          // Si ya existe, preferir transfer_out
          final existing = processedTransfers[transferKey]!;
          if (existing.type == InventoryMovementType.transferIn &&
              movement.type == InventoryMovementType.transferOut) {
            processedTransfers[transferKey] = movement;
          }
        }
      } else {
        // Mantener movimientos que no son transferencias
        nonTransferMovements.add(movement);
      }
    }

    // Combinar transferencias procesadas con otros movimientos
    final result = <InventoryMovement>[
      ...processedTransfers.values,
      ...nonTransferMovements,
    ];

    // Ordenar por fecha de creación descendente
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  /// Extrae el nombre del almacén para transferencias considerando origen/destino
  static String _extractWarehouseName(
    InventoryMovement movement, {
    required bool isOrigin,
    List<Warehouse>? warehouses,
  }) {
    try {
      print(
        '🏢 DEBUG: Extrayendo nombre de almacén - isOrigin: $isOrigin, tipo: ${movement.type.name}',
      );
      print('🏢 DEBUG: Movement warehouseName: ${movement.warehouseName}');
      print('🏢 DEBUG: Movement metadata: ${movement.metadata}');
      print('🏢 DEBUG: Warehouses disponibles: ${warehouses?.length ?? 0}');

      // Helper function para buscar almacén por ID
      String? getWarehouseNameById(String? warehouseId) {
        if (warehouseId == null ||
            warehouseId.isEmpty ||
            warehouses == null ||
            warehouses.isEmpty) {
          return null;
        }

        try {
          final warehouse = warehouses.firstWhere((w) => w.id == warehouseId);
          print(
            '🏢 DEBUG: Encontrado almacén para ID $warehouseId: ${warehouse.name}',
          );
          return warehouse.name;
        } catch (e) {
          print('🏢 DEBUG: No se encontró almacén para ID: $warehouseId');
          return null;
        }
      }

      // Para transferencias, necesitamos manejar la lógica específica
      if (movement.type == InventoryMovementType.transferOut ||
          movement.type == InventoryMovementType.transferIn) {
        if (movement.metadata != null) {
          if (isOrigin) {
            // Para obtener el almacén de origen
            if (movement.type == InventoryMovementType.transferOut) {
              // Para transfer_out, el almacén actual es el origen
              final warehouseName = getWarehouseNameById(movement.warehouseId);
              if (warehouseName != null) {
                print('🏢 DEBUG: Origen (transfer_out): $warehouseName');
                return warehouseName;
              }
              return movement.warehouseName ?? 'Almacén origen';
            } else if (movement.type == InventoryMovementType.transferIn) {
              // Para transfer_in, el origen está en metadata
              final originWarehouseId =
                  movement.metadata!['originWarehouse'] as String?;
              final warehouseName = getWarehouseNameById(originWarehouseId);
              if (warehouseName != null) {
                print('🏢 DEBUG: Origen (transfer_in): $warehouseName');
                return warehouseName;
              }
              return 'Almacén origen';
            }
          } else {
            // Para obtener el almacén de destino
            if (movement.type == InventoryMovementType.transferOut) {
              // Para transfer_out, el destino está en metadata
              final destinationWarehouseId =
                  movement.metadata!['destinationWarehouse'] as String?;
              final warehouseName = getWarehouseNameById(
                destinationWarehouseId,
              );
              if (warehouseName != null) {
                print('🏢 DEBUG: Destino (transfer_out): $warehouseName');
                return warehouseName;
              }
              return 'Almacén destino';
            } else if (movement.type == InventoryMovementType.transferIn) {
              // Para transfer_in, el almacén actual es el destino
              final warehouseName = getWarehouseNameById(movement.warehouseId);
              if (warehouseName != null) {
                print('🏢 DEBUG: Destino (transfer_in): $warehouseName');
                return warehouseName;
              }
              return movement.warehouseName ?? 'Almacén destino';
            }
          }
        }

        // Fallback para transferencias sin metadata
        if (isOrigin) {
          return movement.warehouseName ?? 'Almacén origen';
        } else {
          return 'Almacén destino';
        }
      }

      // Para movimientos que no son transferencias
      if (isOrigin) {
        final warehouseName = getWarehouseNameById(movement.warehouseId);
        return warehouseName ?? movement.warehouseName ?? 'Almacén actual';
      } else {
        return 'N/A'; // No aplica destino para movimientos no-transferencia
      }
    } catch (e) {
      print('❌ Error extrayendo nombre de almacén: $e');
      return isOrigin ? 'Error en origen' : 'Error en destino';
    }
  }

  static Future<String> _saveExcelWithPicker(
    Excel excel,
    String filename,
  ) async {
    try {
      final bytes = excel.encode();
      if (bytes == null) throw Exception('No se pudo generar el archivo Excel');

      // Let user choose where to save
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo Excel',
        fileName: '$filename.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputPath == null) {
        throw Exception('Descarga cancelada por el usuario');
      }

      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      return outputPath;
    } catch (e) {
      throw Exception('Error guardando archivo Excel: $e');
    }
  }

  static Future<String> _savePDFWithPicker(
    pw.Document pdf,
    String filename,
  ) async {
    try {
      final bytes = await pdf.save();

      // Let user choose where to save
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo PDF',
        fileName: '$filename.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath == null) {
        throw Exception('Descarga cancelada por el usuario');
      }

      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      return outputPath;
    } catch (e) {
      throw Exception('Error guardando archivo PDF: $e');
    }
  }

  // ==================== NEW KARDEX REPORT EXPORTS ====================

  static Future<void> exportKardexReportToExcel(
    KardexReport kardexReport,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Kardex - ${kardexReport.product.name}'];

      // Remove default sheet
      excel.delete('Sheet1');

      int currentRow = 0;

      // Company header
      final companyCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      companyCell.value = TextCellValue(companyName);
      companyCell.cellStyle = CellStyle(bold: true, fontSize: 16);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow),
      );
      currentRow++;

      // Title
      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      titleCell.value = TextCellValue('KARDEX DE PRODUCTO');
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow),
      );
      currentRow += 2;

      // Product info
      final productInfoRows = [
        ['Producto:', kardexReport.product.name],
        ['SKU:', kardexReport.product.sku],
        ['Categoría:', kardexReport.product.categoryName ?? 'N/A'],
        [
          'Período:',
          '${AppFormatters.formatDate(kardexReport.period.startDate)} - ${AppFormatters.formatDate(kardexReport.period.endDate)}',
        ],
      ];

      for (final row in productInfoRows) {
        final labelCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        );
        labelCell.value = TextCellValue(row[0]);
        labelCell.cellStyle = CellStyle(bold: true);

        final valueCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        );
        valueCell.value = TextCellValue(row[1]);
        currentRow++;
      }
      currentRow++;

      // Summary section
      final summaryCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      summaryCell.value = TextCellValue('RESUMEN');
      summaryCell.cellStyle = CellStyle(bold: true, fontSize: 12);
      currentRow++;

      final summaryRows = [
        [
          'Saldo Inicial:',
          '${kardexReport.initialBalance.quantity.toInt()}',
          AppFormatters.formatCurrency(kardexReport.initialBalance.value),
        ],
        [
          'Total Entradas:',
          '${kardexReport.summary.totalEntries}',
          AppFormatters.formatCurrency(kardexReport.summary.totalPurchases),
        ],
        [
          'Total Salidas:',
          '${kardexReport.summary.totalExits}',
          AppFormatters.formatCurrency(kardexReport.summary.totalSales),
        ],
        [
          'Saldo Final:',
          '${kardexReport.finalBalance.quantity.toInt()}',
          AppFormatters.formatCurrency(kardexReport.finalBalance.value),
        ],
      ];

      for (final row in summaryRows) {
        final labelCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        );
        labelCell.value = TextCellValue(row[0]);
        labelCell.cellStyle = CellStyle(bold: true);

        final qtyCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        );
        qtyCell.value = TextCellValue(row[1]);

        final valueCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
        );
        valueCell.value = TextCellValue(row[2]);
        currentRow++;
      }
      currentRow += 2;

      // Movements header
      if (kardexReport.hasMovements) {
        final movementsHeaderCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        );
        movementsHeaderCell.value = TextCellValue('MOVIMIENTOS');
        movementsHeaderCell.cellStyle = CellStyle(bold: true, fontSize: 12);
        currentRow++;

        // Column headers
        final headers = [
          'Fecha',
          'N° Movimiento',
          'Tipo',
          'Descripción',
          'Entrada',
          'Salida',
          'Balance',
          'Costo Unit.',
          'Valor',
        ];
        for (int i = 0; i < headers.length; i++) {
          final headerCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
          );
          headerCell.value = TextCellValue(headers[i]);
          headerCell.cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
          );
        }
        currentRow++;

        // Movement rows
        for (final movement in kardexReport.movements) {
          final rowData = [
            AppFormatters.formatDate(movement.date),
            movement.movementNumber,
            movement.displayType,
            movement.description,
            movement.entryQuantity > 0
                ? movement.entryQuantity.toInt().toString()
                : '',
            movement.exitQuantity > 0
                ? movement.exitQuantity.toInt().toString()
                : '',
            movement.balance.toInt().toString(),
            AppFormatters.formatCurrency(movement.unitCost),
            AppFormatters.formatCurrency(movement.balanceValue),
          ];

          for (int i = 0; i < rowData.length; i++) {
            final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
            );
            cell.value = TextCellValue(rowData[i]);

            // Color code entries and exits
            if (i == 4 && movement.entryQuantity > 0) {
              cell.cellStyle = CellStyle(fontColorHex: ExcelColor.green);
            } else if (i == 5 && movement.exitQuantity > 0) {
              cell.cellStyle = CellStyle(fontColorHex: ExcelColor.red);
            }
          }
          currentRow++;
        }
      }

      // Save and share
      await _saveAndShareExcel(
        excel,
        'Kardex_${kardexReport.product.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      throw Exception('Error exportando kardex a Excel: $e');
    }
  }

  static Future<void> exportKardexReportToPDF(KardexReport kardexReport) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'KARDEX DE PRODUCTO',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Product info
                  pw.Table(
                    columnWidths: {
                      0: const pw.FixedColumnWidth(100),
                      1: const pw.FlexColumnWidth(),
                    },
                    children: [
                      _buildInfoRow('Producto:', kardexReport.product.name),
                      _buildInfoRow('SKU:', kardexReport.product.sku),
                      _buildInfoRow(
                        'Categoría:',
                        kardexReport.product.categoryName ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Período:',
                        '${AppFormatters.formatDate(kardexReport.period.startDate)} - ${AppFormatters.formatDate(kardexReport.period.endDate)}',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Summary
                  pw.Text(
                    'RESUMEN',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    columnWidths: {
                      0: const pw.FixedColumnWidth(120),
                      1: const pw.FixedColumnWidth(80),
                      2: const pw.FlexColumnWidth(),
                    },
                    border: pw.TableBorder.all(),
                    children: [
                      _buildSummaryRow(
                        'Concepto',
                        'Cantidad',
                        'Valor',
                        isHeader: true,
                      ),
                      _buildSummaryRow(
                        'Saldo Inicial',
                        '${kardexReport.initialBalance.quantity.toInt()}',
                        AppFormatters.formatCurrency(
                          kardexReport.initialBalance.value,
                        ),
                      ),
                      _buildSummaryRow(
                        'Total Entradas',
                        '${kardexReport.summary.totalEntries}',
                        AppFormatters.formatCurrency(
                          kardexReport.summary.totalPurchases,
                        ),
                      ),
                      _buildSummaryRow(
                        'Total Salidas',
                        '${kardexReport.summary.totalExits}',
                        AppFormatters.formatCurrency(
                          kardexReport.summary.totalSales,
                        ),
                      ),
                      _buildSummaryRow(
                        'Saldo Final',
                        '${kardexReport.finalBalance.quantity.toInt()}',
                        AppFormatters.formatCurrency(
                          kardexReport.finalBalance.value,
                        ),
                        isTotal: true,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Movements
                  if (kardexReport.hasMovements) ...[
                    pw.Text(
                      'MOVIMIENTOS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(60), // Fecha
                        1: const pw.FixedColumnWidth(70), // N° Movimiento
                        2: const pw.FixedColumnWidth(60), // Tipo
                        3: const pw.FlexColumnWidth(2), // Descripción
                        4: const pw.FixedColumnWidth(50), // Entrada
                        5: const pw.FixedColumnWidth(50), // Salida
                        6: const pw.FixedColumnWidth(50), // Balance
                        7: const pw.FixedColumnWidth(60), // Valor
                      },
                      children: [
                        // Header
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          children: [
                            _buildMovementCell('Fecha', isHeader: true),
                            _buildMovementCell('N° Mov.', isHeader: true),
                            _buildMovementCell('Tipo', isHeader: true),
                            _buildMovementCell('Descripción', isHeader: true),
                            _buildMovementCell('Entrada', isHeader: true),
                            _buildMovementCell('Salida', isHeader: true),
                            _buildMovementCell('Balance', isHeader: true),
                            _buildMovementCell('Valor', isHeader: true),
                          ],
                        ),
                        // Movements
                        ...kardexReport.movements.map(
                          (movement) => pw.TableRow(
                            children: [
                              _buildMovementCell(
                                AppFormatters.formatDate(movement.date),
                              ),
                              _buildMovementCell(movement.movementNumber),
                              _buildMovementCell(movement.displayType),
                              _buildMovementCell(
                                movement.description,
                                maxLines: 2,
                              ),
                              _buildMovementCell(
                                movement.entryQuantity > 0
                                    ? movement.entryQuantity.toInt().toString()
                                    : '',
                                color:
                                    movement.entryQuantity > 0
                                        ? PdfColors.green
                                        : null,
                              ),
                              _buildMovementCell(
                                movement.exitQuantity > 0
                                    ? movement.exitQuantity.toInt().toString()
                                    : '',
                                color:
                                    movement.exitQuantity > 0
                                        ? PdfColors.red
                                        : null,
                              ),
                              _buildMovementCell(
                                movement.balance.toInt().toString(),
                              ),
                              _buildMovementCell(
                                AppFormatters.formatCurrency(
                                  movement.balanceValue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ];
          },
        ),
      );

      await _saveAndSharePDF(
        pdf,
        'Kardex_${kardexReport.product.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      throw Exception('Error exportando kardex a PDF: $e');
    }
  }

  static pw.TableRow _buildInfoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(value)),
      ],
    );
  }

  static pw.TableRow _buildSummaryRow(
    String concept,
    String quantity,
    String value, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    final textStyle =
        isHeader || isTotal
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
            : const pw.TextStyle();
    final decoration =
        isHeader
            ? const pw.BoxDecoration(color: PdfColors.grey300)
            : isTotal
            ? const pw.BoxDecoration(color: PdfColors.grey100)
            : null;

    return pw.TableRow(
      decoration: decoration,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(concept, style: textStyle),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            quantity,
            style: textStyle,
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            value,
            style: textStyle,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMovementCell(
    String text, {
    bool isHeader = false,
    PdfColor? color,
    int maxLines = 1,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
          fontSize: 8,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  // ==================== ✅ NUEVOS MÉTODOS PROFESIONALES ====================

  /// Descargar kardex con picker para que usuario escoja la ruta
  static Future<String> downloadKardexToExcel(KardexReport kardexReport) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Kardex'];
      excel.delete('Sheet1');

      // Crear contenido del Excel (sin SKU)
      await _buildKardexExcelContent(sheet, kardexReport);

      // Usar picker para que usuario escoja dónde guardar
      final productName = kardexReport.product.name.replaceAll(' ', '_');
      final fileName = 'kardex_$productName';

      return await _saveExcelWithPicker(excel, fileName);
    } catch (e) {
      throw Exception('Error descargando kardex a Excel: $e');
    }
  }

  /// Descargar kardex como PDF con picker para que usuario escoja la ruta
  static Future<String> downloadKardexToPdf(KardexReport kardexReport) async {
    try {
      final pdf = pw.Document();

      // Crear contenido del PDF (sin SKU)
      await _buildKardexPdfContent(pdf, kardexReport);

      // Usar picker para que usuario escoja dónde guardar
      final productName = kardexReport.product.name.replaceAll(' ', '_');
      final fileName = 'kardex_$productName';

      return await _savePDFWithPicker(pdf, fileName);
    } catch (e) {
      throw Exception('Error descargando kardex a PDF: $e');
    }
  }

  /// Compartir kardex como PDF
  static Future<void> shareKardexToPdf(KardexReport kardexReport) async {
    try {
      final pdf = pw.Document();

      // Metadata del archivo (sin SKU)
      final productName = kardexReport.product.name;
      final period =
          '${AppFormatters.formatDate(kardexReport.period.startDate)} - ${AppFormatters.formatDate(kardexReport.period.endDate)}';
      final fileName =
          'Kardex_${productName}_${DateTime.now().millisecondsSinceEpoch}';

      // Crear contenido del PDF (sin SKU)
      await _buildKardexPdfContent(pdf, kardexReport);

      // Guardar temporalmente y compartir
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Kardex de $productName ($period)',
        subject: 'Kardex - $productName',
      );
    } catch (e) {
      throw Exception('Error compartiendo kardex: $e');
    }
  }

  /// Construir contenido del Excel para kardex
  static Future<void> _buildKardexExcelContent(
    Sheet sheet,
    KardexReport kardexReport,
  ) async {
    int currentRow = 0;

    // Encabezado de la empresa
    final companyCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    companyCell.value = TextCellValue(companyName);
    companyCell.cellStyle = CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );
    currentRow++;

    // Título
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    titleCell.value = TextCellValue('Kardex de Inventario');
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );
    currentRow++;

    // Información del producto (sin SKU)
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('Producto: ${kardexReport.product.name}');
    currentRow++;

    final period =
        '${AppFormatters.formatDate(kardexReport.period.startDate)} - ${AppFormatters.formatDate(kardexReport.period.endDate)}';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('Período: $period');
    currentRow++;

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue(
      'Fecha: ${AppFormatters.formatDateTime(DateTime.now())}',
    );
    currentRow += 2;

    // Resumen inicial
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('SALDO INICIAL');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = IntCellValue(kardexReport.initialBalance.quantity.toInt());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        .value = TextCellValue(
      AppFormatters.formatCurrency(kardexReport.initialBalance.value),
    );
    currentRow += 2;

    // Encabezados de movimientos
    final headers = [
      'Fecha',
      'Tipo',
      'Descripción',
      'Entrada',
      'Salida',
      'Saldo',
      'Valor Total',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }
    currentRow++;

    // Datos de movimientos
    for (final movement in kardexReport.movements) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = TextCellValue(AppFormatters.formatDate(movement.date));
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = TextCellValue(movement.movementType.toString());
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
          )
          .value = TextCellValue(movement.description);
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
          )
          .value = IntCellValue(movement.entryQuantity.toInt());
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
          )
          .value = IntCellValue(movement.exitQuantity.toInt());
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
          )
          .value = IntCellValue(movement.balance.toInt());
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
          )
          .value = TextCellValue(
        AppFormatters.formatCurrency(movement.balanceValue),
      );
      currentRow++;
    }

    currentRow++;

    // Resumen final
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        .value = TextCellValue('SALDO FINAL');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        .value = IntCellValue(kardexReport.finalBalance.quantity.toInt());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        .value = TextCellValue(
      AppFormatters.formatCurrency(kardexReport.finalBalance.value),
    );
  }

  /// Construir contenido del PDF para kardex
  static Future<void> _buildKardexPdfContent(
    pw.Document pdf,
    KardexReport kardexReport,
  ) async {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Kardex de Inventario',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Producto: ${kardexReport.product.name}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Período: ${AppFormatters.formatDate(kardexReport.period.startDate)} - ${AppFormatters.formatDate(kardexReport.period.endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Fecha: ${AppFormatters.formatDateTime(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            // Resumen inicial
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SALDO INICIAL:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${kardexReport.initialBalance.quantity.toInt()} unidades',
                  ),
                  pw.Text(
                    AppFormatters.formatCurrency(
                      kardexReport.initialBalance.value,
                    ),
                  ),
                ],
              ),
            ),

            // Tabla de movimientos
            _buildKardexMovementsTable(kardexReport.movements),

            pw.SizedBox(height: 20),

            // Resumen final
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SALDO FINAL:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${kardexReport.finalBalance.quantity.toInt()} unidades',
                  ),
                  pw.Text(
                    AppFormatters.formatCurrency(
                      kardexReport.finalBalance.value,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  static pw.Widget _buildKardexMovementsTable(List<KardexMovement> movements) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildMovementCell('Fecha', isHeader: true),
            _buildMovementCell('Tipo', isHeader: true),
            _buildMovementCell('Descripción', isHeader: true),
            _buildMovementCell('Entrada', isHeader: true),
            _buildMovementCell('Salida', isHeader: true),
            _buildMovementCell('Saldo', isHeader: true),
            _buildMovementCell('Valor', isHeader: true),
          ],
        ),
        // Data rows
        ...movements.map(
          (movement) => pw.TableRow(
            children: [
              _buildMovementCell(AppFormatters.formatDate(movement.date)),
              _buildMovementCell(
                movement.movementType.toString().split('.').last,
              ),
              _buildMovementCell(movement.description, maxLines: 2),
              _buildMovementCell(
                movement.entryQuantity > 0
                    ? movement.entryQuantity.toInt().toString()
                    : '',
              ),
              _buildMovementCell(
                movement.exitQuantity > 0
                    ? movement.exitQuantity.toInt().toString()
                    : '',
              ),
              _buildMovementCell(movement.balance.toInt().toString()),
              _buildMovementCell(
                AppFormatters.formatCurrency(movement.balanceValue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
