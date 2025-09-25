// lib/features/settings/domain/usecases/get_current_organization_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';

class GetCurrentOrganizationUseCase implements UseCase<Organization, NoParams> {
  final OrganizationRepository repository;

  GetCurrentOrganizationUseCase(this.repository);

  @override
  Future<Either<Failure, Organization>> call(NoParams params) async {
    return await repository.getCurrentOrganization();
  }
}