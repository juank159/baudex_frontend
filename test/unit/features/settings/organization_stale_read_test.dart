import 'dart:async';

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/settings/data/datasources/organization_remote_datasource.dart';
import 'package:baudex_desktop/features/settings/data/models/organization_model.dart';
import 'package:baudex_desktop/features/settings/data/repositories/organization_offline_repository.dart';
import 'package:baudex_desktop/features/settings/data/repositories/organization_repository_impl.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:dartz/dartz.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _Network extends Mock implements NetworkInfo {}

OrganizationModel org(double rate) => OrganizationModel(
      id: 'org-1',
      name: 'Tienda',
      slug: 'tienda',
      settings: {
        'acceptedCurrencies': [
          {'code': 'VES', 'name': 'Bolívar', 'defaultRate': rate},
        ],
      },
      subscriptionPlan: SubscriptionPlan.basic,
      subscriptionStatus: SubscriptionStatus.active,
      isActive: true,
      currency: 'COP',
      locale: 'es',
      timezone: 'America/Bogota',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      multiCurrencyEnabled: true,
    );

double rateOf(Organization o) =>
    (o.acceptedCurrencies.first['defaultRate'] as num).toDouble();

/// Servidor simulado: cada consulta se responde cuando la prueba lo decide,
/// con lo que el servidor tenía EN EL MOMENTO en que la consulta salió.
class _Server implements OrganizationRemoteDataSource {
  OrganizationModel stored = org(30);
  final List<Completer<OrganizationModel>> pendingReads = [];

  @override
  Future<OrganizationModel> getCurrentOrganization() {
    final snapshot = stored;
    final completer = Completer<OrganizationModel>();
    pendingReads.add(completer);
    // La respuesta lleva lo que había cuando se hizo la consulta.
    return completer.future.then((_) => snapshot);
  }

  void answerReads() {
    for (final read in pendingReads) {
      if (!read.isCompleted) read.complete(stored);
    }
    pendingReads.clear();
  }

  @override
  Future<OrganizationModel> updateCurrentOrganization(Map<String, dynamic> updates) async {
    final currencies = (updates['settings'] as Map)['acceptedCurrencies'] as List;
    stored = org(((currencies.first as Map)['defaultRate'] as num).toDouble());
    return stored;
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async => stored;

  @override
  Future<bool> updateProfitMargin(double marginPercentage) async => true;
}

/// Copia local simulada (lo que este equipo tiene guardado).
class _LocalCopy extends Mock implements OrganizationOfflineRepository {
  Organization? saved;

  @override
  Future<Either<Failure, void>> cacheOrganization(Organization organization) async {
    saved = organization;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async =>
      saved == null ? Left(CacheFailure('vacío')) : Right(saved!);
}

/// Caso real: el dueño cambia el bolívar de 30 a 28,6 y al ir a facturar sigue
/// saliendo 30. Pasa cuando una consulta al servidor que ya iba en camino
/// (el refresco periódico o la descarga) vuelve DESPUÉS del guardado con el
/// valor viejo y pisa el nuevo.
void main() {
  late _Server server;
  late _LocalCopy local;
  late OrganizationRepositoryImpl repo;

  setUp(() {
    server = _Server();
    local = _LocalCopy()..saved = org(30);
    final network = _Network();
    when(() => network.isConnected).thenAnswer((_) async => true);
    repo = OrganizationRepositoryImpl(
      remoteDataSource: server,
      networkInfo: network,
      offlineRepository: local,
    );
  });

  Map<String, dynamic> newRate(double rate) => {
        'settings': {
          'acceptedCurrencies': [
            {'code': 'VES', 'name': 'Bolívar', 'defaultRate': rate},
          ],
        },
      };

  test('un refresco que iba en camino no devuelve la tasa vieja tras guardar', () async {
    final refresh = repo.refreshFromServer(); // sale con 30
    await Future<void>.delayed(Duration.zero);

    final saved = await repo.updateCurrentOrganization(newRate(28.6));
    expect(rateOf(saved.getOrElse(() => throw 'falló')), 28.6);

    server.answerReads(); // el refresco viejo llega ahora, con 30
    final refreshed = await refresh;

    expect(rateOf(refreshed.getOrElse(() => throw 'falló')), 28.6,
        reason: 'lo que se le entrega a la app');
    expect(rateOf(local.saved!), 28.6, reason: 'lo que queda guardado en el equipo');
  });

  test('igual con la consulta normal (getCurrentOrganization)', () async {
    final read = repo.getCurrentOrganization();
    await Future<void>.delayed(Duration.zero);

    await repo.updateCurrentOrganization(newRate(28.6));
    server.answerReads();

    expect(rateOf((await read).getOrElse(() => throw 'falló')), 28.6);
    expect(rateOf(local.saved!), 28.6);
  });

  test('un refresco posterior al guardado sí trae lo del servidor (otro equipo cambió la tasa)', () async {
    await repo.updateCurrentOrganization(newRate(28.6));

    server.stored = org(27.9); // otro equipo la cambió después
    final refresh = repo.refreshFromServer();
    await Future<void>.delayed(Duration.zero);
    server.answerReads();

    expect(rateOf((await refresh).getOrElse(() => throw 'falló')), 27.9);
    expect(rateOf(local.saved!), 27.9);
  });

  test('de punta a punta: lo que ven facturación y órdenes de compra no vuelve a la tasa vieja', () async {
    final controller = Get.put(OrganizationController(repo));
    addTearDown(Get.reset);
    controller.applyOrganization(org(30), notifyRateChange: false);

    // Así se enteran el diálogo de pago y el formulario de órdenes de compra.
    final seen = <double>[];
    ever<Organization?>(controller.currentOrganizationRx, (o) {
      if (o != null) seen.add(rateOf(o));
    });

    final refresh = controller.forceRefreshFromServer(); // sale con 30
    await Future<void>.delayed(Duration.zero);

    expect(await controller.updateCurrencyRate('VES', 28.6), isTrue);
    expect(rateOf(controller.currentOrganization!), 28.6);

    server.answerReads(); // la respuesta vieja llega tarde
    await refresh;
    await Future<void>.delayed(Duration.zero);

    expect(rateOf(controller.currentOrganization!), 28.6);
    expect(seen, [28.6], reason: 'los módulos reciben la tasa nueva y nunca la vieja');
  });
}
