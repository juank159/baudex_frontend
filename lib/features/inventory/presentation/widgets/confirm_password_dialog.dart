import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/services/password_validation_service.dart';

/// Diálogo reutilizable que pide la contraseña del usuario para
/// confirmar una acción sensible de inventario (ajuste individual,
/// ajustes masivos, futuros borrados con impacto).
///
/// Patrón: StatefulWidget con `TextEditingController` propio en el
/// State. El controller se dispose en `State.dispose()` — no en una
/// variable local tras `await showDialog(...)`. Esto evita el bug
/// "TextEditingController used after disposed" en macOS cuando la
/// animación de cierre del Dialog continúa rebuilding después del pop.
///
/// Retorna `true` si la contraseña fue válida y el usuario confirmó,
/// `false` si canceló o si el dialog se cerró sin confirmar.
Future<bool> showConfirmPasswordDialog({
  required String title,
  required String message,
  String confirmButtonText = 'Confirmar y aplicar',
}) async {
  final result = await Get.dialog<bool>(
    barrierDismissible: false,
    _ConfirmPasswordDialog(
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
    ),
  );
  return result == true;
}

class _ConfirmPasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmButtonText;

  const _ConfirmPasswordDialog({
    required this.title,
    required this.message,
    required this.confirmButtonText,
  });

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Ingrese su contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = Get.find<PasswordValidationService>();
      final valid = await service.validatePassword(password);

      if (!mounted) return;

      if (valid) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Contraseña incorrecta. Verifique e intente de nuevo.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al validar: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera con gradiente warning
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mensaje contextual de la acción
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.warningOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            ElegantLightTheme.warningOrange.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: ElegantLightTheme.warningOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: ElegantLightTheme.warningOrange,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Campo contraseña
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    onSubmitted: (_) => _isLoading ? null : _confirm(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Contraseña del administrador',
                      labelStyle: const TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: ElegantLightTheme.primaryBlue,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: ElegantLightTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.primaryBlue.withOpacity(0.3),
                          width: _errorMessage != null ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.primaryBlue.withOpacity(0.25),
                          width: _errorMessage != null ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ElegantLightTheme.errorRed.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: ElegantLightTheme.errorRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: ElegantLightTheme.errorRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: ElegantLightTheme.textTertiary
                                    .withOpacity(0.4),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : ElegantLightTheme.warningGradient,
                            color: _isLoading
                                ? ElegantLightTheme.cardColor
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _confirm,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              ElegantLightTheme.textSecondary,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          widget.confirmButtonText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
