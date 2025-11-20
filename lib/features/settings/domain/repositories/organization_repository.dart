// lib/features/settings/domain/repositories/organization_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/organization.dart';

abstract class OrganizationRepository {
  Future<Either<Failure, Organization>> getCurrentOrganization();
  Future<Either<Failure, Organization>> updateCurrentOrganization(Map<String, dynamic> updates);
  Future<Either<Failure, Organization>> getOrganizationById(String id);
  
  /// ✅ NUEVO: Actualizar margen de ganancia para productos temporales
  Future<Either<Failure, bool>> updateProfitMargin(double marginPercentage);
}