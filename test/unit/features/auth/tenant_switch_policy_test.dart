import 'package:baudex_desktop/features/auth/domain/tenant_switch_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Al iniciar sesión se compara el NEGOCIO de los datos del equipo con el
/// del usuario, no el usuario. Un empleado del mismo negocio nunca borra la
/// base local; otro negocio sí, salvo que haya operaciones sin subir.
void main() {
  const merca = '8c5a2625-merca';
  const granada = 'c33e9620-granada';
  const kely = 'user-kely';
  const empleado = 'user-empleado';

  TenantSwitchDecision decide({
    String? data,
    String org = merca,
    String? last,
    String user = empleado,
    int pending = 0,
  }) =>
      decideTenantSwitch(
        dataOrganization: data,
        newOrganization: org,
        lastUserId: last,
        newUserId: user,
        pendingOperations: pending,
      );

  test('empleado del mismo negocio que el administrador: no se borra nada', () {
    expect(decide(data: merca, last: kely, user: empleado), TenantSwitchDecision.keepLocalData);
  });

  test('mismo negocio con operaciones sin subir: no se borra nada', () {
    expect(decide(data: merca, last: kely, pending: 5), TenantSwitchDecision.keepLocalData);
  });

  test('el mismo usuario vuelve a entrar: no se borra nada', () {
    expect(decide(data: merca, last: kely, user: kely), TenantSwitchDecision.keepLocalData);
  });

  test('otro negocio sin pendientes: se limpia para no mezclar datos', () {
    expect(decide(data: merca, org: granada, last: kely, user: 'user-granada'),
        TenantSwitchDecision.clearLocalData);
  });

  test('otro negocio con operaciones sin subir: no se borra y no deja entrar', () {
    expect(decide(data: merca, org: granada, last: kely, user: 'user-granada', pending: 3),
        TenantSwitchDecision.blockedByPendingOperations);
  });

  test('aunque sea el mismo usuario, si los datos son de otro negocio se limpian', () {
    expect(decide(data: granada, org: merca, last: kely, user: kely),
        TenantSwitchDecision.clearLocalData);
  });

  test('equipo sin negocio anotado y sin usuario anterior: no se borra nada', () {
    expect(decide(data: null, last: null), TenantSwitchDecision.keepLocalData);
  });

  test('equipo sin negocio anotado y otro usuario: comportamiento anterior (limpia)', () {
    expect(decide(data: null, last: kely, user: empleado), TenantSwitchDecision.clearLocalData);
  });

  test('equipo sin negocio anotado, otro usuario y pendientes: no se borra', () {
    expect(decide(data: null, last: kely, user: empleado, pending: 2),
        TenantSwitchDecision.blockedByPendingOperations);
  });
}
