import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../controllers/cash_register_controller.dart';

/// Dialog inline para abrir la caja desde cualquier parte de la app
/// (típicamente disparado por `CashRegisterGuard.requireOpen`).
///
/// A diferencia del dialog interno de `cash_register_screen.dart`,
/// este NO navega a la pantalla de caja — se monta in-place encima
/// del contexto actual. Esencial cuando el usuario está en el form
/// de crear factura con ítems agregados: si tuviera que navegar a la
/// pantalla de caja perdería sus ítems.
///
/// Retorna `true` si la apertura fue exitosa, `false` si canceló o falló.
Future<bool> showOpenCashRegisterDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OpenCashRegisterDialog(),
  );
  return result == true;
}

class _OpenCashRegisterDialog extends StatefulWidget {
  const _OpenCashRegisterDialog();

  @override
  State<_OpenCashRegisterDialog> createState() =>
      _OpenCashRegisterDialogState();
}

class _OpenCashRegisterDialogState extends State<_OpenCashRegisterDialog> {
  // Controllers manejados por el State del dialog → dispose en el
  // momento correcto (cuando el árbol del dialog se desmonta). Esto
  // evita el bug histórico de "TextEditingController used after
  // being disposed" que aparecía cuando los controllers se creaban
  // como variables locales y se disponían tras el `await showDialog`.
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!Get.isRegistered<CashRegisterController>()) {
      // Navigator.pop (no Get.back) porque el dialog se montó con
      // `showDialog<bool>`, que NO está en el stack de rutas de GetX.
      // Get.back cerraría la pantalla padre o no haría nada → bug del
      // dialog colgado tras apertura exitosa.
      Navigator.of(context).pop(false);
      return;
    }
    final amount = AppFormatters.parseNumber(_amountCtrl.text) ?? 0;
    final notes = _notesCtrl.text.trim();
    // ignore: avoid_print
    print('[OPEN_DIALOG] submit → amount=$amount notes="$notes"');
    setState(() => _submitting = true);
    final ctrl = Get.find<CashRegisterController>();
    // Try/catch + finally garantizan que el spinner SIEMPRE se quita,
    // aun si la repo lanza (timeout, red caída, parse error, etc.).
    // Sin este wrapper el dialog se quedaba en "Abriendo..." infinito.
    bool ok = false;
    try {
      ok = await ctrl.open(
        openingAmount: amount,
        openingNotes: notes.isEmpty ? null : notes,
      );
      // ignore: avoid_print
      print('[OPEN_DIALOG] ctrl.open returned: $ok');
    } catch (e, st) {
      // ignore: avoid_print
      print('[OPEN_DIALOG] EXCEPTION: $e\n$st');
      Get.snackbar(
        'Error',
        'No se pudo abrir la caja: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        // SingleChildScrollView protege del teclado en celular.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Abrir caja',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Registra el monto con que inicias el turno',
                    style: TextStyle(
                      fontSize: 13,
                      color: ElegantLightTheme.textSecondary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amountCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  // Formateador con separador de miles, mismo patrón
                  // que se usa en formularios de productos, gastos y
                  // demás campos monetarios de la app. Reemplaza al
                  // FilteringTextInputFormatter crudo que solo dejaba
                  // pasar dígitos sin formato visual.
                  inputFormatters: [PriceInputFormatter()],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto inicial *',
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                      color: ElegantLightTheme.successGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    helperText: 'Efectivo con que arranca la caja del día.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el monto inicial';
                    }
                    final n = AppFormatters.parseNumber(v);
                    if (n == null || n < 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: Apertura del turno mañana',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _handleSubmit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_open_rounded, size: 18),
                        label: Text(_submitting ? 'Abriendo...' : 'Abrir caja'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ElegantLightTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
