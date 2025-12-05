// lib/features/credit_notes/presentation/controllers/credit_note_list_controller.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/usecases/get_credit_notes.dart';
import '../../domain/usecases/delete_credit_note.dart';
import '../../domain/usecases/confirm_credit_note.dart';
import '../../domain/usecases/cancel_credit_note.dart';
import '../../domain/usecases/download_credit_note_pdf.dart';
import '../../domain/repositories/credit_note_repository.dart';

class CreditNoteListController extends GetxController {
  // Dependencies
  final GetCreditNotes _getCreditNotesUseCase;
  final DeleteCreditNote _deleteCreditNoteUseCase;
  final ConfirmCreditNote _confirmCreditNoteUseCase;
  final CancelCreditNote _cancelCreditNoteUseCase;
  final DownloadCreditNotePdf _downloadCreditNotePdfUseCase;

  CreditNoteListController({
    required GetCreditNotes getCreditNotesUseCase,
    required DeleteCreditNote deleteCreditNoteUseCase,
    required ConfirmCreditNote confirmCreditNoteUseCase,
    required CancelCreditNote cancelCreditNoteUseCase,
    required DownloadCreditNotePdf downloadCreditNotePdfUseCase,
  })  : _getCreditNotesUseCase = getCreditNotesUseCase,
        _deleteCreditNoteUseCase = deleteCreditNoteUseCase,
        _confirmCreditNoteUseCase = confirmCreditNoteUseCase,
        _cancelCreditNoteUseCase = cancelCreditNoteUseCase,
        _downloadCreditNotePdfUseCase = downloadCreditNotePdfUseCase;

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isRefreshing = false.obs;

  // Datos
  final _creditNotes = <CreditNote>[].obs;
  final _paginationMeta = Rxn<PaginationMeta>();

  // Filtros y búsqueda
  final _searchQuery = ''.obs;
  final _selectedStatus = Rxn<CreditNoteStatus>();
  final _selectedType = Rxn<CreditNoteType>();
  final _selectedReason = Rxn<CreditNoteReason>();
  final _invoiceId = Rxn<String>();
  final _customerId = Rxn<String>();
  final _startDate = Rxn<DateTime>();
  final _endDate = Rxn<DateTime>();
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;

  // Paginación
  final _currentPage = 1.obs;
  final _itemsPerPage = 20.obs;

  // Controllers
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Timer para debounce de búsqueda
  Timer? _searchDebounceTimer;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get hasData => _creditNotes.isNotEmpty;
  bool get isEmpty => !isLoading && _creditNotes.isEmpty;

  List<CreditNote> get creditNotes => _creditNotes;
  PaginationMeta? get paginationMeta => _paginationMeta.value;

  String get searchQuery => _searchQuery.value;
  CreditNoteStatus? get selectedStatus => _selectedStatus.value;
  CreditNoteType? get selectedType => _selectedType.value;
  CreditNoteReason? get selectedReason => _selectedReason.value;
  String? get invoiceId => _invoiceId.value;
  String? get customerId => _customerId.value;
  DateTime? get startDate => _startDate.value;
  DateTime? get endDate => _endDate.value;

  int get currentPage => _currentPage.value;
  bool get hasNextPage => paginationMeta?.hasNextPage ?? false;
  bool get hasPreviousPage => paginationMeta?.hasPreviousPage ?? false;
  bool get hasFilters =>
      searchQuery.isNotEmpty ||
      selectedStatus != null ||
      selectedType != null ||
      selectedReason != null ||
      invoiceId != null ||
      customerId != null ||
      startDate != null ||
      endDate != null;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _setupSearchListener();
    _setupScrollListener();
    loadCreditNotes();
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ==================== SETUP ====================

