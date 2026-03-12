// lib/features/notifications/domain/usecases/mark_all_as_read_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkAllAsReadUseCase implements UseCase<Unit, NoParams> {
  final NotificationRepository repository;

  const MarkAllAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.markAllAsRead();
  }
}
