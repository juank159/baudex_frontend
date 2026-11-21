// lib/features/invoices/presentation/widgets/scanner_focus.dart
import 'package:flutter/widgets.dart';

/// ¿Puede la caja del lector recuperar el foco?
///
/// Sí cuando nadie lo tiene, cuando lo tiene ella misma ([own]) o cuando quedó
/// en un ámbito ([FocusScopeNode]) sin un campo concreto: eso pasa cuando la
/// pantalla se reconstruye por la sincronización o un aviso, y antes contaba
/// como "otro lo tiene" (el lector perdía teclas cada ~15 escaneos).
/// No, si otro campo o botón lo tiene: el cajero está escribiendo ahí.
bool scannerFocusIsFree(FocusNode? primary, {List<FocusNode> own = const []}) {
  if (primary == null) return true;
  if (own.contains(primary)) return true;
  return primary is FocusScopeNode;
}
