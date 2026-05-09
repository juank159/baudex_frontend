// lib/features/auth/presentation/widgets/email_autocomplete_field.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class EmailAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  const EmailAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.onTap,
    this.onChanged,
  });

  @override
  State<EmailAutocompleteField> createState() => _EmailAutocompleteFieldState();
}

class _EmailAutocompleteFieldState extends State<EmailAutocompleteField> {
  late AuthController authController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay más amplio (300ms) para dar tiempo a que el tap del item
      // del dropdown se procese antes de cerrar las sugerencias. En
      // desktop el focus puede perderse antes que el tap se capture,
      // así que necesitamos un margen mayor.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_focusNode.hasFocus) {
          authController.hideEmailSuggestions();
        }
      });
    } else {
      authController.displayEmailSuggestions();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo de texto principal
        CustomTextField(
          controller: widget.controller,
          label: widget.label,
          hint: widget.hint,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: widget.validator,
          focusNode: _focusNode,
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          onTap: () {
            authController.displayEmailSuggestions();
            widget.onTap?.call();
          },
        ),

        // Dropdown de sugerencias con animación
        Obx(() {
          if (!authController.showEmailSuggestions ||
              authController.savedEmails.isEmpty) {
            return const SizedBox.shrink();
          }

          final filteredEmails =
              authController.getFilteredEmails(widget.controller.text);
          if (filteredEmails.isEmpty) {
            return const SizedBox.shrink();
          }

          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ElegantLightTheme.elevatedShadow,
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filteredEmails.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 48,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final email = filteredEmails[index];
                    return _buildEmailSuggestionTile(email);
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmailSuggestionTile(String email) {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          // Zona principal: tap = seleccionar el email.
          // Usamos Expanded + InkWell para que ocupe TODO el ancho
          // excepto el botón eliminar.
          Expanded(
            child: InkWell(
              onTap: () {
                authController.selectSavedEmail(email);
                widget.onChanged?.call(email);
                // NO unfocus: el cambio en `_showEmailSuggestions` ya
                // oculta el dropdown. Hacer unfocus aquí cancela el
                // tap si el focusNode se pierde antes de procesar.
              },
              hoverColor: ElegantLightTheme.primaryBlue.withOpacity(0.05),
              splashColor: ElegantLightTheme.primaryBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ElegantLightTheme.primaryBlue
                                .withOpacity(0.1),
                            ElegantLightTheme.primaryBlueLight
                                .withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ElegantLightTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón eliminar SEPARADO con su propio Material+InkWell.
          // No anida con el del email, así no compiten por el tap.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => authController.removeSavedEmail(email),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: ElegantLightTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
