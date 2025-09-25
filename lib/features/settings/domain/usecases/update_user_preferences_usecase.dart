import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/user_preferences.dart';
import '../repositories/user_preferences_repository.dart';

class UpdateUserPreferencesUseCase implements UseCase<UserPreferences, UpdateUserPreferencesParams> {
  final UserPreferencesRepository repository;

  UpdateUserPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, UserPreferences>> call(UpdateUserPreferencesParams params) async {
    return await repository.updateUserPreferences(params.preferences);
  }
}

class UpdateUserPreferencesParams extends Equatable {
  final Map<String, dynamic> preferences;

  const UpdateUserPreferencesParams({
    required this.preferences,
  });

  @override
  List<Object?> get props => [preferences];
}