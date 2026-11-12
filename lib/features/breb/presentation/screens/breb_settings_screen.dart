// lib/features/breb/presentation/screens/breb_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';
import '../../data/breb_api.dart';
import '../../domain/breb_charge.dart';

/// Configuración de Bre-B del negocio:
///  - sus llaves (con el QR del banco, para armar el QR con el monto),
///  - la dirección de correo a la que debe reenviar los avisos del banco,
///  - los últimos avisos recibidos que no se conciliaron solos.
class BrebSettingsScreen extends StatefulWidget {
  const BrebSettingsScreen({super.key});

  @override
  State<BrebSettingsScreen> createState() => _BrebSettingsScreenState();
}

class _BrebSettingsScreenState extends State<BrebSettingsScreen> {
  late final BrebApi _api = BrebApi(Get.find<DioClient>());
  late final OrganizationController _organization = Get.find<OrganizationController>();

  List<Map<String, dynamic>> _llaves = [];
  String? _inboundAddress;
  String? _addressError;
  List<Map<String, dynamic>> _recentEmails = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _llaves = brebLlavesOf(_organization.currentOrganization?.settings);
    _loadServerData();
  }

  Future<void> _loadServerData() async {
    try {
      final address = await _api.inboundAddress();
      if (mounted) setState(() => _inboundAddress = address);
    } on BrebException catch (e) {
      if (mounted) setState(() => _addressError = e.message);
    }
    try {
      final emails = await _api.recentEmails();
      if (mounted) setState(() => _recentEmails = emails);
    } on BrebException catch (_) {
      // Solo diagnóstico: sin conexión simplemente no se muestra.
    }
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
    Get.snackbar(
      ok ? 'Llaves guardadas' : 'No se pudo guardar',
      ok ? 'El punto de venta ya puede cobrar por Bre-B.' : (_organization.error ?? 'Intente de nuevo.'),
      snackPosition: SnackPosition.TOP,
      backgroundColor: ok ? Colors.green.shade100 : Colors.red.shade100,
    );
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
      builder: (context) => AlertDialog(
        title: const Text('Quitar llave'),
        content: Text('¿Quitar "${_llaves[index]['label']}"? Ya no se mostrará al cobrar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save(List<Map<String, dynamic>>.from(_llaves)..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bre-B (cobro con QR)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _editLlave(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar llave'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _section(
            'Tus llaves Bre-B',
            'El cliente ve estas llaves al pagar. Con el QR del banco, el sistema arma un QR con el valor exacto de cada venta.',
            [
              if (_llaves.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Todavía no hay llaves. Agrega una para poder cobrar por Bre-B.'),
                ),
              for (var i = 0; i < _llaves.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    (_llaves[i]['qrTemplate']?.toString() ?? '').isNotEmpty ? Icons.qr_code_2 : Icons.key,
                  ),
                  title: Text(_llaves[i]['label']?.toString() ?? 'Llave'),
                  subtitle: Text(
                    '${_llaves[i]['llave']}'
                    '${(_llaves[i]['qrTemplate']?.toString() ?? '').isNotEmpty ? ' · con QR' : ' · sin QR'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: _saving ? null : () => _editLlave(index: i)),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: _saving ? null : () => _removeLlave(i)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            'Correo para los avisos del banco',
            'En el correo donde el banco te avisa cada pago (Nequi o Bancolombia), crea un reenvío automático '
                'de esos avisos a esta dirección. Así el sistema confirma el pago solo.',
            [
              if (_inboundAddress != null)
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _inboundAddress!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _inboundAddress!));
                        Get.snackbar('Copiado', 'Dirección copiada.', snackPosition: SnackPosition.TOP);
                      },
                    ),
                  ],
                )
              else if (_addressError != null)
                Text(_addressError!, style: TextStyle(color: Colors.red.shade700))
              else
                const LinearProgressIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            'Avisos recibidos sin conciliar',
            'Los últimos avisos que llegaron a tu dirección y no se pudieron unir solos a una venta. '
                'Sirve para comprobar que el reenvío funciona.',
            [
              if (_recentEmails.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No hay avisos sin conciliar.'),
                ),
              for (final email in _recentEmails.take(10))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(email['resolved'] == true ? Icons.check_circle_outline : Icons.mail_outline),
                  title: Text(_reasonLabel(email['reason']?.toString())),
                  subtitle: Text([
                    if (email['amount'] != null) '\$${email['amount']}',
                    if ((email['bankLabel'] ?? '').toString().isNotEmpty) email['bankLabel'],
                    if ((email['payerName'] ?? '').toString().isNotEmpty) email['payerName'],
                  ].join(' · ')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String help, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(help, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
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
        return 'Aviso recibido';
    }
  }
}

/// Alta o edición de una llave: nombre, llave y (opcional) el QR del banco.
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
    if (!await _checkTemplate() || !mounted) return;
    Navigator.pop(context, <String, dynamic>{
      'id': widget.initial?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'label': label,
      'llave': llave,
      if (_template.text.trim().isNotEmpty) 'qrTemplate': _template.text.trim(),
      if (widget.initial?['bankAccountId'] != null) 'bankAccountId': widget.initial!['bankAccountId'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Agregar llave Bre-B' : 'Editar llave Bre-B'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _label,
                decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ej. Nequi de la tienda'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _llave,
                decoration: const InputDecoration(labelText: 'Llave', hintText: 'Celular, @alias o correo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _template,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Texto del QR del banco (opcional)',
                  hintText: 'Escanea el QR de tu llave con cualquier lector y pega aquí el texto',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _checking ? null : _checkTemplate,
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(_checking ? 'Probando…' : 'Probar QR con \$1.000'),
                ),
              ),
              if (_previewError != null)
                Text(_previewError!, style: TextStyle(color: Colors.red.shade700)),
              if (_previewPayload != null)
                Center(
                  child: Column(
                    children: [
                      QrImageView(data: _previewPayload!, size: 160, backgroundColor: Colors.white),
                      const Text('El QR es válido. Con tu app del banco debe mostrar \$1.000.'),
                    ],
                  ),
                ),
              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_formError!, style: TextStyle(color: Colors.red.shade700)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _checking ? null : _accept, child: const Text('Guardar')),
      ],
    );
  }
}
