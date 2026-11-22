// CREATE de producto offline armado desde Isar: no debe perder el impuesto
// ni las ediciones de los UPDATE que la limpieza de duplicados borra.
import 'package:baudex_desktop/features/products/data/sync/queued_product_request.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 22);

Product local({
  TaxCategory tax = TaxCategory.noGravado,
  double rate = 0,
  bool taxable = false,
  RetentionCategory? ret,
  double? retRate,
  bool hasRet = false,
  String? unit = 'und',
  List<ProductPrice>? prices,
}) =>
    Product(
      id: 'product_offline_1',
      name: 'Gaseosa',
      sku: 'GAS-1',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: 5,
      minStock: 1,
      unit: unit,
      categoryId: 'cat-1',
      createdById: 'u',
      createdAt: _now,
      updatedAt: _now,
      prices: prices,
      taxCategory: tax,
      taxRate: rate,
      isTaxable: taxable,
      retentionCategory: ret,
      retentionRate: retRate,
      hasRetention: hasRet,
    );

final _payload = <String, dynamic>{
  'name': 'Gaseosa',
  'sku': 'GAS-1',
  'unit': 'botella',
  'prices': [
    {'type': 'price1', 'amount': 3500},
  ],
  'taxCategory': 'IVA',
  'taxRate': 19,
  'isTaxable': true,
  'retentionCategory': 'RET_IVA',
  'retentionRate': 15,
  'hasRetention': true,
};

void main() {
  group('productCreateDataFromLocal', () {
    test('Isar con IVA 19 y RET_IVA 15 → el request lleva ese impuesto', () {
      final data = productCreateDataFromLocal(
        local(
          tax: TaxCategory.iva,
          rate: 19,
          taxable: true,
          ret: RetentionCategory.retIva,
          retRate: 15,
          hasRet: true,
        ),
        const {},
      );
      final json = createProductRequestFromQueue(data, categoryId: 'cat-1').toJson();
      expect(json['taxCategory'], 'IVA');
      expect(json['taxRate'], 19.0);
      expect(json['isTaxable'], true);
      expect(json['retentionCategory'], 'RET_IVA');
      expect(json['retentionRate'], 15.0);
      expect(json['hasRetention'], true);
    });

    test('Isar sin impuesto (valores por defecto) → usa el del payload', () {
      final data = productCreateDataFromLocal(local(), _payload);
      final json = createProductRequestFromQueue(data, categoryId: 'cat-1').toJson();
      expect(json['taxCategory'], 'IVA');
      expect(json['taxRate'], 19.0);
      expect(json['retentionCategory'], 'RET_IVA');
      expect(json['hasRetention'], true);
    });

    test('Isar con impuesto propio gana sobre el payload', () {
      final data = productCreateDataFromLocal(
        local(tax: TaxCategory.inc, rate: 8, taxable: true),
        _payload,
      );
      expect(data['taxCategory'], 'INC');
      expect(data['taxRate'], 8.0);
      // retención vacía en Isar → la del payload
      expect(data['retentionCategory'], 'RET_IVA');
    });

    test('sin impuesto en ningún lado → NO_GRAVADO/0 (el producto no tiene)', () {
      final data = productCreateDataFromLocal(local(), const {'name': 'x'});
      expect(data['taxCategory'], 'NO_GRAVADO');
      expect(data['taxRate'], 0.0);
      expect(data['retentionCategory'], isNull);
    });

    test('precios y unidad: Isar primero, el payload si Isar no tiene', () {
      final conPrecios = productCreateDataFromLocal(
        local(prices: [
          ProductPrice(
            id: 'p1',
            productId: 'product_offline_1',
            type: PriceType.price2,
            amount: 4000,
            currency: 'COP',
            status: PriceStatus.active,
            discountPercentage: 0,
            minQuantity: 1,
            createdAt: _now,
            updatedAt: _now,
          ),
        ]),
        _payload,
      );
      expect((conPrecios['prices'] as List).single['amount'], 4000);
      expect(conPrecios['unit'], 'und');

      final sinPrecios = productCreateDataFromLocal(local(unit: null), _payload);
      expect((sinPrecios['prices'] as List).single['amount'], 3500);
      expect(sinPrecios['unit'], 'botella');
    });
  });

  group('mergeProductUpdatesIntoCreate', () {
    test('las ediciones de los UPDATE quedan en el CREATE, el último gana', () {
      final merged = mergeProductUpdatesIntoCreate(
        {'name': 'Gaseosa', 'unit': 'und', 'taxCategory': 'NO_GRAVADO', 'prices': [
          {'type': 'price1', 'amount': 3500},
        ]},
        [
          {'name': 'Gaseosa 1L', 'unit': null, 'taxCategory': 'IVA', 'taxRate': 19},
          {'id': 'x', 'updated': true, 'unit': 'botella', 'prices': [
            {'type': 'price1', 'amount': 4200},
          ], '_interno': 1},
        ],
      );
      expect(merged['name'], 'Gaseosa 1L');
      expect(merged['unit'], 'botella');
      expect(merged['taxCategory'], 'IVA');
      expect(merged['taxRate'], 19);
      expect((merged['prices'] as List).single['amount'], 4200);
      expect(merged.containsKey('id'), isFalse);
      expect(merged.containsKey('updated'), isFalse);
      expect(merged.containsKey('_interno'), isFalse);
    });
  });
}
