// lib/features/credit_notes/data/credit_note_pdf_builder.dart
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/core/utils/formatters.dart';
import '../domain/entities/credit_note.dart';

/// PDF de una nota crédito generado en el equipo, para descargarlo sin
/// conexión (con internet se usa el del servidor). Mismos datos: número,
/// fecha, factura, cliente, motivo, productos y totales.
class CreditNotePdfBuilder {
  CreditNotePdfBuilder._();

  static Future<Uint8List> build(CreditNote note) async {
    String money(double v) => AppFormatters.formatCurrency(v);
    String date(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final customer = note.customer;
    final customerName = customer == null
        ? ''
        : (customer.companyName?.isNotEmpty == true
            ? customer.companyName!
            : '${customer.firstName} ${customer.lastName}'.trim());

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('NOTA CRÉDITO',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(note.number,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Fecha: ${date(note.date)}'),
          pw.Text('Factura: ${note.invoice?.number ?? note.invoiceId}'),
          if (customerName.isNotEmpty) pw.Text('Cliente: $customerName'),
          pw.Text('Tipo: ${note.type.displayName}   Estado: ${note.status.displayName}'),
          pw.Text('Motivo: ${note.reason.displayName}'
              '${note.reasonDescription?.isNotEmpty == true ? ' - ${note.reasonDescription}' : ''}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Producto', 'Cantidad', 'Precio', 'Subtotal'],
            data: [
              for (final item in note.items)
                [
                  item.description,
                  item.quantity % 1 == 0
                      ? item.quantity.toStringAsFixed(0)
                      : item.quantity.toStringAsFixed(2),
                  money(item.unitPrice),
                  money(item.subtotal),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ${money(note.subtotal)}'),
                pw.Text('IVA (${note.taxPercentage.toStringAsFixed(0)}%): ${money(note.taxAmount)}'),
                pw.Text('Total: ${money(note.total)}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          if (note.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 16),
            pw.Text('Notas: ${note.notes}'),
          ],
        ],
      ),
    );
    return doc.save();
  }
}
