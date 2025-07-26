// lib/features/settings/domain/usecases/save_app_settings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class SaveAppSettingsParams extends Equatable {
  final AppSettings settings;

  const SaveAppSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}

class SaveAppSettingsUseCase implements UseCase<AppSettings, SaveAppSettingsParams> {
  final SettingsRepository repository;

  SaveAppSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, AppSettings>> call(SaveAppSettingsParams params) async {
    return await repository.saveAppSettings(params.settings);
  }
}