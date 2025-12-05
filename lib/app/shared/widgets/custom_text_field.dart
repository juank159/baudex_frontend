// File: lib/app/shared/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/elegant_light_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final int maxLines;
  final String? helperText;
  final String? errorText;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.helperText,
    this.errorText,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  TextEditingController? _internalController;
  late TextEditingController _activeController;

  @override
  void initState() {
    super.initState();
    try {
      _initializeController();
    } catch (e) {
      print('❌ Error en initState de CustomTextField: $e');
      // Crear fallback controller si falla la inicialización
      _internalController = TextEditingController();
      _activeController = _internalController!;
    }
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el controller externo cambió, reinicializar de forma segura
    if (oldWidget.controller != widget.controller) {
      try {
        _initializeController();
      } catch (e) {
        print('❌ Error en didUpdateWidget de CustomTextField: $e');
        // Crear controlador interno de emergencia
        _internalController?.dispose();
        _internalController = TextEditingController();
        _activeController = _internalController!;
      }
    }
  }

  @override
  void dispose() {
    // Solo liberar el controlador interno si lo creamos nosotros
    _internalController?.dispose();
    super.dispose();
  }

  /// ✅ SOLUCIÓN RADICAL: Inicializar controlador seguro
  void _initializeController() {
    // Si hay un controller externo y está seguro, usarlo
    if (widget.controller != null && _isExternalControllerSafe()) {
      _activeController = widget.controller!;
      // Limpiar controller interno si existe
      _internalController?.dispose();
      _internalController = null;
    } else {
      // Crear/mantener controller interno seguro
      _internalController ??= TextEditingController();
      _activeController = _internalController!;

      // Si había un controller externo pero se volvió inseguro, copiamos su valor si es posible
      if (widget.controller != null) {
        try {
          final externalText = widget.controller!.text;
          if (_internalController!.text != externalText) {
            _internalController!.text = externalText;
          }
        } catch (e) {
          print(
            '⚠️ CustomTextField: No se pudo copiar texto del controller externo disposed',
          );
        }
      }
    }
  }

  /// ✅ VERIFICACIÓN ULTRA-SEGURA: Verificar controller externo
  bool _isExternalControllerSafe() {
    if (widget.controller == null) return false;

    try {
      // Verificación básica: el controller existe
      final controller = widget.controller!;

      // Verificación 1: Propiedades básicas (estas fallan si el controller está disposed)
      final _ = controller.text;
      final __ = controller.selection;
      final ___ = controller.value;

      // Verificación 2: Intentar agregar/remover listener (detecta disposed más profundamente)
      void testListener() {}
      controller.addListener(testListener);
      controller.removeListener(testListener);

      // Verificación 3: Intentar acceder a métodos (estos también fallan si disposed)
      final ____ = controller.toString();

      // Verificación 4: Test específico para disposed flag (más directo)
      if (controller.toString().contains('DISPOSED')) {
        print(
          '⚠️ CustomTextField: Controller disposed detectado en toString()',
        );
        return false;
      }

      return true;
    } catch (e) {
      print(
        '⚠️ CustomTextField: Controller externo disposed detectado (${widget.label}) - $e',
      );
      return false;
    }
  }

  /// ✅ VERIFICACIÓN DEL CONTROLLER ACTIVO
  bool _isActiveControllerSafe() {
    try {
      // Verificaciones más robustas para detectar disposal
      final _ = _activeController.text;
      final __ = _activeController.selection;
      final ___ = _activeController.value;

      // Si llegamos aquí, el controller está OK
      return true;
    } catch (e) {
      // Controller probablemente disposed o en mal estado
      print('⚠️ CustomTextField: _activeController no seguro - $e');
      return false;
    }
  }

  /// ✅ CREAR CONTROLLER INTERNO SEGURO COMO FALLBACK
  void _createSafeInternalController() {
    try {
      // Liberar controller interno anterior si existe
      _internalController?.dispose();

      // Crear nuevo controller interno
      _internalController = TextEditingController();
      _activeController = _internalController!;

      print(
        '✅ CustomTextField: Controller interno seguro creado para ${widget.label}',
      );
    } catch (e) {
      print('❌ Error creando controller interno: $e');
    }
  }

  /// ✅ WIDGET BÁSICO CUANDO NO ESTÁ MOUNTED O HAY PROBLEMAS
  Widget _buildBasicTextField() {
    // Crear un controller completamente nuevo y seguro para el fallback
    final fallbackController = TextEditingController();

    return TextFormField(
      controller: fallbackController,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        helperText: widget.helperText,
        errorText: widget.errorText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ VERIFICACIÓN CRÍTICA: Solo verificar si el widget está mounted
    if (!mounted) {
      print('⚠️ CustomTextField: Widget no mounted, usando controller básico');
      return _buildBasicTextField();
    }

    // ✅ VERIFICACIÓN PREVENTIVA ULTRA-ROBUSTA MEJORADA
    // Usar Builder simple en lugar de LayoutBuilder para evitar problemas de eventos
    return Builder(
      builder: (context) {
        // ✅ VERIFICACIÓN ADICIONAL: Evitar reconstrucción durante dispose
        try {
          // Verificar si estamos en proceso de dispose
          if (!mounted) {
            print(
              '⚠️ CustomTextField: Widget no mounted durante build, usando fallback',
            );
            return _buildBasicTextField();
          }

          if (widget.controller != null && !_isExternalControllerSafe()) {
            // Si el controller externo está disposed, re-inicializar INMEDIATAMENTE
            _initializeController();
          }

          // ✅ VERIFICACIÓN FINAL: Asegurar que el _activeController esté seguro
          if (!_isActiveControllerSafe()) {
            print(
              '❌ CustomTextField: _activeController no seguro, recreando...',
            );
            _createSafeInternalController();
          }

          // ✅ VERIFICACIÓN FINAL antes de usar el controller
          if (!_isActiveControllerSafe()) {
            print(
              '⚠️ CustomTextField: Fallback completo, usando widget básico',
            );
            return _buildBasicTextField();
          }
        } catch (e) {
          print(
            '❌ CustomTextField: Error en verificaciones, usando fallback - $e',
          );
          return _buildBasicTextField();
        }

        return FocusScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: ValueKey('${widget.label}_${_activeController.hashCode}'),
                controller:
                    _isActiveControllerSafe() ? _activeController : null,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                validator: widget.validator,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                onTap: widget.onTap,
                onChanged: (value) {
                  // Manejar cambios de forma segura
                  try {
                    widget.onChanged?.call(value);

                    // Si estamos usando controller interno pero hay uno externo, intentar sincronizar
                    if (_internalController != null &&
                        widget.controller != null &&
                        _isExternalControllerSafe()) {
                      widget.controller!.text = value;
                    }
                  } catch (e) {
                    print('⚠️ CustomTextField: Error en onChanged - $e');
                  }
                },
                inputFormatters: widget.inputFormatters,
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  prefixIcon:
                      widget.prefixIcon != null
                          ? Icon(widget.prefixIcon)
                          : null,
                  suffixIcon:
                      widget.suffixIcon != null
                          ? IconButton(
                            icon: Icon(
                              widget.suffixIcon,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                            onPressed: widget.onSuffixIconPressed,
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.0,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      widget.enabled ? Colors.white : Colors.grey.shade50,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.isMobile ? 16.0 : 20.0,
                    vertical: context.isMobile ? 16.0 : 18.0,
                  ),
                  helperText: widget.helperText,
                  errorText: widget.errorText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
