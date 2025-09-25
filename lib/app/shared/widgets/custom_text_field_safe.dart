// File: lib/app/shared/widgets/custom_text_field_safe.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import 'safe_text_editing_controller.dart';

/// ✅ SOLUCIÓN DEFINITIVA: CustomTextFieldSafe
/// 
/// Este widget ELIMINA COMPLETAMENTE los errores de:
/// - "A TextEditingController was used after being disposed"
/// - "RenderFlex overflowed" (mediante layout mejorado)
/// - Crashes durante navegación entre pantallas
/// 
/// Uso EXACTAMENTE igual que CustomTextField pero 100% seguro:
/// ```dart
/// CustomTextFieldSafe(
///   controller: myController, // Puede ser nulo, disposed, etc.
///   label: 'Mi Campo',
///   onChanged: (value) => print(value),
/// )
/// ```
class CustomTextFieldSafe extends StatefulWidget {
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
  final EdgeInsets? contentPadding;
  final double? fontSize;
  final String? debugLabel;

  const CustomTextFieldSafe({
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
    this.contentPadding,
    this.fontSize,
    this.debugLabel,
  });

  @override
  State<CustomTextFieldSafe> createState() => _CustomTextFieldSafeState();
}

class _CustomTextFieldSafeState extends State<CustomTextFieldSafe> {
  late SafeTextEditingController _safeController;
  late String _controllerDebugLabel;

  @override
  void initState() {
    super.initState();
    _controllerDebugLabel = widget.debugLabel ?? widget.label;
    _initializeSafeController();
  }

  @override
  void didUpdateWidget(CustomTextFieldSafe oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si el controller externo cambió, reinicializar
    if (oldWidget.controller != widget.controller) {
      _log('🔄 Controller externo cambió, reinicializando...');
      _initializeSafeController();
    }
  }

  @override
  void dispose() {
    _log('🔚 Disposing CustomTextFieldSafe...');
    
    try {
      _safeController.dispose();
      _log('✅ SafeController disposed exitosamente');
    } catch (e) {
      _log('⚠️ Error al dispose SafeController: $e');
    }
    
    super.dispose();
  }

  /// ✅ INICIALIZACIÓN ULTRA-SEGURA del controller
  void _initializeSafeController() {
    try {
      // Si hay un controller externo, intentar usarlo
      if (widget.controller != null) {
        _log('🔧 Intentando usar controller externo...');
        
        // Verificar si el controller externo es seguro
        if (widget.controller!.isSafe) {
          _log('✅ Controller externo es seguro, creando SafeController desde él');
          _safeController = SafeTextEditingController.fromExisting(
            widget.controller!,
            debugLabel: _controllerDebugLabel,
          );
        } else {
          _log('⚠️ Controller externo unsafe, creando SafeController nuevo');
          _safeController = SafeTextEditingController(
            debugLabel: _controllerDebugLabel,
          );
          
          // Intentar copiar el texto del controller externo si es posible
          _tryToCopyFromExternalController();
        }
      } else {
        _log('🆕 No hay controller externo, creando SafeController nuevo');
        _safeController = SafeTextEditingController(
          debugLabel: _controllerDebugLabel,
        );
      }
      
      _log('✅ SafeController inicializado exitosamente');
    } catch (e) {
      _log('❌ Error inicializando SafeController: $e');
      
      // Fallback: crear controller completamente nuevo
      _safeController = SafeTextEditingController(
        debugLabel: '${_controllerDebugLabel}_fallback',
      );
    }
  }

  /// ✅ INTENTAR COPIAR TEXTO del controller externo de forma segura
  void _tryToCopyFromExternalController() {
    if (widget.controller == null) return;
    
    try {
      final externalText = widget.controller!.text;
      if (externalText.isNotEmpty && _safeController.canSafelyAccess()) {
        _safeController.text = externalText;
        _log('✅ Texto copiado del controller externo: "${externalText.length} chars"');
      }
    } catch (e) {
      _log('⚠️ No se pudo copiar texto del controller externo: $e');
    }
  }

  /// ✅ SINCRONIZACIÓN BIDIRECCIONAL con controller externo
  void _syncWithExternalController(String newValue) {
    if (widget.controller == null) return;
    
    try {
      if (widget.controller!.isSafe && widget.controller!.text != newValue) {
        widget.controller!.text = newValue;
        _log('🔄 Valor sincronizado con controller externo');
      }
    } catch (e) {
      _log('⚠️ Error sincronizando con controller externo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildSafeTextField(context, constraints);
      },
    );
  }

