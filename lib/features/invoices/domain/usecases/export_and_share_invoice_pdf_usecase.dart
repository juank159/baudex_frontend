// lib/features/invoices/domain/usecases/export_and_share_invoice_pdf_usecase.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

/// Use case para exportar y compartir PDF de factura
///
/// Este use case descarga el PDF desde el backend y permite:
/// 1. Guardarlo en el dispositivo
/// 2. Compartirlo vía WhatsApp, email, etc usando share_plus
class ExportAndShareInvoicePdfUseCase {
  final InvoiceRepository repository;

  ExportAndShareInvoicePdfUseCase({required this.repository});

  /// Descargar PDF y compartirlo
  ///
  /// [invoiceId] - ID de la factura
  /// [invoiceNumber] - Número de factura para el nombre del archivo
  /// [shareDirectly] - Si es true, comparte inmediatamente. Si es false, solo descarga
  Future<Either<Failure, ShareResult?>> call({
    required String invoiceId,
    required String invoiceNumber,
    bool shareDirectly = true,
  }) async {
    try {

      // 1. Descargar PDF desde el backend
      final result = await repository.downloadInvoicePdf(invoiceId);

      return result.fold(
        (failure) {
          return Left(failure);
        },
        (pdfBytes) async {
          try {
            // 2. Guardar PDF en archivo temporal
            final fileName = 'Factura-$invoiceNumber.pdf';
            final filePath = await _savePdfToFile(pdfBytes, fileName);

            if (shareDirectly) {
              // 3. Compartir usando share_plus
              final shareResult = await Share.shareXFiles(
                [XFile(filePath)],
                text: 'Factura $invoiceNumber',
                subject: 'Factura $invoiceNumber - Baudex',
              );

              return Right(shareResult);
            } else {
              // Solo descargado, no compartir
              return const Right(null);
            }
          } catch (e) {
            return Left(CacheFailure('Error al procesar PDF: $e'));
          }
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error inesperado al exportar PDF: $e'));
    }
  }

  /// Guardar bytes de PDF en archivo temporal
  Future<String> _savePdfToFile(List<int> pdfBytes, String fileName) async {
    try {
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();

      // Crear subdirectorio para PDFs si no existe
      final pdfDir = Directory('${tempDir.path}/invoices_pdf');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      // Crear archivo
      final filePath = '${pdfDir.path}/$fileName';
      final file = File(filePath);

      // Escribir bytes
      await file.writeAsBytes(pdfBytes);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener ruta del archivo PDF guardado
  ///
  /// Útil para abrir el PDF en un visor externo
  Future<String?> getSavedPdfPath(String invoiceNumber) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Factura-$invoiceNumber.pdf';
      final filePath = '${tempDir.path}/invoices_pdf/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
