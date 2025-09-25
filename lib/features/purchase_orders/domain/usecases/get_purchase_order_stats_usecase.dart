// lib/features/purchase_orders/domain/usecases/get_purchase_order_stats_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class GetPurchaseOrderStatsUseCase implements UseCase<PurchaseOrderStats, NoParams> {
  final PurchaseOrderRepository repository;

  const GetPurchaseOrderStatsUseCase(this.repository);

  @override
  Future<Either<Failure, PurchaseOrderStats>> call(NoParams params) async {
    return await repository.getPurchaseOrderStats();
  }
}