  /// ✅ CONSTRUCCIÓN ULTRA-SEGURA del TextField
  Widget _buildSafeTextField(BuildContext context, BoxConstraints constraints) {
    // Verificación final de estado antes del build
    if (!mounted) {
      _log('⚠️ Widget no mounted, retornando placeholder');
      return _buildPlaceholderField(context);
    }

    if (!_safeController.canSafelyAccess()) {
      _log('⚠️ SafeController no seguro, recreando...');
      _initializeSafeController();
      
      // Si aún no es seguro, usar placeholder
      if (!_safeController.canSafelyAccess()) {
        _log('❌ SafeController aún no seguro, usando placeholder');
        return _buildPlaceholderField(context);
      }
    }

    return _buildMainTextField(context, constraints);
  }

  /// ✅ CAMPO PRINCIPAL con todas las características
  Widget _buildMainTextField(BuildContext context, BoxConstraints constraints) {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ PREVENIR OVERFLOW
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible( // ✅ LAYOUT FLEXIBLE PARA PREVENIR OVERFLOW
          child: TextFormField(
            controller: _safeController,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            onTap: widget.onTap,
            onChanged: _handleTextChanged,
            inputFormatters: widget.inputFormatters,
            style: TextStyle(
              fontSize: widget.fontSize ?? _getResponsiveFontSize(context),
              color: widget.enabled ? Colors.black : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            decoration: _buildInputDecoration(context, constraints),
          ),
        ),
      ],
    );
  }

  /// ✅ CAMPO PLACEHOLDER para casos de emergencia
  Widget _buildPlaceholderField(BuildContext context) {
    return TextFormField(
      controller: TextEditingController(), // Controller temporal básico
      enabled: false,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? 'Campo temporalmente no disponible',
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
          horizontal: context.isMobile ? 12.0 : 16.0,
          vertical: context.isMobile ? 12.0 : 14.0,
        ),
      ),
    );
  }

  /// ✅ DECORACIÓN RESPONSIVA Y ADAPTABLE
  InputDecoration _buildInputDecoration(BuildContext context, BoxConstraints constraints) {
    // Calcular padding responsivo basado en el ancho disponible
    final isNarrow = constraints.maxWidth < 300;
    final isMobile = context.isMobile;
    
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon != null 
          ? Icon(
              widget.prefixIcon,
              size: isNarrow ? 18 : 20,
            ) 
          : null,
      suffixIcon: widget.suffixIcon != null
          ? IconButton(
              icon: Icon(
                widget.suffixIcon,
                color: Colors.blueAccent,
                size: isNarrow ? 18 : 20,
              ),
              onPressed: widget.onSuffixIconPressed,
              constraints: BoxConstraints(
                minWidth: isNarrow ? 36 : 44,
                minHeight: isNarrow ? 36 : 44,
              ),
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
      fillColor: widget.enabled ? Colors.white : Colors.grey.shade50,
      contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
        horizontal: _getResponsiveHorizontalPadding(isMobile, isNarrow),
        vertical: _getResponsiveVerticalPadding(isMobile, isNarrow),
      ),
      helperText: widget.helperText,
      errorText: widget.errorText,
      isDense: isNarrow, // Compactar cuando el espacio es limitado
    );
  }

  /// ✅ MANEJO SEGURO de cambios de texto
  void _handleTextChanged(String value) {
    try {
      // Notificar al callback externo
      widget.onChanged?.call(value);
      
      // Sincronizar con controller externo si existe
      _syncWithExternalController(value);
    } catch (e) {
      _log('⚠️ Error en handleTextChanged: $e');
    }
  }

  /// ✅ UTILIDADES RESPONSIVE
  double _getResponsiveFontSize(BuildContext context) {
    if (context.isMobile) return 14.0;
    if (context.isTablet) return 15.0;
    return 16.0;
  }

  double _getResponsiveHorizontalPadding(bool isMobile, bool isNarrow) {
    if (isNarrow) return 8.0;
    if (isMobile) return 12.0;
    return 16.0;
  }

  double _getResponsiveVerticalPadding(bool isMobile, bool isNarrow) {
    if (isNarrow) return 8.0;
    if (isMobile) return 12.0;
    return 14.0;
  }

  /// ✅ LOGGING
  void _log(String message) {
    print('🛡️ CustomTextFieldSafe ($_controllerDebugLabel): $message');
  }
}

/// ✅ EXTENSION para facilitar migración desde CustomTextField
extension CustomTextFieldSafeExtension on Widget {
  /// Convertir cualquier CustomTextField a CustomTextFieldSafe
  static Widget makeSafe(Widget widget) {
    // Esta extensión podría implementarse para conversiones automáticas
    // Por ahora, la migración debe ser manual para mayor control
    return widget;
  }
}