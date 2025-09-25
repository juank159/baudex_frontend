// lib/features/inventory/domain/usecases/get_inventory_batches_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart' as core;
import '../../../../app/core/usecases/usecase.dart';
import '../entities/inventory_batch.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryBatchesUseCase
    implements UseCase<core.PaginatedResult<InventoryBatch>, InventoryBatchQueryParams> {
  final InventoryRepository repository;

  GetInventoryBatchesUseCase(this.repository);

  @override
  Future<Either<Failure, core.PaginatedResult<InventoryBatch>>> call(
    InventoryBatchQueryParams params,
  ) async {
    return await repository.getBatches(params);
  }
}