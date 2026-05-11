// lib/features/invoices/presentation/bindings/product_exchange_binding.dart
import 'package:get/get.dart';

import '../../../credit_notes/domain/repositories/credit_note_repository.dart';
import '../../../customer_credits/domain/repositories/customer_credit_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/usecases/exchange_products_usecase.dart';
import '../controllers/product_exchange_controller.dart';

/// Binding del flujo "Cambio de producto". Reutiliza repositorios ya
/// registrados por otros bindings (CreditNote, Invoice, CustomerCredit) —
/// si alguno no está, falla con error claro en lugar de duplicar la
/// instancia y perder el estado offline.
class ProductExchangeBinding extends Bindings {
  @override
  void dependencies() {
    // UseCase principal
    Get.lazyPut<ExchangeProductsUseCase>(
      () => ExchangeProductsUseCase(
        creditNoteRepository: Get.find<CreditNoteRepository>(),
        invoiceRepository: Get.find<InvoiceRepository>(),
        customerCreditRepository: Get.find<CustomerCreditRepository>(),
      ),
      fenix: true,
    );

    // Controller
    Get.lazyPut<ProductExchangeController>(
      () => ProductExchangeController(
        exchangeUseCase: Get.find<ExchangeProductsUseCase>(),
        invoiceRepository: Get.find<InvoiceRepository>(),
      ),
      fenix: true,
    );
  }
}
