// lib/features/settings/domain/usecases/create_organization_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/organization.dart';
import '../entities/create_organization_request.dart';
import '../repositories/organization_repository.dart';

class CreateOrganizationUseCase implements UseCase<Organization, CreateOrganizationParams> {
  final OrganizationRepository repository;

  CreateOrganizationUseCase(this.repository);

  @override
  Future<Either<Failure, Organization>> call(CreateOrganizationParams params) async {
    return await repository.createOrganization(params.request);
  }
}

class CreateOrganizationParams extends Equatable {
  final CreateOrganizationRequest request;

  const CreateOrganizationParams({required this.request});

  @override
  List<Object> get props => [request];
}