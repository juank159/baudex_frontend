// lib/features/invoices/presentation/screens/invoice_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';

class InvoiceSettingsScreen extends StatelessWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Configuración de Facturas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  // Layout para móviles
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumberingSection(context),
          SizedBox(height: context.verticalSpacing),
          _buildFormatSection(context),
          SizedBox(height: context.verticalSpacing),
          _buildTaxSection(context),
          SizedBox(height: context.verticalSpacing),
          _buildDefaultsSection(context),
        ],
      ),
    );
  }

  // Layout para tablets
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildNumberingSection(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildFormatSection(context)),
                ],
              ),
              SizedBox(height: context.verticalSpacing),
              Row(
                children: [
                  Expanded(child: _buildTaxSection(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildDefaultsSection(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Layout para desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildNumberingSection(context),
                        SizedBox(height: context.verticalSpacing),
                        _buildTaxSection(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildFormatSection(context),
                        SizedBox(height: context.verticalSpacing),
                        _buildDefaultsSection(context),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberingSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_list_numbered, color: Colors.blue.shade600, size: context.isMobile ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  'Numeración de Facturas',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),
            
            // Prefijo
            _buildSettingField(
              context,
              label: 'Prefijo',
              value: 'FACT-',
              hint: 'Ejemplo: FACT-, INV-, etc.',
              icon: Icons.text_fields,
            ),
            
            const SizedBox(height: 12),
            
            // Número inicial
            _buildSettingField(
              context,
              label: 'Número inicial',
              value: '1000',
              hint: 'Número desde donde empezar',
              icon: Icons.looks_one,
            ),
            
            const SizedBox(height: 12),
            
            // Formato actual
            Container(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.preview, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vista previa',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          'FACT-1000, FACT-1001, FACT-1002...',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.green.shade600, size: context.isMobile ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  'Formato de Facturas',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),
            
            // Formato de fecha
            _buildFormatOption(
              context,
              title: 'Formato de fecha',
              current: 'DD/MM/YYYY',
              options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
              icon: Icons.calendar_today,
            ),
            
            const SizedBox(height: 16),
            
            // Formato de moneda
            _buildFormatOption(
              context,
              title: 'Formato de moneda',
              current: '\$ 1.234.567',
              options: ['\$ 1.234.567', '\$ 1,234,567', '1.234.567 \$'],
              icon: Icons.attach_money,
            ),
            
            const SizedBox(height: 16),
            
            // Idioma
            _buildFormatOption(
              context,
              title: 'Idioma',
              current: 'Español (Colombia)',
              options: ['Español (Colombia)', 'Español (México)', 'English (US)'],
              icon: Icons.language,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent, color: Colors.orange.shade600, size: context.isMobile ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  'Configuración de Impuestos',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),
            
            // IVA por defecto
            _buildSettingField(
              context,
              label: 'IVA por defecto (%)',
              value: '19',
              hint: 'Porcentaje de IVA predeterminado',
              icon: Icons.calculate,
            ),
            
            const SizedBox(height: 12),
            
            // Switch para incluir IVA
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: SwitchListTile(
                title: Text(
                  'Incluir IVA por defecto',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Aplicar IVA automáticamente en nuevas facturas',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                    color: Colors.grey.shade600,
                  ),
                ),
                value: true,
                activeColor: Colors.orange.shade600,
                onChanged: (value) {
                  // TODO: Implementar lógica
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.indigo.shade600, size: context.isMobile ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  'Valores por Defecto',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),
            
            // Términos y condiciones
            _buildSettingField(
              context,
              label: 'Términos y condiciones',
              value: 'Pago a 30 días',
              hint: 'Términos de pago predeterminados',
              icon: Icons.description,
              maxLines: 2,
            ),
            
            const SizedBox(height: 12),
            
            // Notas por defecto
            _buildSettingField(
              context,
              label: 'Notas por defecto',
              value: 'Gracias por su compra',
              hint: 'Nota que aparecerá en todas las facturas',
              icon: Icons.note,
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Información adicional
            Container(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade50,
                    Colors.indigo.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.indigo.shade600,
                    size: context.isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💼 Configuración Empresarial',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 13, tablet: 14, desktop: 15),
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estos valores se aplicarán automáticamente a todas las nuevas facturas que crees.',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingField(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 13, tablet: 14, desktop: 15),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 15, desktop: 16),
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? 12 : 16,
              vertical: context.isMobile ? 12 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required String title,
    required String current,
    required List<String> options,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 13, tablet: 14, desktop: 15),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 12 : 16,
            vertical: context.isMobile ? 8 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: current,
                  isExpanded: true,
                  underline: Container(),
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 15, desktop: 16),
                    color: Colors.grey.shade800,
                  ),
                  items: options.map((option) => 
                    DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    // TODO: Implementar lógica de cambio
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}