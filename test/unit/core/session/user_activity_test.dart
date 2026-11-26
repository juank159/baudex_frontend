import 'package:baudex_desktop/app/core/session/user_activity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Semáforo de interacción: el trabajo de fondo espera a que el usuario
/// lleve un rato sin tocar nada.
void main() {
  late DateTime now;

  setUp(() {
    UserActivity.debugReset();
    now = DateTime(2026, 11, 26, 9);
    UserActivity.debugNow = () => now;
  });
  tearDown(UserActivity.debugReset);

  test('sin ninguna entrada todavía: libre', () async {
    expect(UserActivity.busy(), isFalse);
    expect(await UserActivity.waitForQuiet(const Duration(seconds: 20)), isTrue);
  });

  test('tras una tecla está ocupado 3 s y luego libre', () {
    UserActivity.note();
    expect(UserActivity.busy(), isTrue);
    now = now.add(const Duration(milliseconds: 2900));
    expect(UserActivity.busy(), isTrue);
    now = now.add(const Duration(milliseconds: 200));
    expect(UserActivity.busy(), isFalse);
  });

  test('espera la calma pedida; cada tecla nueva la reinicia', () async {
    UserActivity.note();
    var done = false;
    final waiting = UserActivity.waitForQuiet(
      const Duration(seconds: 20),
      poll: const Duration(milliseconds: 1),
    ).then((ok) => done = ok);

    now = now.add(const Duration(seconds: 15));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(done, isFalse);

    UserActivity.note(); // otra tecla a los 15 s
    now = now.add(const Duration(seconds: 15));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(done, isFalse, reason: 'solo van 15 s desde la última tecla');

    now = now.add(const Duration(seconds: 6));
    await waiting;
    expect(done, isTrue);
  });

  test('si el usuario no para, se rinde al tope y avisa', () async {
    UserActivity.note();
    final waiting = UserActivity.waitForQuiet(
      const Duration(seconds: 20),
      maxWait: const Duration(seconds: 8),
      poll: const Duration(milliseconds: 1),
    );
    for (var i = 0; i < 10; i++) {
      now = now.add(const Duration(seconds: 1));
      UserActivity.note();
      await Future<void>.delayed(const Duration(milliseconds: 3));
    }
    expect(await waiting, isFalse);
  });
}
