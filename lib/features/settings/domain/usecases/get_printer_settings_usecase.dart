// lib/features/settings/domain/usecases/get_printer_settings_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/printer_settings.dart';
import '../repositories/settings_repository.dart';

class GetAllPrinterSettingsUseCase implements UseCase<List<PrinterSettings>, NoParams> {
  final SettingsRepository repository;

  GetAllPrinterSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PrinterSettings>>> call(NoParams params) async {
    return await repository.getAllPrinterSettings();
  }
}

class GetDefaultPrinterSettingsUseCase implements UseCase<PrinterSettings?, NoParams> {
  final SettingsRepository repository;

  GetDefaultPrinterSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, PrinterSettings?>> call(NoParams params) async {
    return await repository.getDefaultPrinterSettings();
  }
}