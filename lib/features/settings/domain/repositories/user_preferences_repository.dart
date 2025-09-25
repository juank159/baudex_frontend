import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/user_preferences.dart';

abstract class UserPreferencesRepository {
  Future<Either<Failure, UserPreferences>> getUserPreferences();
  Future<Either<Failure, UserPreferences>> updateUserPreferences(Map<String, dynamic> preferences);
}