// lib/features/settings/domain/usecases/save_printer_settings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/printer_settings.dart';
import '../repositories/settings_repository.dart';

class SavePrinterSettingsParams extends Equatable {
  final PrinterSettings settings;

  const SavePrinterSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}

class SavePrinterSettingsUseCase implements UseCase<PrinterSettings, SavePrinterSettingsParams> {
  final SettingsRepository repository;

  SavePrinterSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, PrinterSettings>> call(SavePrinterSettingsParams params) async {
    return await repository.savePrinterSettings(params.settings);
  }
}

class DeletePrinterSettingsParams extends Equatable {
  final String settingsId;

  const DeletePrinterSettingsParams({required this.settingsId});

  @override
  List<Object> get props => [settingsId];
}

class DeletePrinterSettingsUseCase implements UseCase<void, DeletePrinterSettingsParams> {
  final SettingsRepository repository;

  DeletePrinterSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePrinterSettingsParams params) async {
    return await repository.deletePrinterSettings(params.settingsId);
  }
}

class SetDefaultPrinterParams extends Equatable {
  final String settingsId;

  const SetDefaultPrinterParams({required this.settingsId});

  @override
  List<Object> get props => [settingsId];
}

class SetDefaultPrinterUseCase implements UseCase<PrinterSettings, SetDefaultPrinterParams> {
  final SettingsRepository repository;

  SetDefaultPrinterUseCase(this.repository);

  @override
  Future<Either<Failure, PrinterSettings>> call(SetDefaultPrinterParams params) async {
    return await repository.setDefaultPrinter(params.settingsId);
  }
}

class TestPrinterConnectionParams extends Equatable {
  final PrinterSettings settings;

  const TestPrinterConnectionParams({required this.settings});

  @override
  List<Object> get props => [settings];
}

class TestPrinterConnectionUseCase implements UseCase<bool, TestPrinterConnectionParams> {
  final SettingsRepository repository;

  TestPrinterConnectionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(TestPrinterConnectionParams params) async {
    return await repository.testPrinterConnection(params.settings);
  }
}