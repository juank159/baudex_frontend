// lib/features/dashboard/domain/usecases/get_unread_notifications_count_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/dashboard_repository.dart';

class GetUnreadNotificationsCountUseCase implements UseCase<int, NoParams> {
  final DashboardRepository repository;

  GetUnreadNotificationsCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.getUnreadNotificationsCount();
  }
}