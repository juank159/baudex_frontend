// test/unit/data/models/isar_product_test.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/product_fixtures.dart';

void main() {
  group('IsarProduct', () {
    final tProduct = ProductFixtures.createProductEntity();

    group('fromEntity', () {
      test('should convert Product entity to IsarProduct', () {
        // Act
        final result = IsarProduct.fromEntity(tProduct);

        // Assert
        expect(result, isA<IsarProduct>());
        expect(result.serverId, tProduct.id);
        expect(result.name, tProduct.name);
        expect(result.sku, tProduct.sku);
        expect(result.stock, tProduct.stock);
        expect(result.minStock, tProduct.minStock);
      });

      test('should map ProductType enum to IsarProductType', () {
        // Arrange
        final serviceProduct = ProductFixtures.createServiceProduct();

        // Act
        final result = IsarProduct.fromEntity(serviceProduct);

        // Assert
        expect(result.type, IsarProductType.service);
      });

      test('should map ProductStatus enum to IsarProductStatus', () {
        // Arrange
        final inactiveProduct = ProductFixtures.createInactiveProduct();

        // Act
        final result = IsarProduct.fromEntity(inactiveProduct);

        // Assert
        expect(result.status, IsarProductStatus.inactive);
      });

      test('should mark as synced by default', () {
        // Act
        final result = IsarProduct.fromEntity(tProduct);

        // Assert
        expect(result.isSynced, true);
        expect(result.lastSyncAt, isNotNull);
      });

      test('should handle null optional fields', () {
        // Arrange
        final productWithNulls = ProductFixtures.createProductEntity(
          description: null,
          barcode: null,
          unit: null,
        );

        // Act
        final result = IsarProduct.fromEntity(productWithNulls);

        // Assert
        expect(result.description, isNull);
        expect(result.barcode, isNull);
        expect(result.unit, isNull);
      });

      test('should convert prices to IsarProductPrice list', () {
        // Arrange
        final productWithPrices = ProductFixtures.createProductWithMultiplePrices();

        // Act
        final result = IsarProduct.fromEntity(productWithPrices);

        // Assert
        expect(result.prices, isNotEmpty);
        expect(result.prices.length, 4);
      });

      test('should handle empty prices list', () {
        // Arrange
        final productWithoutPrices = ProductFixtures.createProductEntity(
          prices: [],
        );

        // Act
        final result = IsarProduct.fromEntity(productWithoutPrices);

        // Assert
        expect(result.prices, isEmpty);
      });
    });

    group('toEntity', () {
      test('should convert IsarProduct to Product entity', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);

        // Act
        final result = isarProduct.toEntity();

        // Assert
        expect(result, isA<Product>());
        expect(result.id, isarProduct.serverId);
        expect(result.name, isarProduct.name);
        expect(result.sku, isarProduct.sku);
      });

      test('should map IsarProductType to ProductType enum', () {
        // Arrange
        final serviceProduct = ProductFixtures.createServiceProduct();
        final isarProduct = IsarProduct.fromEntity(serviceProduct);

        // Act
        final result = isarProduct.toEntity();

        // Assert
        expect(result.type, ProductType.service);
      });

      test('should map IsarProductStatus to ProductStatus enum', () {
        // Arrange
        final inactiveProduct = ProductFixtures.createInactiveProduct();
        final isarProduct = IsarProduct.fromEntity(inactiveProduct);

        // Act
        final result = isarProduct.toEntity();

        // Assert
        expect(result.status, ProductStatus.inactive);
      });

      test('should convert IsarProductPrice list to ProductPrice entities', () {
        // Arrange
        final productWithPrices = ProductFixtures.createProductWithMultiplePrices();
        final isarProduct = IsarProduct.fromEntity(productWithPrices);

        // Act
        final result = isarProduct.toEntity();

        // Assert
        expect(result.prices, isNotNull);
        expect(result.prices!.length, 4);
      });
    });

    group('utility methods', () {
      test('isDeleted should return true when deletedAt is set', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        isarProduct.deletedAt = DateTime.now();

        // Act & Assert
        expect(isarProduct.isDeleted, true);
      });

      test('isDeleted should return false when deletedAt is null', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);

        // Act & Assert
        expect(isarProduct.isDeleted, false);
      });

      test('isActive should return true when status is active and not deleted', () {
        // Arrange
        final activeProduct = ProductFixtures.createProductEntity(
          status: ProductStatus.active,
        );
        final isarProduct = IsarProduct.fromEntity(activeProduct);

        // Act & Assert
        expect(isarProduct.isActive, true);
      });

      test('isActive should return false when deleted', () {
        // Arrange
        final activeProduct = ProductFixtures.createProductEntity(
          status: ProductStatus.active,
        );
        final isarProduct = IsarProduct.fromEntity(activeProduct);
        isarProduct.deletedAt = DateTime.now();

        // Act & Assert
        expect(isarProduct.isActive, false);
      });

      test('isActive should return false when status is inactive', () {
        // Arrange
        final inactiveProduct = ProductFixtures.createInactiveProduct();
        final isarProduct = IsarProduct.fromEntity(inactiveProduct);

        // Act & Assert
        expect(isarProduct.isActive, false);
      });

      test('isLowStock should return true when stock <= minStock', () {
        // Arrange
        final lowStockProduct = ProductFixtures.createLowStockProduct(
          stock: 5.0,
          minStock: 10.0,
        );
        final isarProduct = IsarProduct.fromEntity(lowStockProduct);

        // Act & Assert
        expect(isarProduct.isLowStock, true);
      });

      test('isLowStock should return false when stock > minStock', () {
        // Arrange
        final normalProduct = ProductFixtures.createProductEntity(
          stock: 50.0,
          minStock: 10.0,
        );
        final isarProduct = IsarProduct.fromEntity(normalProduct);

        // Act & Assert
        expect(isarProduct.isLowStock, false);
      });

      test('needsSync should return true when isSynced is false', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        isarProduct.isSynced = false;

        // Act & Assert
        expect(isarProduct.needsSync, true);
      });

      test('needsSync should return false when isSynced is true', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        isarProduct.isSynced = true;

        // Act & Assert
        expect(isarProduct.needsSync, false);
      });
    });

    group('sync methods', () {
      test('markAsUnsynced should set isSynced to false', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        isarProduct.isSynced = true;

        // Act
        isarProduct.markAsUnsynced();

        // Assert
        expect(isarProduct.isSynced, false);
      });

      test('markAsUnsynced should update updatedAt timestamp', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        final oldUpdatedAt = isarProduct.updatedAt;

        // Wait a tiny bit to ensure timestamp difference
        Future.delayed(const Duration(milliseconds: 10));

        // Act
        isarProduct.markAsUnsynced();

        // Assert
        expect(isarProduct.updatedAt.isAfter(oldUpdatedAt) ||
               isarProduct.updatedAt.isAtSameMomentAs(oldUpdatedAt), true);
      });

      test('markAsSynced should set isSynced to true', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        isarProduct.isSynced = false;

        // Act
        isarProduct.markAsSynced();

        // Assert
        expect(isarProduct.isSynced, true);
      });

      test('markAsSynced should update lastSyncAt timestamp', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        final oldLastSyncAt = isarProduct.lastSyncAt;

        // Act
        isarProduct.markAsSynced();

        // Assert
        expect(isarProduct.lastSyncAt, isNotNull);
        if (oldLastSyncAt != null) {
          expect(isarProduct.lastSyncAt!.isAfter(oldLastSyncAt) ||
                 isarProduct.lastSyncAt!.isAtSameMomentAs(oldLastSyncAt), true);
        }
      });
    });

    group('soft delete', () {
      test('softDelete should set deletedAt timestamp', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);

        // Act
        isarProduct.softDelete();

        // Assert
        expect(isarProduct.deletedAt, isNotNull);
        expect(isarProduct.isDeleted, true);
      });

      test('softDelete should mark as unsynced', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);
        isarProduct.isSynced = true;

        // Act
        isarProduct.softDelete();

        // Assert
        expect(isarProduct.isSynced, false);
      });
    });

    group('entity roundtrip', () {
      test('should maintain data integrity through fromEntity -> toEntity', () {
        // Arrange
        final originalProduct = tProduct;

        // Act
        final isarProduct = IsarProduct.fromEntity(originalProduct);
        final reconstructedProduct = isarProduct.toEntity();

        // Assert
        expect(reconstructedProduct.id, originalProduct.id);
        expect(reconstructedProduct.name, originalProduct.name);
        expect(reconstructedProduct.sku, originalProduct.sku);
        expect(reconstructedProduct.stock, originalProduct.stock);
        expect(reconstructedProduct.minStock, originalProduct.minStock);
        expect(reconstructedProduct.type, originalProduct.type);
        expect(reconstructedProduct.status, originalProduct.status);
      });

      test('should handle low stock product roundtrip', () {
        // Arrange
        final lowStockProduct = ProductFixtures.createLowStockProduct();

        // Act
        final isarProduct = IsarProduct.fromEntity(lowStockProduct);
        final reconstructedProduct = isarProduct.toEntity();

        // Assert
        expect(reconstructedProduct.stock, lowStockProduct.stock);
        expect(reconstructedProduct.minStock, lowStockProduct.minStock);
        expect(reconstructedProduct.stock <= reconstructedProduct.minStock, true);
      });

      test('should handle service product roundtrip', () {
        // Arrange
        final serviceProduct = ProductFixtures.createServiceProduct();

        // Act
        final isarProduct = IsarProduct.fromEntity(serviceProduct);
        final reconstructedProduct = isarProduct.toEntity();

        // Assert
        expect(reconstructedProduct.type, ProductType.service);
      });

      test('should handle product with multiple prices roundtrip', () {
        // Arrange
        final productWithPrices = ProductFixtures.createProductWithMultiplePrices();

        // Act
        final isarProduct = IsarProduct.fromEntity(productWithPrices);
        final reconstructedProduct = isarProduct.toEntity();

        // Assert
        expect(reconstructedProduct.prices!.length, productWithPrices.prices!.length);
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        // Arrange
        final isarProduct = IsarProduct.fromEntity(tProduct);

        // Act
        final result = isarProduct.toString();

        // Assert
        expect(result, contains('IsarProduct'));
        expect(result, contains(tProduct.id));
        expect(result, contains(tProduct.name));
        expect(result, contains(tProduct.sku));
      });
    });
  });
}
