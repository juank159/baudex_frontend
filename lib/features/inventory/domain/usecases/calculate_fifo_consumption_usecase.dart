// lib/features/inventory/domain/usecases/calculate_fifo_consumption_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_balance.dart';
import '../repositories/inventory_repository.dart';

class CalculateFifoConsumptionParams {
  final String productId;
  final int quantity;
  final String? warehouseId;

  const CalculateFifoConsumptionParams({
    required this.productId,
    required this.quantity,
    this.warehouseId,
  });
}

class CalculateFifoConsumptionUseCase
    implements UseCase<List<FifoConsumption>, CalculateFifoConsumptionParams> {
  final InventoryRepository repository;

  CalculateFifoConsumptionUseCase(this.repository);

  @override
  Future<Either<Failure, List<FifoConsumption>>> call(
    CalculateFifoConsumptionParams params,
  ) async {
    return await repository.calculateFifoConsumption(
      params.productId,
      params.quantity,
      warehouseId: params.warehouseId,
    );
  }
}