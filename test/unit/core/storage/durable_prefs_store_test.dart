// El almacén de preferencias propio (Windows/Linux): que el archivo nunca
// quede a medias y que, si lo encuentra dañado, recupere en vez de empezar
// de cero.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/storage/durable_prefs_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  late Directory dir;
  late File file;
  File tmp() => File('${file.path}.tmp');
  File bak() => File('${file.path}.bak');

  setUp(() {
    dir = Directory.systemTemp.createTempSync('baudex_prefs');
    file = File('${dir.path}/shared_preferences.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  const good = {'flutter.sync_wm_v1|org|products': '2026-11-25', 'flutter.n': 3};

  group('abrir', () {
    test('equipo nuevo: vacío y sin problema', () {
      final r = loadDurablePrefs(file);
      expect(r.values, isEmpty);
      expect(r.report.source, PrefsLoadSource.file);
      expect(r.report.recovered, isFalse);
    });

    test('archivo sano: se lee tal cual (listas como textos)', () {
      file.writeAsStringSync(json.encode({...good, 'flutter.l': ['a', 'b']}));
      final r = loadDurablePrefs(file);
      expect(r.values['flutter.n'], 3);
      expect(r.values['flutter.l'], isA<List<String>>());
      expect(r.report.source, PrefsLoadSource.file);
    });

    test('archivo cortado y hay copia: se restaura de la copia', () {
      bak().writeAsStringSync(json.encode(good));
      file.writeAsStringSync('{"flutter.sync_wm_v1|org|prod');
      final r = loadDurablePrefs(file);
      expect(r.report.source, PrefsLoadSource.backup);
      expect(r.values, good);
      expect(r.report.setAside, contains('.danado-'));
      expect(file.existsSync(), isFalse);
    });

    test('archivo lleno de ceros (apagón) y hay copia: se restaura', () {
      bak().writeAsStringSync(json.encode(good));
      file.writeAsBytesSync(List<int>.filled(200, 0));
      expect(loadDurablePrefs(file).values, good);
    });

    test('archivo vacío (escritura perdida) y hay copia: se restaura', () {
      bak().writeAsStringSync(json.encode(good));
      file.writeAsStringSync('');
      final r = loadDurablePrefs(file);
      expect(r.report.source, PrefsLoadSource.backup);
      expect(r.values, good);
    });

    test('se cortó entre "actual → copia" y "temporal → actual": gana el '
        'temporal, que es lo más nuevo', () {
      bak().writeAsStringSync(json.encode({'flutter.n': 1}));
      tmp().writeAsStringSync(json.encode({'flutter.n': 2}));
      final r = loadDurablePrefs(file);
      expect(r.report.source, PrefsLoadSource.pendingWrite);
      expect(r.values['flutter.n'], 2);
    });

    test('temporal cortado: no se usa; el archivo bueno sigue', () {
      file.writeAsStringSync(json.encode(good));
      tmp().writeAsStringSync('{"flutter.n":');
      expect(loadDurablePrefs(file).values, good);
    });

    test('dañado y sin copia: se rescata lo legible', () {
      file.writeAsStringSync(
        '{"flutter.a":"uno","flutter.b":2,"flutter.c":"se cort',
      );
      final r = loadDurablePrefs(file);
      expect(r.report.source, PrefsLoadSource.salvaged);
      expect(r.values, {'flutter.a': 'uno', 'flutter.b': 2});
    });

    test('la versión anterior ya había apartado el dañado y no hay nada '
        'nuevo: se rescata de ese', () {
      File('${file.path}.danado-1764000000000').writeAsStringSync(
        '{"flutter.full_sync_business_v1":"org-1","flutter.x":"cort',
      );
      final r = loadDurablePrefs(file);
      expect(r.report.source, PrefsLoadSource.salvaged);
      expect(r.values, {'flutter.full_sync_business_v1': 'org-1'});
    });

    test('nada que rescatar: vacío, y queda dicho', () {
      file.writeAsBytesSync(List<int>.filled(50, 0));
      final r = loadDurablePrefs(file);
      expect(r.values, isEmpty);
      expect(r.report.source, PrefsLoadSource.empty);
      expect(r.report.problem, isNotNull);
    });
  });

  group('escribir', () {
    test('queda el archivo nuevo, la copia del anterior y ningún temporal', () async {
      await writeDurablePrefs(file, {'flutter.n': 1});
      await writeDurablePrefs(file, {'flutter.n': 2});
      expect(json.decode(file.readAsStringSync()), {'flutter.n': 2});
      expect(json.decode(bak().readAsStringSync()), {'flutter.n': 1});
      expect(tmp().existsSync(), isFalse);
    });

    test('un archivo dañado nunca pisa una copia buena', () async {
      bak().writeAsStringSync(json.encode(good));
      file.writeAsStringSync('{"cortado');
      await writeDurablePrefs(file, {'flutter.n': 9});
      expect(json.decode(bak().readAsStringSync()), good);
      expect(json.decode(file.readAsStringSync()), {'flutter.n': 9});
    });
  });

  group('almacén completo detrás de SharedPreferences', () {
    Future<SharedPreferences> start() async {
      await installDurablePrefs(fileOverride: file);
      return SharedPreferences.getInstance();
    }

    test('200 cambios a la vez: todos quedan y el archivo siempre es legible', () async {
      final prefs = await start();
      await Future.wait([
        for (var i = 0; i < 200; i++) prefs.setString('k$i', 'valor $i' * 20),
      ]);
      final onDisk = json.decode(file.readAsStringSync()) as Map;
      expect(onDisk.length, 200);
      expect(onDisk['flutter.k199'], 'valor 199' * 20);
    });

    test('cerrar y abrir: los valores siguen (texto, número, sí/no, lista)', () async {
      var prefs = await start();
      await prefs.setString('negocio', 'org-1');
      await prefs.setInt('n', 7);
      await prefs.setBool('ok', true);
      await prefs.setStringList('l', ['a', 'b']);
      await prefs.remove('n');

      prefs = await start();
      expect(prefs.getString('negocio'), 'org-1');
      expect(prefs.getInt('n'), isNull);
      expect(prefs.getBool('ok'), isTrue);
      expect(prefs.getStringList('l'), ['a', 'b']);
    });

    test('archivo dañado al arrancar: se restaura de la copia y no lanza', () async {
      var prefs = await start();
      await prefs.setString('full_sync_business_v1', 'org-1');
      await prefs.setString('otra', 'x'); // deja copia con el negocio
      file.writeAsBytesSync([...utf8.encode('{"flutter.full_sy'), 0, 0, 0]);

      final report = await installDurablePrefs(fileOverride: file);
      prefs = await SharedPreferences.getInstance();

      expect(report!.source, PrefsLoadSource.backup);
      expect(prefs.getString('full_sync_business_v1'), 'org-1');
      await installedDurablePrefs!.flush();
      expect(json.decode(file.readAsStringSync()), isA<Map>());
    });

    test('guardar el mismo valor no reescribe el archivo', () async {
      final prefs = await start();
      await prefs.setString('k', 'v');
      final before = file.lastModifiedSync();
      final size = bak().existsSync() ? bak().lengthSync() : -1;
      await prefs.setString('k', 'v');
      expect(file.lastModifiedSync(), before);
      expect(bak().existsSync() ? bak().lengthSync() : -1, size);
    });

    test('si no se puede escribir, no lanza y avisa', () async {
      final problems = <Object>[];
      final blocked = File('${dir.path}/no-es-carpeta/sub/prefs.json');
      File('${dir.path}/no-es-carpeta').writeAsStringSync('soy un archivo');
      final store = DurablePrefsStore(blocked, onProblem: (e, _) => problems.add(e));
      SharedPreferencesStorePlatform.instance = store;
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.resetStatic();
      final prefs = await SharedPreferences.getInstance();

      final ok = await prefs.setString('k', 'v');

      expect(ok, isFalse);
      expect(problems, isNotEmpty);
      expect(prefs.getString('k'), 'v');
    });
  });
}
