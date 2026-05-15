// lib/features/products/presentation/controllers/product_presentations_controller.dart
import 'package:get/get.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../domain/entities/product_presentation.dart';
import '../../domain/usecases/get_product_presentations_usecase.dart';
import '../../domain/usecases/create_product_presentation_usecase.dart';
import '../../domain/usecases/update_product_presentation_usecase.dart';
import '../../domain/usecases/delete_product_presentation_usecase.dart';

class ProductPresentationsController extends GetxController
    with SyncAutoRefreshMixin {
  final GetProductPresentationsUseCase getPresentationsUseCase;
  final CreateProductPresentationUseCase createPresentationUseCase;
  final UpdateProductPresentationUseCase updatePresentationUseCase;
  final DeleteProductPresentationUseCase deletePresentationUseCase;

  ProductPresentationsController({
    required this.getPresentationsUseCase,
    required this.createPresentationUseCase,
    required this.updatePresentationUseCase,
    required this.deletePresentationUseCase,
  });

  // ==================== STATE ====================

  final RxList<ProductPresentation> presentations =
      <ProductPresentation>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString productId = ''.obs;
  final RxString productName = ''.obs;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();

    final params = Get.parameters;
    final args = Get.arguments;

    final id = params['productId'] ??
        (args is Map ? args['productId'] as String? : null) ??
        '';
    productId.value = id;

    final name = params['productName'] ??
        (args is Map ? args['productName'] as String? : null) ??
        '';
    productName.value = name;

    if (productId.value.isNotEmpty) {
      loadPresentations();
    }
  }

  @override
  Future<void> onSyncCompleted() async {
    if (productId.value.isNotEmpty) {
      await loadPresentations();
    }
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> loadPresentations() async {
    if (productId.value.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';

    final result = await getPresentationsUseCase(
      GetProductPresentationsParams(productId: productId.value),
    );

    result.fold(
      (failure) {
        errorMessage.value = failure.message;
      },
      (list) {
        presentations.assignAll(list);
      },
    );

    isLoading.value = false;
  }

  Future<bool> createPresentation({
    required String name,
    required double factor,
    required double price,
    String? currency,
    String? barcode,
    String? sku,
    bool isDefault = false,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    isSaving.value = true;

    final result = await createPresentationUseCase(
      CreateProductPresentationParams(
        productId: productId.value,
        name: name,
        factor: factor,
        price: price,
        currency: currency,
        barcode: barcode,
        sku: sku,
        isDefault: isDefault,
        isActive: isActive,
        sortOrder: sortOrder,
      ),
    );

    isSaving.value = false;

    return result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      },
      (presentation) {
        if (isDefault) {
          // Clear previous default flag locally
          final updated = presentations
              .map(
                (p) => p.isDefault ? p.copyWith(isDefault: false) : p,
              )
              .toList();
          presentations.assignAll(updated);
        }
        presentations.add(presentation);
        Get.snackbar(
          'Creada',
          'Presentación "${presentation.name}" creada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        return true;
      },
    );
  }

  Future<bool> updatePresentation({
    required String id,
    String? name,
    double? factor,
    double? price,
    String? currency,
    String? barcode,
    String? sku,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
  }) async {
    isSaving.value = true;

    final result = await updatePresentationUseCase(
      UpdateProductPresentationParams(
        productId: productId.value,
        id: id,
        name: name,
        factor: factor,
        price: price,
        currency: currency,
        barcode: barcode,
        sku: sku,
        isDefault: isDefault,
        isActive: isActive,
        sortOrder: sortOrder,
      ),
    );

    isSaving.value = false;

    return result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      },
      (presentation) {
        if (isDefault == true) {
          // Clear previous default flag locally
          final updated = presentations
              .map(
                (p) => p.id == id
                    ? presentation
                    : p.copyWith(isDefault: false),
              )
              .toList();
          presentations.assignAll(updated);
        } else {
          final index = presentations.indexWhere((p) => p.id == id);
          if (index != -1) {
            presentations[index] = presentation;
          }
        }
        Get.snackbar(
          'Actualizada',
          'Presentación "${presentation.name}" actualizada',
          snackPosition: SnackPosition.TOP,
        );
        return true;
      },
    );
  }

  Future<bool> deletePresentation(String id) async {
    isSaving.value = true;

    final result = await deletePresentationUseCase(
      DeleteProductPresentationParams(
        productId: productId.value,
        id: id,
      ),
    );

    isSaving.value = false;

    return result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      },
      (_) {
        presentations.removeWhere((p) => p.id == id);
        Get.snackbar(
          'Eliminada',
          'Presentación eliminada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        return true;
      },
    );
  }

  // ==================== HELPERS ====================

  bool get hasPresentations => presentations.isNotEmpty;

  ProductPresentation? get defaultPresentation =>
      presentations.where((p) => p.isDefault).firstOrNull;
}
