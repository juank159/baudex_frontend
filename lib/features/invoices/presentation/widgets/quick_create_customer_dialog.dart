// lib/features/invoices/presentation/widgets/quick_create_customer_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/create_customer_usecase.dart';

/// Dialog rápido para crear un cliente sin salir del flujo de creación
/// de factura. Offline-first: el usecase encola en SyncQueue si no hay
/// red y devuelve un Customer con id temporal `customer_offline_*` que
/// se puede usar inmediatamente en la factura.
///
/// Campos pedidos (mínimos para una venta de mostrador):
///   - Nombre y apellido (requeridos)
///   - Tipo y número de documento (requeridos)
///   - Teléfono (opcional pero recomendado)
///   - Email (opcional — si se omite generamos uno único basado en doc)
class QuickCreateCustomerDialog extends StatefulWidget {
  /// Callback cuando se crea el cliente exitosamente. El padre
  /// típicamente lo usa para seleccionar el cliente recién creado en la
  /// factura.
  final void Function(Customer customer)? onCreated;

  /// Texto inicial para `firstName` (útil cuando el cajero ya tipeó algo
  /// en la búsqueda y no encontró coincidencias).
  final String? prefilledName;

  const QuickCreateCustomerDialog({
    super.key,
    this.onCreated,
    this.prefilledName,
  });

  @override
  State<QuickCreateCustomerDialog> createState() =>
      _QuickCreateCustomerDialogState();
}

class _QuickCreateCustomerDialogState extends State<QuickCreateCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  final _lastNameCtrl = TextEditingController();
  final _documentNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  DocumentType _documentType = DocumentType.cc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.prefilledName ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _documentNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final documentNumber = _documentNumberCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final emailInput = _emailCtrl.text.trim();

    // Email es required en CreateCustomerParams. Si el cajero no lo
    // ingresa generamos uno único basado en el documento — el cliente
    // mostrador típico no tiene email registrado.
    final email = emailInput.isNotEmpty
        ? emailInput
        : 'cliente.${documentNumber.toLowerCase()}@local.baudex';

    try {
      final useCase = Get.find<CreateCustomerUseCase>();
      final result = await useCase(
        CreateCustomerParams(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone.isNotEmpty ? phone : null,
          documentType: _documentType,
          documentNumber: documentNumber,
          status: CustomerStatus.active,
        ),
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          setState(() => _saving = false);
          Get.snackbar(
            'No se pudo crear el cliente',
            failure.toString().replaceAll('Failure(', '').replaceAll(')', ''),
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            duration: const Duration(milliseconds: 2500),
          );
        },
        (customer) {
          if (!mounted) return;
          widget.onCreated?.call(customer);
          Get.back(); // cierra dialog
          Get.snackbar(
            'Cliente creado',
            '${customer.firstName} ${customer.lastName} listo para usar',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(milliseconds: 2000),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        'Error',
        'No se pudo crear el cliente: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(milliseconds: 2500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Nuevo cliente'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<DocumentType>(
                        initialValue: _documentType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo doc',
                          isDense: true,
                        ),
                        items: DocumentType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _documentType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _documentNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Número *',
                          isDense: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9A-Za-z\-]'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (v.trim().length < 4) return 'Muy corto';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    isDense: true,
                    hintText: 'Opcional',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    isDense: true,
                    hintText: 'Opcional, se genera si lo dejas vacío',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check, size: 16),
          label: Text(_saving ? 'Guardando...' : 'Crear y seleccionar'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
