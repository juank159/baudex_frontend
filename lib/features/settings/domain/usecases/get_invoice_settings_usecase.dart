// lib/features/settings/domain/usecases/get_invoice_settings_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/invoice_settings.dart';
import '../repositories/settings_repository.dart';

class GetInvoiceSettingsUseCase implements UseCase<InvoiceSettings, NoParams> {
  final SettingsRepository repository;

  GetInvoiceSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, InvoiceSettings>> call(NoParams params) async {
    return await repository.getInvoiceSettings();
  }
}