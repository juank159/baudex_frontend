// Perfil de CPU de un servidor Node YA corriendo (abrir su inspector con
// `kill -USR1 <pid>`; escucha en 127.0.0.1:9229). Sin dependencias.
// Uso: dart run tool/estres/node_cpu_profile.dart <segundos> <salida.cpuprofile>
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> a) async {
  final secs = a.isNotEmpty ? int.parse(a[0]) : 15;
  final out = a.length > 1 ? a[1] : 'perfil.cpuprofile';
  final list = await (await (await HttpClient().getUrl(Uri.parse('http://127.0.0.1:9229/json/list'))).close())
      .transform(utf8.decoder).join();
  final ws = await WebSocket.connect((jsonDecode(list) as List).first['webSocketDebuggerUrl']);
  var id = 0;
  final pending = <int, Completer<Map>>{};
  ws.listen((m) {
    final d = jsonDecode(m as String) as Map;
    if (d['id'] != null) pending.remove(d['id'])?.complete((d['result'] ?? {}) as Map);
  });
  Future<Map> send(String method, [Map params = const {}]) {
    final c = Completer<Map>();
    pending[++id] = c;
    ws.add(jsonEncode({'id': id, 'method': method, 'params': params}));
    return c.future;
  }
  await send('Profiler.enable');
  await send('Profiler.setSamplingInterval', {'interval': 500});
  await send('Profiler.start');
  await Future.delayed(Duration(seconds: secs));
  final profile = (await send('Profiler.stop'))['profile'] as Map;
  File(out).writeAsStringSync(jsonEncode(profile));
  final deltas = (profile['timeDeltas'] as List).cast<num>();
  final total = deltas.fold<num>(0, (x, y) => x + y);
  final samples = (profile['samples'] as List).cast<int>();
  final per = total / samples.length;
  final counts = <int, int>{};
  for (final s in samples) counts[s] = (counts[s] ?? 0) + 1;
  final self = <String, double>{}, byFile = <String, double>{};
  for (final n in (profile['nodes'] as List).cast<Map>()) {
    final c = counts[n['id']] ?? 0;
    if (c == 0) continue;
    final f = n['callFrame'] as Map;
    var url = (f['url'] as String);
    final short = url.replaceAll(RegExp(r'.*node_modules/'), 'nm/').replaceAll(RegExp(r'.*/dist/'), 'dist/');
    final fn = (f['functionName'] as String).isEmpty ? '(anónima)' : f['functionName'];
    final k = '$fn $short:${(f['lineNumber'] as int) + 1}';
    self[k] = (self[k] ?? 0) + c * per;
    final m = RegExp(r'node_modules/((@[^/]+/)?[^/]+)').firstMatch(url);
    final file = m != null ? 'nm:${m.group(1)}' : (short.isEmpty ? fn : short);
    byFile[file] = (byFile[file] ?? 0) + c * per;
  }
  String top(Map<String, double> o, int n) => (o.entries.toList()..sort((x, y) => y.value.compareTo(x.value)))
      .take(n)
      .map((e) => '${(e.value / 1000).toStringAsFixed(0).padLeft(6)} ms ${(100 * e.value / total).toStringAsFixed(1).padLeft(5)}%  ${e.key}')
      .join('\n');
  print('Muestreado ${(total / 1e6).toStringAsFixed(1)} s\n-- por paquete/archivo --\n${top(byFile, 15)}\n-- por función (tiempo propio) --\n${top(self, 25)}');
  await ws.close();
  exit(0);
}
