// lib/features/inventory/domain/usecases/get_balance_for_stock_action_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/inventory_balance.dart';
import 'get_inventory_balance_by_product_usecase.dart';

/// Saldo de un producto en un almacén para ACTUAR sobre él.
///
/// Es el mismo caso de uso que reciben las pantallas de ajuste y traslado
/// ([GetInventoryBalanceByProductUseCase]), pero no se conforma con lo que
/// haya en el equipo:
/// - Ajuste de stock y ajustes masivos: con internet pregunta al servidor al
///   elegir el producto; sin internet devuelve lo del equipo, marcado "sin
///   confirmar" cuando el equipo no puede asegurar la cifra.
/// - Traslados ([forTransfer]): solo pregunta al servidor cuando el equipo
///   duda (la búsqueda lee muchos productos en serie) y, si no logra
///   confirmarlo, deja la cifra de siempre: nunca muestra más unidades de
///   las que el equipo puede trasladar.
class GetBalanceForStockActionUseCase
    extends GetInventoryBalanceByProductUseCase {
  final bool forTransfer;

  GetBalanceForStockActionUseCase(super.repository, {this.forTransfer = false});

  @override
  Future<Either<Failure, InventoryBalance>> call(
    String productId, {
    String? warehouseId,
  }) async {
    final result = await repository.getBalanceForStockAction(
      productId,
      warehouseId: warehouseId,
      serverOnlyIfDoubtful: forTransfer,
    );
    if (!forTransfer) return result;
    final unconfirmed =
        result.fold((_) => true, (balance) => balance.isStockUnconfirmed);
    if (!unconfirmed) return result;
    return repository.getBalanceByProduct(productId, warehouseId: warehouseId);
  }
}