  void _setupSearchListener() {
    searchController.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _searchQuery.value = searchController.text;
        _currentPage.value = 1;
        loadCreditNotes();
      });
    });
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent * 0.8 &&
          !isLoadingMore &&
          hasNextPage) {
        loadMoreCreditNotes();
      }
    });
  }

  // ==================== DATA LOADING ====================

  Future<void> loadCreditNotes({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading.value = true;
    }

    try {
      final params = QueryCreditNotesParams(
        page: _currentPage.value,
        limit: _itemsPerPage.value,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        status: selectedStatus,
        type: selectedType,
        reason: selectedReason,
        invoiceId: invoiceId,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        sortBy: _sortBy.value,
        sortOrder: _sortOrder.value,
      );

      final result = await _getCreditNotesUseCase(params);

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
        (paginatedResult) {
          if (_currentPage.value == 1) {
            _creditNotes.value = paginatedResult.data;
          } else {
            _creditNotes.addAll(paginatedResult.data);
          }
          _paginationMeta.value = paginatedResult.meta;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadMoreCreditNotes() async {
    if (!hasNextPage || isLoadingMore) return;

    _isLoadingMore.value = true;
    _currentPage.value++;

    try {
      await loadCreditNotes(showLoading: false);
    } finally {
      _isLoadingMore.value = false;
    }
  }

  Future<void> refreshCreditNotes() async {
    _isRefreshing.value = true;
    _currentPage.value = 1;
    await loadCreditNotes(showLoading: false);
    _isRefreshing.value = false;
  }

  // ==================== FILTERS ====================

  void setStatusFilter(CreditNoteStatus? status) {
    _selectedStatus.value = status;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void setTypeFilter(CreditNoteType? type) {
    _selectedType.value = type;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void setReasonFilter(CreditNoteReason? reason) {
    _selectedReason.value = reason;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void setInvoiceFilter(String? id) {
    _invoiceId.value = id;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void setCustomerFilter(String? id) {
    _customerId.value = id;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate.value = start;
    _endDate.value = end;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void clearFilters() {
    searchController.clear();
    _searchQuery.value = '';
    _selectedStatus.value = null;
    _selectedType.value = null;
    _selectedReason.value = null;
    _invoiceId.value = null;
    _customerId.value = null;
    _startDate.value = null;
    _endDate.value = null;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  void setSorting(String sortBy, String sortOrder) {
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _currentPage.value = 1;
    loadCreditNotes();
  }

  // ==================== ACTIONS ====================

  Future<void> confirmCreditNote(String id) async {
    try {
      final result = await _confirmCreditNoteUseCase(id);

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
          // Actualizar la lista
          final index = _creditNotes.indexWhere((cn) => cn.id == id);
          if (index != -1) {
            _creditNotes[index] = creditNote;
            _creditNotes.refresh();
          }

          Get.snackbar(
            'Confirmada',
            'Nota de crédito confirmada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al confirmar: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> cancelCreditNote(String id) async {
    try {
      final result = await _cancelCreditNoteUseCase(id);

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
          // Actualizar la lista
          final index = _creditNotes.indexWhere((cn) => cn.id == id);
          if (index != -1) {
            _creditNotes[index] = creditNote;
            _creditNotes.refresh();
          }

          Get.snackbar(
            'Cancelada',
            'Nota de crédito cancelada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cancelar: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteCreditNote(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar esta nota de crédito?'),
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

    try {
      final result = await _deleteCreditNoteUseCase(id);

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
          // Remover de la lista
          _creditNotes.removeWhere((cn) => cn.id == id);

          Get.snackbar(
            'Eliminada',
            'Nota de crédito eliminada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== PDF DOWNLOAD ====================

  Future<void> downloadPdf(String id) async {
    try {
      Get.snackbar(
        'Descargando',
        'Generando PDF...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      final result = await _downloadCreditNotePdfUseCase(id);

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
        (pdfBytes) async {
          // Encontrar la nota de crédito para obtener el número
          final creditNote = _creditNotes.firstWhereOrNull((cn) => cn.id == id);
          final fileName = creditNote != null
              ? 'nota-credito-${creditNote.number}.pdf'
              : 'nota-credito-$id.pdf';

          // Guardar el PDF
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(pdfBytes);

          Get.snackbar(
            'Descarga Completa',
            'PDF guardado en: $filePath',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al descargar PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== NAVIGATION ====================

  void goToDetail(String id) {
    Get.toNamed('/credit-notes/detail/$id');
  }

  void goToCreate({String? invoiceId}) {
    if (invoiceId != null) {
      Get.toNamed('/credit-notes/create', arguments: {'invoiceId': invoiceId});
    } else {
      Get.toNamed('/credit-notes/create');
    }
  }

  void goToEdit(String id) {
    Get.toNamed('/credit-notes/edit/$id');
  }
}
