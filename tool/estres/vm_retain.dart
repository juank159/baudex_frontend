// ¿Quién retiene los objetos que crecen? Para una clase (p. ej.
// AnimationController) toma unas instancias vivas y muestra su camino de
// retención hasta la raíz (qué objeto no las suelta).
// Uso: dart run tool/estres/vm_retain.dart <uri> <Clase> [n=6]
import 'dart:io';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> a) async {
  var uri = a[0].replaceFirst('http', 'ws');
  if (!uri.endsWith('/')) uri += '/';
  final cls = a[1];
  final n = a.length > 2 ? int.parse(a[2]) : 6;
  final vm = await vmServiceConnectUri('${uri}ws');
  final iso = (await vm.getVM()).isolates!.firstWhere((i) => i.name == 'main');
  final prof = await vm.getAllocationProfile(iso.id!, gc: true);
  final m = prof.members!.firstWhere((m) => m.classRef?.name == cls);
  print('$cls vivos: ${m.instancesCurrent}');
  final inst = await vm.getInstances(iso.id!, m.classRef!.id!, 400);
  final objs = inst.instances ?? [];
  final summary = <String, int>{};
  for (var i = 0; i < objs.length; i++) {
    RetainingPath p;
    try {
      p = await vm.getRetainingPath(iso.id!, objs[i].id!, 300);
    } catch (_) {
      continue;
    }
    final chain = (p.elements ?? []).map((e) {
      final v = e.value;
      String name = v is InstanceRef ? (v.classRef?.name ?? '?') : (v is ContextRef ? 'Context' : (v is FieldRef ? 'static ${(v.owner as dynamic)?.name}.${v.name}' : v.runtimeType.toString()));
      final f = e.parentField ?? e.parentMapKey;
      return f != null ? '$name.${f is String ? f : (f is InstanceRef ? f.valueAsString : '')}' : name;
    }).toList();
    // Primer objeto "de la app" (no del framework) en la cadena
    // Lo que importa es la RAÍZ: los últimos eslabones (quién no suelta)
    final root = chain.length > 10 ? chain.sublist(chain.length - 10) : chain;
    final key = root.where((c) => !c.startsWith('_List') && !c.startsWith('_Closure') && !c.startsWith('Context')).join(' <- ');
    summary[key] = (summary[key] ?? 0) + 1;
    if (i < n) print('\n#$i (${chain.length} eslabones) clases de la app: ${chain.where((c) => RegExp(r'^[A-Z][A-Za-z]*(Controller|Service|Screen|Widget|State|Page|Binding)[.@]').hasMatch(c) && !c.startsWith('Stateful') && !c.startsWith('AnimationController')).toSet().join(' <- ')}');
  }
  print('\n-- resumen de ${objs.length} instancias (primeros dueños) --');
  for (final e in (summary.entries.toList()..sort((x, y) => y.value - x.value)).take(12)) {
    print('${e.value.toString().padLeft(5)}  ${e.key}');
  }
  await vm.dispose();
  exit(0);
}
