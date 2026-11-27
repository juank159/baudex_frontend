// Pantalla "Editar producto": caso real del dueño. Un producto ya registrado
// SIN código de barras; lo edita, escribe "0013390" (7 dígitos, ceros
// adelante) y guarda. Antes salía "Código de barras inválido" (se exigían de
// 8 a 18 caracteres) y no se podía guardar.
//
// Se recorre la pantalla de verdad: se escribe en el campo, se toca
// "Actualizar" y se mira lo que llega al repositorio.
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:baudex_desktop/features/categories/domain/usecases/create_category_usecase.dart';
import 'package:baudex_desktop/features/categories/domain/usecases/get_categories_usecase.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/create_product_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_product_by_id_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/update_product_usecase.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_form_controller.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_form_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/category_fixtures.dart';
import '../../../fixtures/product_fixtures.dart';

class _Storage extends Mock implements SecureStorageService {}

class _GetCategories extends Mock implements GetCategoriesUseCase {}

class _CreateCategory extends Mock implements CreateCategoryUseCase {}

/// Repositorio de mentira: guarda lo que le llega.
class _Repo extends Mock implements ProductRepository {
  _Repo(this.product);
  final Product product;
  final updates = <String?>[];
  final barcodeChecks = <String>[];
  Set<String> takenBarcodes = {};

  @override
  Future<Either<Failure, Product>> getProductById(String id) async =>
      Right(product);

  @override
  Future<Either<Failure, bool>> existsByName(String name,
          {String? excludeId}) async =>
      const Right(false);

  @override
  Future<Either<Failure, bool>> existsBySku(String sku,
          {String? excludeId}) async =>
      const Right(false);

  @override
  Future<Either<Failure, bool>> existsByBarcode(String barcode,
      {String? excludeId}) async {
    barcodeChecks.add(barcode);
    return Right(takenBarcodes.contains(barcode));
  }

  @override
  Future<Either<Failure, Product>> updateProduct({
    required String id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    ProductType? type,
    ProductStatus? status,
    double? stock,
    double? minStock,
    String? unit,
    double? weight,
    double? length,
    double? width,
    double? height,
    List<String>? images,
    Map<String, dynamic>? metadata,
    String? categoryId,
    List<CreateProductPriceParams>? prices,
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
  }) async {
    updates.add(barcode);
    return Right(product);
  }
}

void main() {
  late _Repo repo;
  late _Storage storage;
  late _GetCategories getCategories;

  final category = CategoryFixtures.createCategoryEntity(
      id: 'cat-001', name: 'Abarrotes');
  final sinCodigo = ProductFixtures.createProductEntity(
    id: 'p1',
    name: 'Panela',
    sku: 'PAN-1',
    barcode: null,
    taxCategory: TaxCategory.noGravado,
    taxRate: 0,
    isTaxable: false,
  );

  setUpAll(() {
    registerFallbackValue(const GetCategoriesParams());
  });

  setUp(() {
    Get.testMode = true;
    ProductFormController.clearCategoriesCache();
    repo = _Repo(sinCodigo);
    storage = _Storage();
    getCategories = _GetCategories();
    when(() => storage.getTenantSlug()).thenAnswer((_) async => 'tienda');
    when(() => getCategories(any())).thenAnswer((_) async => Right(
          PaginatedResult<Category>(
            data: [category],
            meta: const PaginationMeta(
              page: 1,
              limit: 100,
              totalItems: 1,
              totalPages: 1,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
          ),
        ));
  });

  tearDown(Get.reset);

  Future<void> openEdit(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/products',
      getPages: [
        GetPage(
            name: '/products',
            page: () => const Scaffold(body: Text('Lista de productos'))),
        GetPage(
          name: '/products/edit/:id',
          page: () => const ProductFormScreen(),
          binding: BindingsBuilder(() {
            Get.put(ProductFormController(
              createProductUseCase: CreateProductUseCase(repo),
              updateProductUseCase: UpdateProductUseCase(repo),
              getProductByIdUseCase: GetProductByIdUseCase(repo),
              getCategoriesUseCase: getCategories,
              createCategoryUseCase: _CreateCategory(),
              secureStorageService: storage,
              productRepository: repo,
            ));
          }),
        ),
      ],
    ));
    Get.toNamed('/products/edit/p1');
    await tester.pumpAndSettle();
    expect(find.text('Editar Producto'), findsWidgets);
  }

  Finder barcodeField() => find.descendant(
        of: find.ancestor(
          of: find.text('Código de Barras'),
          matching: find.byType(TextFormField),
        ),
        matching: find.byType(EditableText),
      );

  Future<void> typeBarcodeAndSave(WidgetTester tester, String code) async {
    expect(Get.find<ProductFormController>().barcodeController.text, isEmpty,
        reason: 'el producto no tenía código');
    await tester.enterText(barcodeField(), code);
    await tester.pump();
    final save = find.text('Actualizar');
    await tester.ensureVisible(save.first);
    await tester.tap(save.first);
    await tester.pumpAndSettle();
  }

  Future<void> drainSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('"0013390" se guarda tal cual, con los ceros adelante',
      (tester) async {
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '0013390');
    expect(find.text('Código de barras inválido'), findsNothing);
    expect(repo.barcodeChecks, ['0013390'],
        reason: 'se revisa el duplicado con el código exacto');
    expect(repo.updates, ['0013390']);
    await drainSnackbars(tester);
  });

  testWidgets('con espacios a los lados se guarda sin ellos', (tester) async {
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '  0013390 ');
    expect(repo.updates, ['0013390']);
    await drainSnackbars(tester);
  });

  testWidgets('un código de 1 carácter se guarda', (tester) async {
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '7');
    expect(repo.updates, ['7']);
    await drainSnackbars(tester);
  });

  testWidgets('más de 20 caracteres: mensaje claro y no se guarda',
      (tester) async {
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '1' * 21);
    expect(
        find.text('El código de barras no puede tener más de 20 caracteres'),
        findsOneWidget);
    expect(repo.updates, isEmpty);
  });

  testWidgets('con un espacio en medio: mensaje claro y no se guarda',
      (tester) async {
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '001 3390');
    expect(find.text('El código de barras no puede tener espacios'),
        findsOneWidget);
    expect(repo.updates, isEmpty);
  });

  testWidgets('"0013390" ya lo tiene otro producto: no se guarda (duplicado)',
      (tester) async {
    repo.takenBarcodes = {'0013390'};
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '0013390');
    expect(repo.barcodeChecks, ['0013390']);
    expect(repo.updates, isEmpty);
    await drainSnackbars(tester);
  });

  testWidgets('sin código sigue guardando (es opcional)', (tester) async {
    await openEdit(tester);
    await typeBarcodeAndSave(tester, '');
    expect(repo.barcodeChecks, isEmpty);
    expect(repo.updates, [null]);
    await drainSnackbars(tester);
  });
}
