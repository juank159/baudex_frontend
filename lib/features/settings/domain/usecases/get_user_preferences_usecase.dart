import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/user_preferences.dart';
import '../repositories/user_preferences_repository.dart';

class GetUserPreferencesUseCase implements UseCase<UserPreferences, NoParams> {
  final UserPreferencesRepository repository;

  GetUserPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, UserPreferences>> call(NoParams params) async {
    return await repository.getUserPreferences();
  }
}