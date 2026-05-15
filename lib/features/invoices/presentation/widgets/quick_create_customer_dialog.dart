// lib/features/invoices/presentation/widgets/quick_create_customer_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/create_customer_usecase.dart';

/// Dialog rápido para crear un cliente sin salir del flujo de creación
/// de factura. Offline-first: el usecase encola en SyncQueue si no hay
/// red y devuelve un Customer con id temporal `customer_offline_*` que
/// se puede usar inmediatamente en la factura.
class QuickCreateCustomerDialog extends StatefulWidget {
  final void Function(Customer customer)? onCreated;
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
  // Defaults idénticos al formulario completo de clientes
  // (`customer_form_controller.dart:196`) para que un cliente creado
  // rápido desde el form de factura tenga el mismo tratamiento que uno
  // creado por el flujo largo. Antes el quick-dialog no enviaba estos
  // campos y el cliente quedaba con `creditLimit=0` → cualquier factura
  // a crédito posterior reventaba con "LÍMITE DE CRÉDITO EXCEDIDO".
  static const double _defaultCreditLimit = 3000000;
  static const int _defaultPaymentTerms = 30;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  final _lastNameCtrl = TextEditingController();
  final _documentNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  late final TextEditingController _creditLimitCtrl;
  late final TextEditingController _paymentTermsCtrl;

