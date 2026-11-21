// Sonda de memoria para la prueba de estrés: se conecta al servicio de la VM
// de la app (modo profile) y cada 2 s anota heap, memoria externa y RSS. Cada
// vez que cambia el escenario (archivo de marca) toma una foto de los objetos
// vivos tras forzar recolección de basura: controladores GetX, estados de
// pantallas, temporizadores y suscripciones a streams. Así se ve qué crece.
//
// Uso: dart run tool/estres/vm_probe.dart <ws://…/ws> <pid> <archivo_marca> <salida.jsonl>
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

final _interesting = RegExp(
    r'(Controller|Service|Binding)$|State$|^_Timer$|Subscription$|^GetStream|^LightSubscription$|^Worker$|^Isar');

Future<void> main(List<String> args) async {
  var uri = args[0];
  if (uri.startsWith('http')) {
    uri = uri.replaceFirst('http', 'ws');
    if (!uri.endsWith('/')) uri += '/';
    uri += 'ws';
  }
  final pid = args[1];
  final markFile = File(args[2]);
  final out = File(args[3]).openWrite(mode: FileMode.append);
  final vm = await vmServiceConnectUri(uri);
  // En modo profile el perfilador viene apagado: se enciende para medir.
  try {
    await vm.setFlag('profiler', 'true');
  } catch (_) {}
  final v = await vm.getVM();
  final iso = v.isolates!.firstWhere((i) => i.name == 'main', orElse: () => v.isolates!.first);
  final id = iso.id!;
  String lastMark = '';
  var markStartMicros = (await vm.getVMTimelineMicros()).timestamp!;
  final outDir = File(args[3]).parent.path;

  // Perfil de CPU del escenario que acaba de terminar: qué funciones Dart
  // ocuparon el hilo principal (tiempo propio e incluido).
  Future<void> cpuReport(String name, int fromMicros) async {
    try {
      final now = (await vm.getVMTimelineMicros()).timestamp!;
      final cs = await vm.getCpuSamples(id, fromMicros, now - fromMicros);
      final fns = cs.functions ?? [];
      String fname(int i) {
        final f = fns[i].function;
        if (f is FuncRef) {
          final owner = f.owner;
          final o = owner is ClassRef ? '${owner.name}.' : '';
          return '$o${f.name}';
        }
        if (f is NativeFunction) return '[nativo] ${f.name}';
        return '${f.runtimeType}';
      }
      final self = <String, int>{}, incl = <String, int>{};
      for (final smp in cs.samples ?? <CpuSample>[]) {
        final st = smp.stack ?? [];
        if (st.isEmpty) continue;
        final top = fname(st.first);
        self[top] = (self[top] ?? 0) + 1;
        for (final n in st.map(fname).toSet()) incl[n] = (incl[n] ?? 0) + 1;
      }
      final total = cs.samples?.length ?? 0;
      final per = (cs.samplePeriod ?? 1000) / 1000.0;
      String top(Map<String, int> m, int n) => (m.entries.toList()..sort((a, b) => b.value - a.value))
          .take(n).map((e) => '${(e.value * per).toStringAsFixed(0).padLeft(7)} ms ${(100 * e.value / (total == 0 ? 1 : total)).toStringAsFixed(1).padLeft(5)}%  ${e.key}').join('\n');
      final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      File('$outDir/cpu_$safe.txt').writeAsStringSync(
          'Escenario $name · muestras $total (${(total * per / 1000).toStringAsFixed(1)} s de CPU del hilo de Dart)\n'
          '-- tiempo propio --\n${top(self, 30)}\n\n-- incluido (función y lo que llama) --\n${top(incl, 45)}\n');
    } catch (e) {
      stderr.writeln('cpu $name: $e');
    }
  }
  var lastFull = DateTime.fromMillisecondsSinceEpoch(0);

  Future<int> rssKb() async {
    final r = await Process.run('ps', ['-o', 'rss=', '-p', pid]);
    return int.tryParse((r.stdout as String).trim()) ?? -1;
  }

  while (true) {
    String mark;
    try {
      mark = markFile.existsSync() ? markFile.readAsStringSync().trim() : '';
    } catch (_) {
      mark = lastMark;
    }
    final now = DateTime.now();
    try {
      final mu = await vm.getMemoryUsage(id);
      final row = <String, Object?>{
        't': now.toIso8601String(),
        'marca': mark,
        'heap_mb': (mu.heapUsage! / 1048576).toStringAsFixed(1),
        'heap_cap_mb': (mu.heapCapacity! / 1048576).toStringAsFixed(1),
        'externa_mb': (mu.externalUsage! / 1048576).toStringAsFixed(1),
        'rss_mb': ((await rssKb()) / 1024).toStringAsFixed(0),
      };
      if (mark != lastMark && lastMark.isNotEmpty && !lastMark.contains(':')) {
        await cpuReport(lastMark, markStartMicros);
      }
      if (mark != lastMark) markStartMicros = (await vm.getVMTimelineMicros()).timestamp!;
      if (mark != lastMark || now.difference(lastFull).inSeconds >= 60) {
        final prof = await vm.getAllocationProfile(id, gc: true);
        final counts = <String, int>{};
        for (final m in prof.members ?? <ClassHeapStats>[]) {
          final name = m.classRef?.name ?? '';
          final n = m.instancesCurrent ?? 0;
          if (n > 0 && _interesting.hasMatch(name)) counts[name] = n;
        }
        final mu2 = await vm.getMemoryUsage(id);
        row['heap_tras_gc_mb'] = (mu2.heapUsage! / 1048576).toStringAsFixed(1);
        row['vivos'] = counts;
        lastFull = now;
      }
      lastMark = mark;
      out.writeln(jsonEncode(row));
      await out.flush();
      if (mark == 'FIN') break;
    } catch (e) {
      stderr.writeln('sonda: $e');
      if (e.toString().contains('closed') || e.toString().contains('Service connection disposed')) break;
    }
    await Future.delayed(const Duration(seconds: 2));
  }
  await out.close();
  await vm.dispose();
  exit(0);
}
