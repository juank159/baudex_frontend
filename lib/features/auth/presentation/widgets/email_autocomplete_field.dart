// lib/features/auth/presentation/widgets/email_autocomplete_field.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ocultar sugerencias al hacer tap fuera
        FocusScope.of(context).unfocus();
        authController.hideEmailSuggestions();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Campo de texto principal
        CustomTextField(
          controller: widget.controller,
          label: widget.label,
          hint: widget.hint,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: widget.validator,
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          onTap: () {
            authController.displayEmailSuggestions();
            widget.onTap?.call();
          },
        ),

        // Dropdown de sugerencias
        Obx(() {
          if (!authController.showEmailSuggestions || authController.savedEmails.isEmpty) {
            return const SizedBox.shrink();
          }

          final filteredEmails = authController.getFilteredEmails(widget.controller.text);
          if (filteredEmails.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: filteredEmails.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final email = filteredEmails[index];
                return _buildEmailSuggestionTile(context, email, authController);
              },
            ),
          );
        }),
        ],
      ),
    );
  }

  Widget _buildEmailSuggestionTile(
    BuildContext context,
    String email,
    AuthController authController,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          authController.selectSavedEmail(email);
          widget.onChanged?.call(email);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icono de correo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),

              // Email text
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Botón para eliminar
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                onPressed: () => authController.removeSavedEmail(email),
                tooltip: 'Eliminar correo guardado',
              ),
            ],
          ),
        ),
      ),
    );
  }
}