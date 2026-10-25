import 'dart:convert';

import 'package:baudex_desktop/features/credit_notes/data/credit_note_pdf_builder.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// El PDF de la nota crédito se puede generar en el equipo (sin internet).
void main() {
  test('genera un PDF válido con los datos de la nota', () async {
    final now = DateTime(2026, 10, 25);
    final note = CreditNote(
      id: 'creditnote_offline_1',
      number: 'NC-OFFLINE-123',
      date: now,
      type: CreditNoteType.partial,
      reason: CreditNoteReason.returnedGoods,
      status: CreditNoteStatus.confirmed,
      subtotal: 12000,
      taxPercentage: 0,
      taxAmount: 0,
      total: 12000,
      invoiceId: 'f1',
      customerId: 'c',
      createdById: 'u',
      items: [
        CreditNoteItem(
          id: 'i1', description: 'Huevo caja x12', quantity: 2, unitPrice: 6000,
          discountPercentage: 0, discountAmount: 0, subtotal: 12000,
          creditNoteId: 'creditnote_offline_1', createdAt: now, updatedAt: now),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final bytes = await CreditNotePdfBuilder.build(note);

    expect(bytes.length, greaterThan(500));
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
