// lib/features/settings/domain/usecases/save_invoice_settings_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/invoice_settings.dart';
import '../repositories/settings_repository.dart';

class SaveInvoiceSettingsParams extends Equatable {
  final InvoiceSettings settings;

  const SaveInvoiceSettingsParams({required this.settings});

  @override
  List<Object> get props => [settings];
}

class SaveInvoiceSettingsUseCase implements UseCase<InvoiceSettings, SaveInvoiceSettingsParams> {
  final SettingsRepository repository;

  SaveInvoiceSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, InvoiceSettings>> call(SaveInvoiceSettingsParams params) async {
    return await repository.saveInvoiceSettings(params.settings);
  }
}