import 'package:flutter/material.dart';

/// RouteObserver global para detectar transiciones de pantalla.
/// Permite que las páginas implementen RouteAware para refrescar
/// datos automáticamente al regresar de otra pantalla.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
