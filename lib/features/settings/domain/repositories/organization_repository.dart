// lib/features/settings/domain/repositories/organization_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/organization.dart';
import '../entities/create_organization_request.dart';

abstract class OrganizationRepository {
  Future<Either<Failure, Organization>> getCurrentOrganization();
  Future<Either<Failure, List<Organization>>> getAllOrganizations();
  Future<Either<Failure, Organization>> createOrganization(CreateOrganizationRequest request);
  Future<Either<Failure, Organization>> updateOrganization(String id, Map<String, dynamic> updates);
  Future<Either<Failure, void>> deleteOrganization(String id);
  Future<Either<Failure, Organization>> getOrganizationById(String id);
}