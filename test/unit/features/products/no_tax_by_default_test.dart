import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// El POS no maneja impuestos: un producto solo lleva IVA si alguien lo
/// configura como gravado. Antes todas las capas suponían IVA 19% y los
/// productos creados sin indicarlo quedaban gravados; sus ventas se partían
/// en "venta + IVA" y la ganancia salía más baja de lo real.
void main() {
  test('Product sin datos de impuesto no lleva IVA', () {
    final product = Product(
      id: 'p1',
      name: 'Chorizos',
      sku: 'CH1',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: 0,
      minStock: 0,
      categoryId: 'c1',
      createdById: 'u1',
      createdAt: DateTime(2026, 10, 14),
      updatedAt: DateTime(2026, 10, 14),
    );
    expect(product.isTaxable, isFalse);
    expect(product.taxRate, 0);
    expect(product.taxCategory, TaxCategory.noGravado);
  });

  test('JSON sin campos de impuesto se lee sin IVA', () {
    final model = ProductModel.fromJson({
      'id': 'p1',
      'name': 'Chorizos',
      'sku': 'CH1',
      'type': 'product',
      'status': 'active',
      'stock': 10,
      'minStock': 0,
      'categoryId': 'c1',
      'createdById': 'u1',
    });
    expect(model.isTaxable, isFalse);
    expect(model.taxRate, 0);
    expect(model.taxCategory, 'NO_GRAVADO');
  });

  test('categoría desconocida = sin IVA', () {
    expect(TaxCategory.fromString('???'), TaxCategory.noGravado);
    expect(IsarProduct.mapTaxCategoryFromString('???'),
        IsarTaxCategory.noGravado);
    // Las conocidas se respetan.
    expect(TaxCategory.fromString('IVA'), TaxCategory.iva);
    expect(IsarProduct.mapTaxCategoryFromString('IVA'), IsarTaxCategory.iva);
  });

  test('producto local (ISAR) nuevo no lleva IVA', () {
    final isar = IsarProduct.create(
      serverId: 'p1',
      name: 'Chorizos',
      sku: 'CH1',
      type: IsarProductType.product,
      status: IsarProductStatus.active,
      stock: 0,
      minStock: 0,
      categoryId: 'c1',
      createdById: 'u1',
      createdAt: DateTime(2026, 10, 14),
      updatedAt: DateTime(2026, 10, 14),
      isSynced: true,
    );
    expect(isar.isTaxable, isFalse);
    expect(isar.taxRate, 0);
    expect(isar.taxCategory, IsarTaxCategory.noGravado);
  });
}