  DocumentType _documentType = DocumentType.cc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.prefilledName ?? '');
    _creditLimitCtrl = TextEditingController(
      text: AppFormatters.formatNumber(_defaultCreditLimit.toInt()),
    );
    _paymentTermsCtrl = TextEditingController(
      text: _defaultPaymentTerms.toString(),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _documentNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _creditLimitCtrl.dispose();
    _paymentTermsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final documentNumber = _documentNumberCtrl.text.trim();
    // Normalizar a formato +57XXXXXXXXXX antes de enviar (lo que exige
    // el backend). El validador ya garantiza que el dato es válido.
    final phone = _normalizeColombianPhone(_phoneCtrl.text);
    final emailInput = _emailCtrl.text.trim();

    final email = emailInput.isNotEmpty
        ? emailInput
        : 'cliente.${documentNumber.toLowerCase()}@local.baudex';

    // Crédito y términos: si el usuario los dejó vacíos o inválidos
    // caemos al default para no crear un cliente "roto" que después no
    // pueda comprar a crédito.
    final creditLimitValue =
        AppFormatters.parseNumber(_creditLimitCtrl.text) ?? _defaultCreditLimit;
    final paymentTermsValue =
        int.tryParse(_paymentTermsCtrl.text.trim()) ?? _defaultPaymentTerms;

    try {
      final useCase = Get.find<CreateCustomerUseCase>();
      final result = await useCase(
        CreateCustomerParams(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: (phone != null && phone.isNotEmpty) ? phone : null,
          documentType: _documentType,
          documentNumber: documentNumber,
          status: CustomerStatus.active,
          creditLimit: creditLimitValue,
          paymentTerms: paymentTermsValue,
        ),
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          setState(() => _saving = false);
          _showSnack(
            'No se pudo crear el cliente',
            failure.toString().replaceAll('Failure(', '').replaceAll(')', ''),
            isError: true,
          );
        },
        (customer) {
          if (!mounted) return;
          widget.onCreated?.call(customer);
          Get.back();
          _showSnack(
            'Cliente creado',
            '${customer.firstName} ${customer.lastName} listo para usar',
            isError: false,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Error', 'No se pudo crear el cliente: $e', isError: true);
    }
  }

  void _showSnack(String title, String message, {required bool isError}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError
          ? ElegantLightTheme.errorRed.withValues(alpha: 0.95)
          : ElegantLightTheme.successGreen.withValues(alpha: 0.95),
      colorText: Colors.white,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
      duration: Duration(milliseconds: isError ? 2500 : 2000),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Ancho responsive: en pantallas pequeñas usa casi todo el ancho.
    final dialogWidth = size.width < 480
        ? size.width - 32
        : (size.width < 800 ? 440.0 : 480.0);
    // Alto máximo: nunca exceder el viewport.
    final maxHeight = size.height - 80;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ElegantLightTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Form(key: _formKey, child: _buildFormFields()),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nuevo cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Acceso rápido desde la factura',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _saving ? null : () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _elegantField(
          controller: _firstNameCtrl,
          label: 'Nombre',
          icon: Icons.person_outline,
          required: true,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        _elegantField(
          controller: _lastNameCtrl,
          label: 'Apellido',
          icon: Icons.person_outline,
          required: true,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        _buildDocumentRow(),
        const SizedBox(height: 12),
        _elegantField(
          controller: _phoneCtrl,
          label: 'Teléfono',
          icon: Icons.phone_outlined,
          hint: 'Ej: 3001234567 (10 dígitos colombianos)',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
          ],
          validator: _validateColombianPhone,
        ),
        const SizedBox(height: 12),
        _elegantField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          hint: 'Opcional, se genera si lo dejas vacío',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildCreditSection(),
      ],
    );
  }

  /// Sección de crédito: límite + días de plazo. Pre-rellenada con los
  /// mismos defaults del form completo de clientes para que cualquier
  /// cliente creado por aquí pueda inmediatamente comprar a crédito.
  /// El usuario puede ajustarlos o dejarlos como están.
  Widget _buildCreditSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_score_outlined,
                size: 16,
                color: ElegantLightTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              const Text(
                'Crédito',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.primaryBlue,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '— condiciones para facturas a crédito',
                  style: TextStyle(
                    fontSize: 11,
                    color: ElegantLightTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final limitField = _elegantField(
                controller: _creditLimitCtrl,
                label: 'Límite de crédito',
                icon: Icons.attach_money,
                hint: 'Ej: 3.000.000',
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = AppFormatters.parseNumber(v);
                  if (n == null || n < 0) return 'Inválido';
                  return null;
                },
              );
              final termsField = _elegantField(
                controller: _paymentTermsCtrl,
                label: 'Plazo (días)',
                icon: Icons.event_outlined,
                hint: '30',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Inválido';
                  return null;
                },
              );
              if (isNarrow) {
                return Column(
                  children: [
                    limitField,
                    const SizedBox(height: 10),
                    termsField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: limitField),
                  const SizedBox(width: 10),
                  SizedBox(width: 120, child: termsField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Fila de tipo + número de documento. Antes había overflow porque el
  /// dropdown era estrecho; ahora usamos LayoutBuilder y, en pantallas
  /// muy angostas, apilamos los campos en columna.
  Widget _buildDocumentRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDocumentTypeDropdown(),
              const SizedBox(height: 12),
              _elegantField(
                controller: _documentNumberCtrl,
                label: 'Número de documento',
                icon: Icons.badge_outlined,
                required: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\-]')),
                ],
                validator: _validateDocumentNumber,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: _buildDocumentTypeDropdown(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _elegantField(
                controller: _documentNumberCtrl,
                label: 'Número',
                icon: Icons.badge_outlined,
                required: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\-]')),
                ],
                validator: _validateDocumentNumber,
              ),
            ),
          ],
        );
      },
    );
  }

  String? _validateDocumentNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    if (v.trim().length < 4) return 'Muy corto';
    return null;
  }

  /// Valida formato de teléfono colombiano (lo que el backend exige).
  /// Reglas:
  ///   - Vacío → válido (campo opcional).
  ///   - 10 dígitos limpios (3001234567) → válido (se agrega +57 al guardar).
  ///   - +573001234567 (12 dígitos con prefijo) → válido.
  ///   - Cualquier otra cosa → error con mensaje claro al usuario.
  ///
  /// Esto evita el caso real reportado: el usuario creó un cliente con
  /// teléfono no-colombiano y el backend lo rechazó con HTTP 400, perdiendo
  /// silenciosamente el dato. Ahora ni siquiera deja escribirlo así.
  String? _validateColombianPhone(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final cleaned = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.length == 10 && RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return null;
    }
    if (cleaned.length == 13 &&
        cleaned.startsWith('+57') &&
        RegExp(r'^\+57\d{10}$').hasMatch(cleaned)) {
      return null;
    }
    return 'Debe ser un teléfono colombiano (10 dígitos o +57XXXXXXXXXX)';
  }

  /// Normaliza el teléfono al formato que el backend acepta antes de
  /// enviarlo: si vienen 10 dígitos limpios, antepone '+57'. Si ya viene
  /// con +57 lo deja tal cual.
  String? _normalizeColombianPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.length == 10 && RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return '+57$cleaned';
    }
    if (cleaned.startsWith('+57')) return cleaned;
    return cleaned;
  }

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<DocumentType>(
      value: _documentType,
      isExpanded: true,
      decoration: _elegantInputDecoration(
        label: 'Tipo doc *',
        icon: Icons.assignment_ind_outlined,
      ),
      items: DocumentType.values
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(
                t.name.toUpperCase(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _documentType = v);
      },
    );
  }

  Widget _elegantField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: _elegantInputDecoration(
        label: required ? '$label *' : label,
        icon: icon,
        hint: hint,
      ),
    );
  }

  InputDecoration _elegantInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ElegantLightTheme.primaryBlue, size: 18),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: ElegantLightTheme.primaryBlue,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ElegantLightTheme.errorRed),
      ),
      labelStyle: const TextStyle(
        color: ElegantLightTheme.textSecondary,
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.7),
        fontSize: 12,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _saving ? null : () => Get.back(),
              style: TextButton.styleFrom(
                foregroundColor: ElegantLightTheme.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _saving
                    ? null
                    : ElegantLightTheme.primaryGradient,
                color: _saving
                    ? ElegantLightTheme.textTertiary.withValues(alpha: 0.4)
                    : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _saving
                    ? null
                    : [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saving)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _saving ? 'Guardando...' : 'Crear y seleccionar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
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
