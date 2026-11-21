// ¿Qué está haciendo la app ahora? Muestra las funciones Dart que más CPU
// usaron en los últimos N segundos (sirve para ver dónde se congela).
// Uso: dart run tool/estres/vm_eval.dart <uri> [segundos=10]
import 'dart:io';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> a) async {
  var uri = a[0].replaceFirst('http', 'ws');
  if (!uri.endsWith('/')) uri += '/';
  final secs = a.length > 1 ? int.parse(a[1]) : 10;
  final vm = await vmServiceConnectUri('${uri}ws');
  // En modo profile el perfilador viene apagado: se enciende para medir.
  try {
    await vm.setFlag('profiler', 'true');
  } catch (_) {}
  final iso = (await vm.getVM()).isolates!.firstWhere((i) => i.name == 'main');
  final now = (await vm.getVMTimelineMicros()).timestamp!;
  final cs = await vm.getCpuSamples(iso.id!, now - secs * 1000000, secs * 1000000);
  final fns = cs.functions ?? [];
  String name(int i) {
    final f = fns[i].function;
    if (f is FuncRef) return '${f.owner is ClassRef ? '${(f.owner as ClassRef).name}.' : ''}${f.name}';
    if (f is NativeFunction) return '[nativo] ${f.name}';
    return '?';
  }
  final incl = <String, int>{};
  final stacks = <String, int>{};
  for (final s in cs.samples ?? <CpuSample>[]) {
    final st = (s.stack ?? []).map(name).toList();
    for (final n in st.toSet()) incl[n] = (incl[n] ?? 0) + 1;
    final k = st.take(8).join(' <- ');
    stacks[k] = (stacks[k] ?? 0) + 1;
  }
  final mu = await vm.getMemoryUsage(iso.id!);
  print('muestras ${cs.samples?.length} en $secs s · heap ${(mu.heapUsage! / 1048576).toStringAsFixed(0)} MB');
  for (final e in (incl.entries.toList()..sort((x, y) => y.value - x.value)).take(25)) {
    print('${e.value.toString().padLeft(6)}  ${e.key}');
  }
  print('-- pilas más frecuentes --');
  for (final e in (stacks.entries.toList()..sort((x, y) => y.value - x.value)).take(5)) {
    print('${e.value.toString().padLeft(6)}  ${e.key}');
  }
  await vm.dispose();
  exit(0);
}
