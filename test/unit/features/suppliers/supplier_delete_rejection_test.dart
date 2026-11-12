import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/suppliers/data/datasources/supplier_local_datasource.dart';
import 'package:baudex_desktop/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:baudex_desktop/features/suppliers/data/repositories/supplier_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements SupplierRemoteDataSource {}

class _Local extends Mock implements SupplierLocalDataSource {}

class _Network extends Mock implements NetworkInfo {}

/// Si el servidor se niega a eliminar un proveedor (tiene órdenes de compra
/// abiertas), la app no lo elimina en el equipo ni lo deja en la cola.
void main() {
  late _Remote remote;
  late _Local local;
  late SupplierRepositoryImpl repo;

  setUp(() {
    remote = _Remote();
    local = _Local();
    final network = _Network();
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => local.removeCachedSupplier(any())).thenAnswer((_) async {});
    repo = SupplierRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: network,
    );
  });

  test('rechazo 409: devuelve el motivo y no toca nada en el equipo', () async {
    when(() => remote.deleteSupplier('s1')).thenThrow(
      const ServerException('Tiene 2 orden(es) de compra abierta(s)', statusCode: 409),
    );

    final result = await repo.deleteSupplier('s1');

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<BusinessRuleFailure>());
    expect(failure!.message, contains('orden(es) de compra'));
    verifyNever(() => local.removeCachedSupplier(any()));
  });
}
