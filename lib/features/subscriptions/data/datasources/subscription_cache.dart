// lib/features/subscriptions/data/datasources/subscription_cache.dart
import 'package:isar/isar.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/rules/subscription_rules.dart';
import '../models/isar/isar_subscription.dart';

/// La suscripción guardada que vale: la última que confirmó el servidor.
/// ÚNICO punto de lectura; nadie debe usar `where().findFirst()`, que devuelve
/// la más antigua (una ya vencida si el negocio renovó).
Future<IsarSubscription?> currentCachedSubscription(Isar isar) async {
  final all = await isar.isarSubscriptions.where().findAll();
  return pickCurrentSubscription<IsarSubscription>(
    all,
    lastSyncAt: (s) => s.lastSyncAt,
    endDate: (s) => s.endDate,
  );
}

/// Guarda la suscripción que acaba de enviar el servidor y borra las demás
/// copias (suscripciones anteriores del mismo negocio).
Future<void> storeCurrentSubscription(Isar isar, Subscription subscription) async {
  await isar.writeTxn(() async {
    final existing = await isar.isarSubscriptions
        .filter()
        .serverIdEqualTo(subscription.id)
        .findFirst();
    final IsarSubscription row;
    if (existing != null) {
      existing.updateFromEntity(subscription);
      row = existing;
    } else {
      row = IsarSubscription.fromEntity(subscription);
    }
    final id = await isar.isarSubscriptions.put(row);
    await isar.isarSubscriptions.filter().not().idEqualTo(id).deleteAll();
  });
}
