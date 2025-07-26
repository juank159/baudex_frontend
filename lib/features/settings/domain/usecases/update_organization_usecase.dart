// lib/features/settings/domain/usecases/update_organization_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';

class UpdateOrganizationUseCase implements UseCase<Organization, UpdateOrganizationParams> {
  final OrganizationRepository repository;

  UpdateOrganizationUseCase(this.repository);

  @override
  Future<Either<Failure, Organization>> call(UpdateOrganizationParams params) async {
    return await repository.updateOrganization(params.id, params.updates);
  }
}

class UpdateOrganizationParams extends Equatable {
  final String id;
  final Map<String, dynamic> updates;

  const UpdateOrganizationParams({
    required this.id,
    required this.updates,
  });

  @override
  List<Object> get props => [id, updates];
}