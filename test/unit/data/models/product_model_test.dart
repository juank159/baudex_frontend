// test/unit/data/models/product_model_test.dart
import 'dart:convert';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_price_model.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/product_fixtures.dart';

void main() {
  group('ProductModel', () {
    final tProduct = ProductFixtures.createProductEntity();
    final tProductModel = ProductModel.fromEntity(tProduct);

    final tProductJson = {
      'id': tProduct.id,
      'name': tProduct.name,
      'description': tProduct.description,
      'sku': tProduct.sku,
      'barcode': tProduct.barcode,
      'type': tProduct.type.name,
      'status': tProduct.status.name,
      'stock': tProduct.stock,
      'minStock': tProduct.minStock,
      'unit': tProduct.unit,
      'weight': tProduct.weight,
      'length': tProduct.length,
      'width': tProduct.width,
      'height': tProduct.height,
      'images': tProduct.images,
      'metadata': tProduct.metadata,
      'categoryId': tProduct.categoryId,
      'createdById': tProduct.createdById,
      'prices': tProduct.prices?.map((p) => {
        'id': p.id,
        'productId': p.productId,
        'type': p.type.name,
        'amount': p.amount,
        'currency': p.currency,
        'status': p.status.name,
        'discountPercentage': p.discountPercentage,
        'minQuantity': p.minQuantity,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
      }).toList(),
      'category': null,
      'createdBy': null,
      'createdAt': tProduct.createdAt.toIso8601String(),
      'updatedAt': tProduct.updatedAt.toIso8601String(),
      'taxCategory': tProduct.taxCategory.value,
      'taxRate': tProduct.taxRate,
      'isTaxable': tProduct.isTaxable,
      'taxDescription': tProduct.taxDescription,
      'retentionCategory': tProduct.retentionCategory?.value,
      'retentionRate': tProduct.retentionRate,
      'hasRetention': tProduct.hasRetention,
    };

    group('fromJson', () {
      test('should return valid ProductModel from JSON', () {
        // Act
        final result = ProductModel.fromJson(tProductJson);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, tProduct.id);
        expect(result.name, tProduct.name);
        expect(result.sku, tProduct.sku);
        expect(result.type, tProduct.type.name);
        expect(result.status, tProduct.status.name);
      });

      test('should handle null optional fields', () {
        // Arrange
        final jsonWithNulls = {
          'id': 'prod-001',
          'name': 'Test Product',
          'description': null,
          'sku': 'SKU-001',
          'barcode': null,
          'type': 'product',
          'status': 'active',
          'stock': 100.0,
          'minStock': 10.0,
          'unit': null,
          'weight': null,
          'length': null,
          'width': null,
          'height': null,
          'images': null,
          'metadata': null,
          'categoryId': 'cat-001',
          'createdById': 'user-001',
          'prices': null,
          'category': null,
          'createdBy': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'taxCategory': 'IVA',
          'taxRate': 19.0,
          'isTaxable': true,
          'taxDescription': null,
          'retentionCategory': null,
          'retentionRate': null,
          'hasRetention': false,
        };

        // Act
        final result = ProductModel.fromJson(jsonWithNulls);

        // Assert
        expect(result.description, isNull);
        expect(result.barcode, isNull);
        expect(result.weight, isNull);
        expect(result.images, isNull);
        expect(result.metadata, isNull);
        expect(result.prices, isNull);
      });

      test('should parse stock and minStock as double from int', () {
        // Arrange
        final jsonWithIntStock = {
          ...tProductJson,
          'stock': 100,
          'minStock': 10,
        };

        // Act
        final result = ProductModel.fromJson(jsonWithIntStock);

        // Assert
        expect(result.stock, 100.0);
        expect(result.minStock, 10.0);
      });

      test('should parse stock and minStock as double from string', () {
        // Arrange
        final jsonWithStringStock = {
          ...tProductJson,
          'stock': '100.5',
          'minStock': '10.5',
        };

        // Act
        final result = ProductModel.fromJson(jsonWithStringStock);

        // Assert
        expect(result.stock, 100.5);
        expect(result.minStock, 10.5);
      });

      test('should parse prices list correctly', () {
        // Arrange
        final jsonWithPrices = {
          ...tProductJson,
          'prices': [
            {
              'id': 'price-001',
              'productId': 'prod-001',
              'type': 'price1',
              'amount': 100000.0,
              'currency': 'COP',
              'status': 'active',
              'discountPercentage': 0.0,
              'minQuantity': 1.0,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
          ],
        };

        // Act
        final result = ProductModel.fromJson(jsonWithPrices);

        // Assert
        expect(result.prices, isNotNull);
        expect(result.prices!.length, 1);
        expect(result.prices!.first, isA<ProductPriceModel>());
      });

      test('should parse category object correctly', () {
        // Arrange
        final jsonWithCategory = {
          ...tProductJson,
          'category': {
            'id': 'cat-001',
            'name': 'Electronics',
            'slug': 'electronics',
          },
        };

        // Act
        final result = ProductModel.fromJson(jsonWithCategory);

        // Assert
        expect(result.category, isNotNull);
        expect(result.category!.id, 'cat-001');
        expect(result.category!.name, 'Electronics');
      });

      test('should parse createdBy object correctly', () {
        // Arrange
        final jsonWithCreatedBy = {
          ...tProductJson,
          'createdBy': {
            'id': 'user-001',
            'firstName': 'John',
            'lastName': 'Doe',
            'fullName': 'John Doe',
          },
        };

        // Act
        final result = ProductModel.fromJson(jsonWithCreatedBy);

        // Assert
        expect(result.createdBy, isNotNull);
        expect(result.createdBy!.id, 'user-001');
        expect(result.createdBy!.fullName, 'John Doe');
      });

      test('should parse tax fields correctly', () {
        // Arrange
        final jsonWithTax = {
          ...tProductJson,
          'taxCategory': 'IVA',
          'taxRate': 19.0,
          'isTaxable': true,
          'taxDescription': 'Standard VAT',
        };

        // Act
        final result = ProductModel.fromJson(jsonWithTax);

        // Assert
        expect(result.taxCategory, 'IVA');
        expect(result.taxRate, 19.0);
        expect(result.isTaxable, true);
        expect(result.taxDescription, 'Standard VAT');
      });

      test('should parse retention fields correctly', () {
        // Arrange
        final jsonWithRetention = {
          ...tProductJson,
          'retentionCategory': 'RETEFUENTE',
          'retentionRate': 2.5,
          'hasRetention': true,
        };

        // Act
        final result = ProductModel.fromJson(jsonWithRetention);

        // Assert
        expect(result.retentionCategory, 'RETEFUENTE');
        expect(result.retentionRate, 2.5);
        expect(result.hasRetention, true);
      });
    });

    group('toJson', () {
      test('should return valid JSON map', () {
        // Act
        final result = tProductModel.toJson();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], tProduct.id);
        expect(result['name'], tProduct.name);
        expect(result['sku'], tProduct.sku);
        expect(result['type'], tProduct.type.name);
        expect(result['status'], tProduct.status.name);
      });

      test('should serialize dates as ISO 8601 strings', () {
        // Act
        final result = tProductModel.toJson();

        // Assert
        expect(result['createdAt'], isA<String>());
        expect(result['updatedAt'], isA<String>());
        expect(
          DateTime.parse(result['createdAt'] as String),
          isA<DateTime>(),
        );
      });

      test('should serialize prices list', () {
        // Arrange
        final productWithPrices = ProductFixtures.createProductWithMultiplePrices();
        final model = ProductModel.fromEntity(productWithPrices);

        // Act
        final result = model.toJson();

        // Assert
        expect(result['prices'], isA<List>());
        expect((result['prices'] as List).length, 4);
      });

      test('should serialize null fields as null', () {
        // Arrange
        final productWithNulls = ProductModel(
          id: 'prod-001',
          name: 'Test',
          description: null,
          sku: 'SKU-001',
          barcode: null,
          type: 'product',
          status: 'active',
          stock: 100.0,
          minStock: 10.0,
          unit: null,
          categoryId: 'cat-001',
          createdById: 'user-001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = productWithNulls.toJson();

        // Assert
        expect(result['description'], isNull);
        expect(result['barcode'], isNull);
        expect(result['unit'], isNull);
      });

      test('should serialize tax fields', () {
        // Act
        final result = tProductModel.toJson();

        // Assert
        expect(result['taxCategory'], isNotNull);
        expect(result['taxRate'], isNotNull);
        expect(result['isTaxable'], isNotNull);
      });
    });

    group('toEntity', () {
      test('should convert to Product entity', () {
        // Act
        final result = tProductModel.toEntity();

        // Assert
        expect(result, isA<Product>());
        expect(result.id, tProductModel.id);
        expect(result.name, tProductModel.name);
        expect(result.sku, tProductModel.sku);
      });

      test('should map type string to ProductType enum', () {
        // Arrange
        final productModel = ProductModel(
          id: 'prod-001',
          name: 'Test Service',
          sku: 'SKU-001',
          type: 'service',
          status: 'active',
          stock: 0.0,
          minStock: 0.0,
          categoryId: 'cat-001',
          createdById: 'user-001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = productModel.toEntity();

        // Assert
        expect(result.type, ProductType.service);
      });

      test('should map status string to ProductStatus enum', () {
        // Arrange
        final productModel = ProductModel(
          id: 'prod-001',
          name: 'Test',
          sku: 'SKU-001',
          type: 'product',
          status: 'inactive',
          stock: 100.0,
          minStock: 10.0,
          categoryId: 'cat-001',
          createdById: 'user-001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = productModel.toEntity();

        // Assert
        expect(result.status, ProductStatus.inactive);
      });

      test('should convert prices to entities', () {
        // Arrange
        final productWithPrices = ProductFixtures.createProductWithMultiplePrices();
        final model = ProductModel.fromEntity(productWithPrices);

        // Act
        final result = model.toEntity();

        // Assert
        expect(result.prices, isNotNull);
        expect(result.prices!.length, 4);
      });

      test('should map tax fields correctly', () {
        // Arrange
        final productModel = ProductModel(
          id: 'prod-001',
          name: 'Test',
          sku: 'SKU-001',
          type: 'product',
          status: 'active',
          stock: 100.0,
          minStock: 10.0,
          categoryId: 'cat-001',
          createdById: 'user-001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          taxCategory: 'IVA',
          taxRate: 19.0,
          isTaxable: true,
        );

        // Act
        final result = productModel.toEntity();

        // Assert
        expect(result.taxCategory, TaxCategory.iva);
        expect(result.taxRate, 19.0);
        expect(result.isTaxable, true);
      });
    });

    group('fromEntity', () {
      test('should create ProductModel from Product entity', () {
        // Arrange
        final product = ProductFixtures.createProductEntity();

        // Act
        final result = ProductModel.fromEntity(product);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, product.id);
        expect(result.name, product.name);
        expect(result.sku, product.sku);
      });

      test('should map ProductType enum to string', () {
        // Arrange
        final product = ProductFixtures.createServiceProduct();

        // Act
        final result = ProductModel.fromEntity(product);

        // Assert
        expect(result.type, 'service');
      });

      test('should map ProductStatus enum to string', () {
        // Arrange
        final product = ProductFixtures.createInactiveProduct();

        // Act
        final result = ProductModel.fromEntity(product);

        // Assert
        expect(result.status, 'inactive');
      });

      test('should convert price entities to models', () {
        // Arrange
        final product = ProductFixtures.createProductWithMultiplePrices();

        // Act
        final result = ProductModel.fromEntity(product);

        // Assert
        expect(result.prices, isNotNull);
        expect(result.prices!.length, 4);
        expect(result.prices!.first, isA<ProductPriceModel>());
      });

      test('should map tax category enum to string', () {
        // Arrange
        final product = ProductFixtures.createProductEntity(
          taxCategory: TaxCategory.iva,
        );

        // Act
        final result = ProductModel.fromEntity(product);

        // Assert
        expect(result.taxCategory, 'IVA');
      });

      test('should handle null retention category', () {
        // Arrange
        final product = ProductFixtures.createProductEntity(
          retentionCategory: null,
        );

        // Act
        final result = ProductModel.fromEntity(product);

        // Assert
        expect(result.retentionCategory, isNull);
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through toJson -> fromJson', () {
        // Arrange
        final originalModel = tProductModel;

        // Act
        final json = originalModel.toJson();
        final reconstructedModel = ProductModel.fromJson(json);

        // Assert
        expect(reconstructedModel.id, originalModel.id);
        expect(reconstructedModel.name, originalModel.name);
        expect(reconstructedModel.sku, originalModel.sku);
        expect(reconstructedModel.stock, originalModel.stock);
        expect(reconstructedModel.type, originalModel.type);
        expect(reconstructedModel.status, originalModel.status);
      });

      test('should maintain data integrity through toEntity -> fromEntity', () {
        // Arrange
        final originalEntity = tProduct;

        // Act
        final model = ProductModel.fromEntity(originalEntity);
        final reconstructedEntity = model.toEntity();

        // Assert
        expect(reconstructedEntity.id, originalEntity.id);
        expect(reconstructedEntity.name, originalEntity.name);
        expect(reconstructedEntity.sku, originalEntity.sku);
        expect(reconstructedEntity.type, originalEntity.type);
        expect(reconstructedEntity.status, originalEntity.status);
      });
    });
  });
}
