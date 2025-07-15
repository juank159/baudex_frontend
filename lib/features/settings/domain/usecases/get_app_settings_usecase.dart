// lib/features/settings/domain/usecases/get_app_settings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetAppSettingsUseCase implements UseCase<AppSettings, NoParams> {
  final SettingsRepository repository;

  GetAppSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) async {
    return await repository.getAppSettings();
  }
}