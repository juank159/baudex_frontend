import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/shared/services/subscription_validation_service.dart';
import 'package:baudex_desktop/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:baudex_desktop/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:baudex_desktop/features/subscriptions/data/models/isar/isar_subscription.dart';
import 'package:baudex_desktop/features/subscriptions/data/models/subscription_model.dart';
import 'package:baudex_desktop/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:baudex_desktop/features/subscriptions/domain/entities/plan_limits.dart';
import 'package:baudex_desktop/features/subscriptions/domain/entities/subscription.dart';
import 'package:baudex_desktop/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/isar_core.dart';

class _Remote extends Mock implements SubscriptionRemoteDataSource {}

class _Net extends Mock implements NetworkInfo {}

/// Caso La Granada: el negocio renovó (cada renovación crea una suscripción
/// NUEVA en el servidor) y en el equipo quedaron guardadas la vieja, ya
/// vencida, y la vigente. La app leía "la primera" = la vieja, y cuando no
/// lograba consultar al servidor (sesión vencida, sin internet, límite de
/// intentos) mostraba "Suscripción vencida" con el plan al día.
void main() {
  late Isar isar;
  late SubscriptionLocalDataSourceImpl local;

  final now = DateTime.now();

  Subscription sub(
    String id, {
    required DateTime end,
    SubscriptionStatus status = SubscriptionStatus.active,
    int? days,
  }) {
    final expired = end.isBefore(now);
    return Subscription(
      id: id,
      organizationId: 'org-granada',
      plan: SubscriptionPlan.premium,
      planDisplayName: 'Premium',
      status: status,
      type: SubscriptionType.monthly,
      startDate: end.subtract(const Duration(days: 30)),
      endDate: end,
      isActive: status == SubscriptionStatus.active && !expired,
      isExpired: expired,
      isTrial: false,
      daysUntilExpiration: days ?? (expired ? 0 : end.difference(now).inDays + 1),
      subscriptionProgress: 0.5,
      remainingDays: days ?? (expired ? 0 : end.difference(now).inDays + 1),
      maxUsers: -1,
      autoRenew: false,
      billingCycle: 1,
      limits: PlanLimits.trial,
    );
  }

  final oldExpired = sub('sub-octubre',
      end: now.subtract(const Duration(days: 22)),
      status: SubscriptionStatus.expired);
  final current = sub('sub-noviembre', end: now.add(const Duration(days: 8)));

  setUpAll(initIsarCore);

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('sub_vencida_falsa');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    local = SubscriptionLocalDataSourceImpl();
  });

  tearDown(() async {
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
  });

  /// Deja el equipo como lo tiene hoy un cliente que renovó: dos copias.
  Future<void> seedTwoCopies() async {
    final a = IsarSubscription.fromEntity(oldExpired)
      ..lastSyncAt = now.subtract(const Duration(days: 23));
    final b = IsarSubscription.fromEntity(current)
      ..lastSyncAt = now.subtract(const Duration(days: 1));
    await isar.writeTxn(() async {
      await isar.isarSubscriptions.put(a); // la vieja queda de primera
      await isar.isarSubscriptions.put(b);
    });
  }

  test('con la vieja y la vigente guardadas, se lee la vigente', () async {
    await seedTwoCopies();

    final cached = (await local.getCachedSubscription()).getOrElse(() => throw 'sin copia');
    expect(cached.id, 'sub-noviembre');
    expect(cached.isExpired, isFalse);
    expect(await local.isCachedSubscriptionExpired(), isFalse);
  });

  test('al guardar la que envía el servidor se borran las anteriores', () async {
    await local.cacheSubscription(oldExpired);
    await local.cacheSubscription(current);

    expect(await isar.isarSubscriptions.count(), 1);
    final cached = (await local.getCachedSubscription()).getOrElse(() => throw 'sin copia');
    expect(cached.id, 'sub-noviembre');
  });

  test('sin copia local no se afirma que venció', () async {
    expect(await local.isCachedSubscriptionExpired(), isFalse);
  });

  test('la validación sin internet no usa la suscripción vieja', () async {
    await seedTwoCopies();

    final info = await SubscriptionValidationService.getSubscriptionInfoAsync();
    expect(info, isNotNull);
    expect(info!.isExpired, isFalse);
    expect(info.status, 'active');
  });

  test('la copia guardada se juzga por su fecha, no por la foto del día en que se guardó', () async {
    // Vigente, pero el contador de días llegó en 0 (dato ausente).
    await local.cacheSubscription(sub('sub-x', end: now.add(const Duration(days: 20)), days: 0));
    final vigente = (await local.getCachedSubscription()).getOrElse(() => throw 'sin copia');
    expect(vigente.isExpired, isFalse);
    expect(vigente.alertLevel, SubscriptionAlertLevel.normal);

    // Guardada como vigente hace tiempo y la fecha ya pasó: sí está vencida.
    final stale = IsarSubscription.fromEntity(sub('sub-y', end: now.add(const Duration(days: 1))))
      ..endDate = now.subtract(const Duration(days: 2));
    await isar.writeTxn(() async {
      await isar.isarSubscriptions.clear();
      await isar.isarSubscriptions.put(stale);
    });
    final vencida = (await local.getCachedSubscription()).getOrElse(() => throw 'sin copia');
    expect(vencida.isExpired, isTrue);
    expect(await local.isCachedSubscriptionExpired(), isTrue);
  });

  test('queda menos de un día: no es "vencida"', () {
    final s = sub('sub-z', end: now.add(const Duration(hours: 5)), days: 0);
    expect(s.alertLevel, isNot(SubscriptionAlertLevel.expired));
  });

  test('si el servidor no envía los días, se calculan con la fecha', () {
    final m = SubscriptionModel.fromJson({
      'id': 's1',
      'organizationId': 'o1',
      'plan': 'premium',
      'status': 'active',
      'type': 'monthly',
      'endDate': now.add(const Duration(days: 8)).toUtc().toIso8601String(),
      'isActive': true,
      'isExpired': false,
    });
    expect(m.daysUntilExpiration, greaterThan(0));
    expect(m.alertLevel, isNot(SubscriptionAlertLevel.expired));
  });

  group('el servidor no responde bien → nunca "vencida" con el plan al día', () {
    final failures = <String, Exception>{
      'sesión vencida (401)': const ServerException('Unauthorized', statusCode: 401),
      'límite de intentos (429)': const ServerException('Too Many Requests', statusCode: 429),
      'servidor caído (500)': const ServerException('Error interno', statusCode: 500),
      'sin conexión': const ConnectionException('Sin conexión a internet'),
      'tiempo agotado': const RequestTimeoutException('Tiempo de conexión agotado'),
    };

    failures.forEach((name, error) {
      test(name, () async {
        await seedTwoCopies();
        final remote = _Remote();
        final net = _Net();
        when(() => net.isConnected).thenAnswer((_) async => true);
        when(() => remote.getCurrentSubscription()).thenThrow(error);

        final repo = SubscriptionRepositoryImpl(
            remoteDataSource: remote, localDataSource: local, networkInfo: net);
        final result = await repo.getCurrentSubscription();

        final s = result.getOrElse(() => throw 'debía usar la copia local');
        expect(s.id, 'sub-noviembre');
        expect(s.isExpired, isFalse);
        expect(s.alertLevel, isNot(SubscriptionAlertLevel.expired));
      });
    });

    test('sin internet (modo offline) tampoco', () async {
      await seedTwoCopies();
      final net = _Net();
      when(() => net.isConnected).thenAnswer((_) async => false);
      final repo = SubscriptionRepositoryImpl(
          remoteDataSource: _Remote(), localDataSource: local, networkInfo: net);

      final s = (await repo.getCurrentSubscription()).getOrElse(() => throw 'sin copia');
      expect(s.id, 'sub-noviembre');
      expect(s.isExpired, isFalse);
    });
  });
}
