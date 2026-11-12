// lib/features/breb/presentation/screens/breb_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';
import '../../data/breb_api.dart';
import '../../domain/breb_charge.dart';
import '../widgets/breb_ui.dart';

/// Configuración de Bre-B del negocio:
///  - sus llaves (con el QR del banco, para armar el QR con el monto),
///  - la dirección de correo a la que debe reenviar los avisos del banco,
///  - los últimos correos recibidos que no se conciliaron solos.
class BrebSettingsScreen extends StatefulWidget {
  /// Para pruebas: servidor simulado.
  final BrebApi? api;

  const BrebSettingsScreen({super.key, this.api});

  @override
  State<BrebSettingsScreen> createState() => _BrebSettingsScreenState();
}

class _BrebSettingsScreenState extends State<BrebSettingsScreen> {
  late final BrebApi _api = widget.api ?? BrebApi(Get.find<DioClient>());
  late final OrganizationController _organization = Get.find<OrganizationController>();

  List<Map<String, dynamic>> _llaves = [];
  String? _inboundAddress;
  String? _addressError;
  List<Map<String, dynamic>>? _recentEmails;
  bool _saving = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _llaves = brebLlavesOf(_organization.currentOrganization?.settings);
    _loadServerData();
  }

  Future<void> _loadServerData() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final address = await _api.inboundAddress();
      if (mounted) {
        setState(() {
          _inboundAddress = address;
          _addressError = null;
        });
      }
    } on BrebException catch (e) {
      if (mounted) setState(() => _addressError = e.message);
    }
    try {
      final emails = await _api.recentEmails();
      if (mounted) setState(() => _recentEmails = emails);
    } on BrebException catch (_) {
      // Solo diagnóstico: sin conexión se muestra la lista vacía.
      if (mounted) setState(() => _recentEmails ??= const []);
    }
    if (mounted) setState(() => _refreshing = false);
  }

  /// Guarda SOLO las llaves Bre-B; el resto de la configuración no se toca.
  Future<void> _save(List<Map<String, dynamic>> llaves) async {
    setState(() => _saving = true);
    final ok = await _organization.updateCurrentOrganization({
      'settings': {
        'breb': {'llaves': llaves},
      },
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _llaves = llaves;
    });
    if (ok) {
      FuturisticNotifications.showSuccess(
        'Llaves guardadas',
        llaves.isEmpty
            ? 'El punto de venta ya no muestra el cobro por Bre-B.'
            : 'El punto de venta ya puede cobrar por Bre-B.',
      );
    } else {
      FuturisticNotifications.showError(
        'No se pudo guardar',
        _organization.error ?? 'Revisa la conexión e intenta de nuevo.',
      );
    }
  }

  Future<void> _editLlave({int? index}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _LlaveDialog(api: _api, initial: index == null ? null : _llaves[index]),
    );
    if (result == null) return;
    final next = List<Map<String, dynamic>>.from(_llaves);
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    await _save(next);
  }

  Future<void> _removeLlave(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => brebAlertDialog(
        title: brebDialogTitle(
          Icons.delete_outline,
          'Quitar llave',
          gradient: ElegantLightTheme.errorGradient,
        ),
        content: Text(
          '¿Quitar "${_llaves[index]['label']}"? Ya no se mostrará al cobrar por Bre-B.',
          style: const TextStyle(color: ElegantLightTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(style: brebTextButtonStyle(),onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: brebPrimaryButtonStyle(color: ElegantLightTheme.errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save(List<Map<String, dynamic>>.from(_llaves)..removeAt(index));
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    FuturisticNotifications.showSuccess('Copiado', '$what quedó en el portapapeles.');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 700;
    return MainLayout(
      title: 'Bre-B (cobro con QR)',
      showBackButton: true,
      showDrawer: false,
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          icon: _refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh),
          onPressed: _refreshing ? null : _loadServerData,
        ),
        const SizedBox(width: 8),
      ],
      body: Container(
        color: ElegantLightTheme.backgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _llavesCard(wide),
                  SizedBox(height: wide ? 24 : 16),
                  _addressCard(),
                  SizedBox(height: wide ? 24 : 16),
                  _emailsCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Llaves ─────────────────────────────

  Widget _llavesCard(bool wide) {
    return BrebSectionCard(
      icon: Icons.key_rounded,
      title: 'Tus llaves Bre-B',
      subtitle: 'El cliente ve estas llaves al pagar. Con el QR del banco, el sistema arma un QR '
          'con el valor exacto de cada venta.',
      action: ElevatedButton.icon(
        key: const Key('breb-add-llave'),
        style: brebPrimaryButtonStyle(),
        onPressed: _saving ? null : () => _editLlave(),
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add, size: 18),
        label: Text(wide ? 'Agregar llave' : 'Agregar'),
      ),
      children: [
        if (_llaves.isEmpty)
          const BrebEmptyState(
            icon: Icons.qr_code_2,
            message: 'Todavía no hay llaves. Agrega una para poder cobrar por Bre-B.',
          ),
        for (var i = 0; i < _llaves.length; i++) _llaveTile(i),
      ],
    );
  }

  Widget _llaveTile(int i) {
    final llave = _llaves[i];
    final hasQr = (llave['qrTemplate']?.toString() ?? '').isNotEmpty;
    return BrebRowTile(
      leading: BrebIconBadge(
        icon: hasQr ? Icons.qr_code_2 : Icons.key_rounded,
        gradient: hasQr ? ElegantLightTheme.successGradient : ElegantLightTheme.infoGradient,
        size: 18,
        glow: false,
      ),
      title: llave['label']?.toString() ?? 'Llave',
      subtitle: llave['llave']?.toString(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrebChip(
            label: hasQr ? 'Con QR' : 'Sin QR',
            color: hasQr ? ElegantLightTheme.successGreen : ElegantLightTheme.textSecondary,
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 20, color: ElegantLightTheme.primaryBlue),
            onPressed: _saving ? null : () => _editLlave(index: i),
          ),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.delete_outline, size: 20, color: ElegantLightTheme.errorRed),
            onPressed: _saving ? null : () => _removeLlave(i),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Correo para los avisos ───────────────────────

  Widget _addressCard() {
    return BrebSectionCard(
      icon: Icons.forward_to_inbox_rounded,
      gradient: ElegantLightTheme.warningGradient,
      title: 'Correo para los avisos del banco',
      subtitle: 'En el correo donde el banco te avisa cada pago (Nequi o Bancolombia), crea un reenvío '
          'automático de esos avisos a esta dirección. Así el sistema confirma el pago solo.',
      children: [
        if (_inboundAddress != null)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _inboundAddress!,
                    key: const Key('breb-inbound-address'),
                    style: const TextStyle(
                      color: ElegantLightTheme.primaryBlueDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar dirección',
                  icon: const Icon(Icons.copy_rounded, size: 20, color: ElegantLightTheme.primaryBlue),
                  onPressed: () => _copy(_inboundAddress!, 'La dirección'),
                ),
              ],
            ),
          )
        else if (_addressError != null)
          BrebNotice.error(_addressError!)
        else
          const BrebInlineLoading('Consultando tu dirección…'),
      ],
    );
  }

  // ─────────────────────────── Correos recibidos ───────────────────────────

  Widget _emailsCard() {
    final emails = _recentEmails;
    return BrebSectionCard(
      icon: Icons.mark_email_unread_outlined,
      gradient: ElegantLightTheme.infoGradient,
      title: 'Correos recibidos sin conciliar',
      subtitle: 'Los últimos correos que llegaron a tu dirección y no se unieron solos a una venta. '
          'Aquí llega también el código que Gmail envía para confirmar el reenvío: toca el correo para leerlo.',
      children: [
        if (emails == null)
          const BrebInlineLoading('Consultando correos recibidos…')
        else if (emails.isEmpty)
          const BrebEmptyState(
            icon: Icons.inbox_outlined,
            message: 'No hay correos sin conciliar.',
          )
        else
          for (final email in emails.take(10)) _emailTile(email),
      ],
    );
  }

  Widget _emailTile(Map<String, dynamic> email) {
    final resolved = email['resolved'] == true;
    final details = [
      if (email['amount'] != null) AppFormatters.formatCurrency(email['amount'] as num),
      if ((email['bankLabel'] ?? '').toString().isNotEmpty) email['bankLabel'].toString(),
      if ((email['payerName'] ?? '').toString().isNotEmpty) email['payerName'].toString(),
      if (_receivedAt(email) != null) _receivedAt(email)!,
    ].join(' · ');
    return BrebRowTile(
      // Siempre se puede tocar: abre el detalle del correo.
      onTap: () => _showEmail(email),
      leading: BrebIconBadge(
        icon: resolved ? Icons.check_circle_outline : Icons.mail_outline_rounded,
        gradient: resolved ? ElegantLightTheme.successGradient : ElegantLightTheme.infoGradient,
        size: 18,
        glow: false,
      ),
      title: _reasonLabel(email['reason']?.toString()),
      subtitle: details.isEmpty ? 'Toca para leer el correo' : details,
      trailing: const Icon(Icons.chevron_right, color: ElegantLightTheme.textTertiary),
    );
  }

  static String _bodyOf(Map<String, dynamic> email) => (email['body'] ?? '').toString().trim();

  static String? _receivedAt(Map<String, dynamic> email) {
    final date = DateTime.tryParse(email['receivedAt']?.toString() ?? '')?.toLocal();
    return date == null ? null : AppFormatters.formatDateTime(date);
  }

  /// Detalle del correo recibido. Aquí se lee, por ejemplo, el código que
  /// Gmail envía para confirmar el reenvío automático de los avisos.
  void _showEmail(Map<String, dynamic> email) {
    final body = _bodyOf(email);
    showDialog<void>(
      context: context,
      builder: (context) => brebAlertDialog(
        title: brebDialogTitle(Icons.mail_outline_rounded, _reasonLabel(email['reason']?.toString())),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_receivedAt(email) != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Recibido: ${_receivedAt(email)}',
                      style: const TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                if (body.isEmpty)
                  const BrebNotice.info(
                    'El servidor no entregó el texto de este correo. Presiona "Actualizar" en la pantalla '
                    'de Bre-B; si sigue igual, el servidor aún no tiene la versión que lo envía.',
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3)),
                    ),
                    child: SelectableText(
                      body,
                      key: const Key('breb-email-body'),
                      style: const TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 13, height: 1.45),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (body.isNotEmpty)
            TextButton.icon(
              style: brebTextButtonStyle(),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copiar texto'),
              onPressed: () => _copy(body, 'El texto del correo'),
            ),
          ElevatedButton(
            style: brebPrimaryButtonStyle(),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static String _reasonLabel(String? reason) {
    switch (reason) {
      case 'not_approved':
        return 'Correo que no es de un banco reconocido';
      case 'not_a_sale':
        return 'Correo del banco que no es un pago recibido';
      case 'parse_error':
        return 'Aviso que no se pudo leer';
      case 'status_rejected':
        return 'Transacción no aprobada';
      case 'no_pending_match':
        return 'Pago sin un cobro pendiente por ese valor';
      case 'multiple_matches':
        return 'Pago que coincide con varios cobros';
      case 'registration_failed':
        return 'Pago recibido que no se pudo registrar';
      case 'already_claimed':
        return 'Pago repetido para un cobro ya confirmado';
      default:
        return 'Correo recibido';
    }
  }
}

/// Alta o edición de una llave: nombre, llave y (opcional) el QR del banco y
/// la cuenta donde entra la plata.
class _LlaveDialog extends StatefulWidget {
  final BrebApi api;
  final Map<String, dynamic>? initial;
  const _LlaveDialog({required this.api, this.initial});

  @override
  State<_LlaveDialog> createState() => _LlaveDialogState();
}

class _LlaveDialogState extends State<_LlaveDialog> {
  late final _label = TextEditingController(text: widget.initial?['label']?.toString() ?? '');
  late final _llave = TextEditingController(text: widget.initial?['llave']?.toString() ?? '');
  late final _template = TextEditingController(text: widget.initial?['qrTemplate']?.toString() ?? '');
  String? _previewPayload;
  String? _previewError;
  String? _formError;
  bool _checking = false;

  /// Cuenta bancaria de Baudex donde entra la plata de esta llave (opcional).
  late String? _bankAccountId = widget.initial?['bankAccountId']?.toString();
  List<BankAccount> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  /// Cuentas bancarias del negocio, si el módulo está disponible.
  Future<void> _loadAccounts() async {
    try {
      if (!Get.isRegistered<BankAccountsController>()) return;
      final accounts = Get.find<BankAccountsController>();
      if (accounts.bankAccounts.isEmpty) await accounts.loadBankAccounts();
      if (mounted) setState(() => _accounts = accounts.activeAccounts);
    } catch (_) {
      // Sin cuentas: la llave se guarda sin cuenta asociada.
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _llave.dispose();
    _template.dispose();
    super.dispose();
  }

  /// Arma un QR de prueba por $1.000 con la plantilla pegada: si el servidor
  /// la acepta, sirve.
  Future<bool> _checkTemplate() async {
    final template = _template.text.trim();
    if (template.isEmpty) {
      setState(() {
        _previewPayload = null;
        _previewError = null;
      });
      return true;
    }
    setState(() => _checking = true);
    try {
      final payload = await widget.api.previewQr(template, 1000);
      if (mounted) {
        setState(() {
          _previewPayload = payload;
          _previewError = null;
        });
      }
      return true;
    } on BrebException catch (e) {
      if (mounted) {
        setState(() {
          _previewPayload = null;
          _previewError = e.message;
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _accept() async {
    final label = _label.text.trim();
    final llave = _llave.text.trim();
    if (label.isEmpty || llave.length < 4) {
      setState(() => _formError = 'Escribe un nombre y la llave (mínimo 4 caracteres).');
      return;
    }
    setState(() => _formError = null);
    if (!await _checkTemplate() || !mounted) return;
    Navigator.pop(context, <String, dynamic>{
      'id': widget.initial?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'label': label,
      'llave': llave,
      if (_template.text.trim().isNotEmpty) 'qrTemplate': _template.text.trim(),
      if (_bankAccountId != null) 'bankAccountId': _bankAccountId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return brebAlertDialog(
      title: brebDialogTitle(
        widget.initial == null ? Icons.add_circle_outline : Icons.edit_outlined,
        widget.initial == null ? 'Agregar llave Bre-B' : 'Editar llave Bre-B',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              TextField(
                key: const Key('breb-llave-label'),
                controller: _label,
                decoration: brebInputDecoration(
                  label: 'Nombre',
                  hint: 'Ej. Nequi de la tienda',
                  icon: Icons.label_outline,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('breb-llave-value'),
                controller: _llave,
                decoration: brebInputDecoration(
                  label: 'Llave',
                  hint: 'Celular, @alias o correo',
                  icon: Icons.key_rounded,
                ),
              ),
              if (_accounts.isNotEmpty) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  key: const Key('breb-llave-account'),
                  value: _accounts.any((a) => a.id == _bankAccountId) ? _bankAccountId : null,
                  isExpanded: true,
                  decoration: brebInputDecoration(
                    label: 'Cuenta donde entra la plata (opcional)',
                    helper: 'Los pagos de esta llave suman al saldo de esa cuenta.',
                    icon: Icons.account_balance_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Sin cuenta')),
                    for (final account in _accounts)
                      DropdownMenuItem<String?>(value: account.id, child: Text(account.name)),
                  ],
                  onChanged: (value) => setState(() => _bankAccountId = value),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                key: const Key('breb-llave-template'),
                controller: _template,
                maxLines: 3,
                decoration: brebInputDecoration(
                  label: 'Texto del QR del banco (opcional)',
                  hint: 'Escanea el QR de tu llave con cualquier lector y pega aquí el texto',
                  helper: 'Con él, cada venta muestra un QR con su valor exacto.',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: brebSecondaryButtonStyle(),
                onPressed: _checking ? null : _checkTemplate,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2, size: 18),
                label: Text(_checking ? 'Probando…' : 'Probar QR con \$1.000'),
              ),
              if (_previewError != null) ...[
                const SizedBox(height: 10),
                BrebNotice.error(_previewError!),
              ],
              if (_previewPayload != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.elevatedShadow,
                    ),
                    child: QrImageView(data: _previewPayload!, size: 160, backgroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                const BrebNotice.success(
                  'El QR es válido. Al escanearlo con la app de tu banco debe mostrar \$1.000.',
                ),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 10),
                BrebNotice.error(_formError!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(style: brebTextButtonStyle(),onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          key: const Key('breb-llave-save'),
          style: brebPrimaryButtonStyle(),
          onPressed: _checking ? null : _accept,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
