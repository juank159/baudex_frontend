// lib/app/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Interfaz base para todos los casos de uso
///
/// [Type] es el tipo de dato que retorna el caso de uso
/// [Params] es el tipo de parámetros que recibe el caso de uso
abstract class UseCase<Type, Params> {
  /// Método principal que ejecuta el caso de uso
  Future<Either<Failure, Type>> call(Params params);
}

/// Clase para casos de uso que no requieren parámetros
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
