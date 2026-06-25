import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mixin que memoriza el último search utilizado **dentro de la misma sección**.
/// Si el usuario abandona la sección (por ejemplo, va a Home) y luego regresa,
/// el search se resetea.
/// Si sólo navegó hacia adelante/atrás **dentro de la misma sección**, conserva.
mixin SearchLifecycleMixin<T> on GetxController {
  // ---------- CONFIGURABLE ----------
  String get sectionName => runtimeType.toString(); // ej. CustomersController
  TextEditingController get searchFieldController;
  String get currentSearchTerm;
  set currentSearchTerm(String value);
  Future<void> onSearchChanged(String newTerm);
  // ----------------------------------

  // Privado
  static final Map<String, _LastSearch> _memory = {};

  @override
  void onReady() {
    super.onReady();
    _handleReturn();
  }

  @override
  void onClose() {
    _saveBeforeClose();
    super.onClose();
  }

  // Lógica central
  void _handleReturn() {
    final last = _memory[sectionName];
    if (last == null) {
      // primera vez o después de abandonar la sección
      _clearSearch();
      return;
    }

    // volvimos a la sección: restauramos
    searchFieldController.text = last.text;
    currentSearchTerm = last.text;
    if (last.text.isNotEmpty) {
      // re-aplicamos sin loader
      onSearchChanged(last.text);
    }
  }

  void _saveBeforeClose() {
    // Guardamos estado **antes** de que GetX destruya el controller
    _memory[sectionName] = _LastSearch(
      text: searchFieldController.text,
      at: DateTime.now(),
    );
  }

  void _clearSearch() {
    searchFieldController.clear();
    currentSearchTerm = '';
    onSearchChanged('');
  }
}

@immutable
class _LastSearch {
  final String text;
  final DateTime at;
  const _LastSearch({required this.text, required this.at});
}
