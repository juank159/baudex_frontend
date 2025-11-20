// lib/app/shared/widgets/password_validation_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_text.dart';
import '../../config/themes/app_colors.dart';

class PasswordValidationDialog extends StatefulWidget {
  final String title;
  final String message;
  final Future<bool> Function(String password) onValidate;

  const PasswordValidationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onValidate,
  });

  @override
  State<PasswordValidationDialog> createState() => _PasswordValidationDialogState();
}

class _PasswordValidationDialogState extends State<PasswordValidationDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await widget.onValidate(_passwordController.text);
      
      if (isValid) {
        if (mounted) {
          Navigator.of(context).pop(true); // Contraseña válida
        }
      } else {
        setState(() {
          _errorMessage = 'Contraseña incorrecta';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al validar contraseña: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveText.getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.warning,
            size: ResponsiveText.getIconSize(context),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: ResponsiveText.getTitleMediumSize(context),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje explicativo
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: ResponsiveText.getSmallIconSize(context),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: ResponsiveText.getBodySmallSize(context),
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: !isMobile, // Auto focus en desktop
                style: TextStyle(
                  fontSize: ResponsiveText.getBodyLargeSize(context),
                ),
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  hintText: 'Ingresa tu contraseña de inicio de sesión',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: ResponsiveText.getSmallIconSize(context),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      size: ResponsiveText.getSmallIconSize(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.grey300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 1,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _validatePassword(),
              ),
              
              // Mensaje de error
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: ResponsiveText.getSmallIconSize(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: ResponsiveText.getBodySmallSize(context),
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Botón Cancelar
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 8 : 12,
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: ResponsiveText.getBodyMediumSize(context),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Botón Validar
        ElevatedButton(
          onPressed: _isLoading ? null : _validatePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 32,
              vertical: isMobile ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Validar',
                  style: TextStyle(
                    fontSize: ResponsiveText.getBodyMediumSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}