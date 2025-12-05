// lib/features/credit_notes/presentation/bindings/credit_note_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';

// Data Layer
import '../../data/datasources/credit_note_remote_datasource.dart';
import '../../data/repositories/credit_note_repository_impl.dart';

// Domain Layer
import '../../domain/repositories/credit_note_repository.dart';
import '../../domain/usecases/create_credit_note.dart';
import '../../domain/usecases/get_credit_note_by_id.dart';
import '../../domain/usecases/get_credit_notes.dart';
import '../../domain/usecases/get_credit_notes_by_invoice.dart';
import '../../domain/usecases/get_remaining_creditable_amount.dart';
import '../../domain/usecases/get_available_quantities_for_credit_note.dart';
import '../../domain/usecases/update_credit_note.dart';
import '../../domain/usecases/confirm_credit_note.dart';
import '../../domain/usecases/cancel_credit_note.dart';
import '../../domain/usecases/delete_credit_note.dart';
import '../../domain/usecases/download_credit_note_pdf.dart';
import '../../domain/usecases/sync_credit_notes.dart';

// Presentation Layer
import '../controllers/credit_note_list_controller.dart';
import '../controllers/credit_note_detail_controller.dart';
import '../controllers/credit_note_form_controller.dart';

// Other dependencies
import '../../../invoices/domain/usecases/get_invoice_by_id_usecase.dart';

class CreditNoteBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 CreditNoteBinding: Registrando dependencias...');

    // ==================== DATA SOURCES ====================
    Get.lazyPut<CreditNoteRemoteDataSource>(
      () {
        print('📡 Creando CreditNoteRemoteDataSource');
        return CreditNoteRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      },
      fenix: true,
    );

    // ==================== REPOSITORIES ====================
    Get.lazyPut<CreditNoteRepository>(
      () {
        print('💾 Creando CreditNoteRepository');
        return CreditNoteRepositoryImpl(
          remoteDataSource: Get.find<CreditNoteRemoteDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        );
      },
      fenix: true,
    );

    // ==================== USE CASES ====================
    Get.lazyPut<CreateCreditNote>(
      () => CreateCreditNote(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetCreditNoteById>(
      () => GetCreditNoteById(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetCreditNotes>(
      () => GetCreditNotes(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetCreditNotesByInvoice>(
      () => GetCreditNotesByInvoice(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetRemainingCreditableAmount>(
      () => GetRemainingCreditableAmount(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetAvailableQuantitiesForCreditNote>(
      () => GetAvailableQuantitiesForCreditNote(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<UpdateCreditNote>(
      () => UpdateCreditNote(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<ConfirmCreditNote>(
      () => ConfirmCreditNote(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<CancelCreditNote>(
      () => CancelCreditNote(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<DeleteCreditNote>(
      () => DeleteCreditNote(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<DownloadCreditNotePdf>(
      () => DownloadCreditNotePdf(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    Get.lazyPut<SyncCreditNotes>(
      () => SyncCreditNotes(Get.find<CreditNoteRepository>()),
      fenix: true,
    );

    // ==================== CONTROLLERS ====================
    // Controllers se registran bajo demanda según la pantalla

    print('✅ CreditNoteBinding: Todas las dependencias registradas');
  }
}

/// Binding específico para lista
class CreditNoteListBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurar que las dependencias base estén disponibles
    if (!Get.isRegistered<CreditNoteRepository>()) {
      CreditNoteBinding().dependencies();
    }

    Get.lazyPut<CreditNoteListController>(
      () => CreditNoteListController(
        getCreditNotesUseCase: Get.find<GetCreditNotes>(),
        deleteCreditNoteUseCase: Get.find<DeleteCreditNote>(),
        confirmCreditNoteUseCase: Get.find<ConfirmCreditNote>(),
        cancelCreditNoteUseCase: Get.find<CancelCreditNote>(),
        downloadCreditNotePdfUseCase: Get.find<DownloadCreditNotePdf>(),
      ),
    );
  }
}

/// Binding específico para detalle
class CreditNoteDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurar que las dependencias base estén disponibles
    if (!Get.isRegistered<CreditNoteRepository>()) {
      CreditNoteBinding().dependencies();
    }

    Get.lazyPut<CreditNoteDetailController>(
      () => CreditNoteDetailController(
        getCreditNoteByIdUseCase: Get.find<GetCreditNoteById>(),
        confirmCreditNoteUseCase: Get.find<ConfirmCreditNote>(),
        cancelCreditNoteUseCase: Get.find<CancelCreditNote>(),
        deleteCreditNoteUseCase: Get.find<DeleteCreditNote>(),
        downloadCreditNotePdfUseCase: Get.find<DownloadCreditNotePdf>(),
      ),
    );
  }
}

/// Binding específico para formulario (crear/editar)
class CreditNoteFormBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurar que las dependencias base estén disponibles
    if (!Get.isRegistered<CreditNoteRepository>()) {
      CreditNoteBinding().dependencies();
    }

    Get.lazyPut<CreditNoteFormController>(
      () => CreditNoteFormController(
        createCreditNoteUseCase: Get.find<CreateCreditNote>(),
        updateCreditNoteUseCase: Get.find<UpdateCreditNote>(),
        getCreditNoteByIdUseCase: Get.find<GetCreditNoteById>(),
        getRemainingCreditableAmountUseCase:
            Get.find<GetRemainingCreditableAmount>(),
        getAvailableQuantitiesUseCase:
            Get.find<GetAvailableQuantitiesForCreditNote>(),
        getInvoiceByIdUseCase: Get.find<GetInvoiceByIdUseCase>(),
      ),
    );
  }
}
