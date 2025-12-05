// lib/features/credit_notes/presentation/controllers/credit_note_detail_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/usecases/get_credit_note_by_id.dart';
import '../../domain/usecases/confirm_credit_note.dart';
import '../../domain/usecases/cancel_credit_note.dart';
import '../../domain/usecases/delete_credit_note.dart';
import '../../domain/usecases/download_credit_note_pdf.dart';

class CreditNoteDetailController extends GetxController {
  // Dependencies
  final GetCreditNoteById _getCreditNoteByIdUseCase;
  final ConfirmCreditNote _confirmCreditNoteUseCase;
  final CancelCreditNote _cancelCreditNoteUseCase;
  final DeleteCreditNote _deleteCreditNoteUseCase;
  final DownloadCreditNotePdf _downloadCreditNotePdfUseCase;

  CreditNoteDetailController({
    required GetCreditNoteById getCreditNoteByIdUseCase,
    required ConfirmCreditNote confirmCreditNoteUseCase,
    required CancelCreditNote cancelCreditNoteUseCase,
    required DeleteCreditNote deleteCreditNoteUseCase,
    required DownloadCreditNotePdf downloadCreditNotePdfUseCase,
  })  : _getCreditNoteByIdUseCase = getCreditNoteByIdUseCase,
        _confirmCreditNoteUseCase = confirmCreditNoteUseCase,
        _cancelCreditNoteUseCase = cancelCreditNoteUseCase,
        _deleteCreditNoteUseCase = deleteCreditNoteUseCase,
        _downloadCreditNotePdfUseCase = downloadCreditNotePdfUseCase;

  // ==================== OBSERVABLES ====================

  final _isLoading = false.obs;
  final _isProcessing = false.obs;
  final _isDownloadingPdf = false.obs;
  final _creditNote = Rxn<CreditNote>();

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isProcessing => _isProcessing.value;
  bool get isDownloadingPdf => _isDownloadingPdf.value;
  CreditNote? get creditNote => _creditNote.value;
  bool get hasData => _creditNote.value != null;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'];
    if (id != null) {
      loadCreditNote(id);
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadCreditNote(String id) async {
    _isLoading.value = true;

    try {
      final result = await _getCreditNoteByIdUseCase(id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        (creditNote) {
          _creditNote.value = creditNote;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshCreditNote() async {
    if (creditNote != null) {
      await loadCreditNote(creditNote!.id);
    }
  }

  // ==================== ACTIONS ====================

  Future<void> confirmCreditNote() async {
    if (creditNote == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Nota de Crédito'),
        content: const Text(
          '¿Está seguro de confirmar esta nota de crédito? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isProcessing.value = true;

    try {
      final result = await _confirmCreditNoteUseCase(creditNote!.id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        (updatedCreditNote) {
          _creditNote.value = updatedCreditNote;
          Get.snackbar(
            'Confirmada',
            'Nota de crédito confirmada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> cancelCreditNote() async {
    if (creditNote == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancelar Nota de Crédito'),
        content: const Text(
          '¿Está seguro de cancelar esta nota de crédito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isProcessing.value = true;

    try {
      final result = await _cancelCreditNoteUseCase(creditNote!.id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        (updatedCreditNote) {
          _creditNote.value = updatedCreditNote;
          Get.snackbar(
            'Cancelada',
            'Nota de crédito cancelada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        },
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> deleteCreditNote() async {
    if (creditNote == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar Nota de Crédito'),
        content: const Text(
          '¿Está seguro de eliminar esta nota de crédito? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isProcessing.value = true;

    try {
      final result = await _deleteCreditNoteUseCase(creditNote!.id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        (_) {
          Get.back(); // Volver a la lista
          Get.snackbar(
            'Eliminada',
            'Nota de crédito eliminada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> downloadPdf() async {
    if (creditNote == null) return;

    _isDownloadingPdf.value = true;

    try {
      final result = await _downloadCreditNotePdfUseCase(creditNote!.id);

      await result.fold(
        (failure) async {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        (pdfBytes) async {
          // Guardar el PDF
          final directory = await getApplicationDocumentsDirectory();
          final file = File(
            '${directory.path}/credit_note_${creditNote!.number}.pdf',
          );
          await file.writeAsBytes(pdfBytes);

          Get.snackbar(
            'Descarga Completa',
            'PDF guardado en: ${file.path}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        },
      );
    } finally {
      _isDownloadingPdf.value = false;
    }
  }

  // ==================== NAVIGATION ====================

  void goToEdit() {
    if (creditNote != null && creditNote!.canBeEdited) {
      Get.toNamed('/credit-notes/edit/${creditNote!.id}');
    }
  }

  void goToInvoice() {
    if (creditNote != null) {
      Get.toNamed('/invoices/${creditNote!.invoiceId}');
    }
  }

  void goToCustomer() {
    if (creditNote != null) {
      Get.toNamed('/customers/${creditNote!.customerId}');
    }
  }
}
