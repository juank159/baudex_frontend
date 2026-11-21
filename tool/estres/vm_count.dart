// Cuenta instancias vivas (tras recolección) de las clases pedidas.
// Uso: dart run tool/estres/vm_count.dart <uri> Clase1,Clase2,...
import 'dart:io';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> a) async {
  var uri = a[0].replaceFirst('http', 'ws');
  if (!uri.endsWith('/')) uri += '/';
  final want = a[1].split(',').toSet();
  final vm = await vmServiceConnectUri('${uri}ws');
  final iso = (await vm.getVM()).isolates!.firstWhere((i) => i.name == 'main');
  final prof = await vm.getAllocationProfile(iso.id!, gc: true);
  for (final m in prof.members!) {
    if (want.contains(m.classRef?.name)) print('${m.classRef!.name}: ${m.instancesCurrent}');
  }
  await vm.dispose();
  exit(0);
}
