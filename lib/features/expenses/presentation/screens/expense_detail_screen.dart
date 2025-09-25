// lib/features/expenses/presentation/screens/expense_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/expense_detail_controller.dart';
import '../../domain/entities/expense.dart';

class ExpenseDetailScreen extends GetView<ExpenseDetailController> {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: LoadingWidget());
        }

        final expense = controller.expense.value;
        if (expense == null) {
          return _buildErrorState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context, expense),
          tablet: _buildTabletLayout(context, expense),
          desktop: _buildDesktopLayout(context, expense),
        );
      }),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Detalle del Gasto'),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      // actions: [
      //   Obx(() {
      //     final expense = controller.expense.value;
      //     if (expense == null) return const SizedBox.shrink();

      //     return PopupMenuButton<String>(
      //       onSelected: (action) => _handleAction(action, context, expense),
      //       itemBuilder: (context) => [
      //         if (expense.canBeEdited) ...[
      //           const PopupMenuItem(
      //             value: 'edit',
      //             child: Row(
      //               children: [
      //                 Icon(Icons.edit, size: 16),
      //                 SizedBox(width: 8),
      //                 Text('Editar'),
      //               ],
      //             ),
      //           ),
      //         ],

      //         const PopupMenuItem(
      //           value: 'duplicate',
      //           child: Row(
      //             children: [
      //               Icon(Icons.copy, size: 16),
      //               SizedBox(width: 8),
      //               Text('Duplicar'),
      //             ],
      //           ),
      //         ),

      //         const PopupMenuItem(
      //           value: 'export',
      //           child: Row(
      //             children: [
      //               Icon(Icons.download, size: 16),
      //               SizedBox(width: 8),
      //               Text('Exportar'),
      //             ],
      //           ),
      //         ),

      //         if (expense.canBeDeleted) ...[
      //           const PopupMenuDivider(),
      //           const PopupMenuItem(
      //             value: 'delete',
      //             child: Row(
      //               children: [
      //                 Icon(Icons.delete, size: 16, color: Colors.red),
      //                 SizedBox(width: 8),
      //                 Text('Eliminar', style: TextStyle(color: Colors.red)),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ],
      //     );
      //   }),
      // ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Expense expense) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(context, expense),
          const SizedBox(height: 16),
          _buildStatusCard(context, expense),
          const SizedBox(height: 16),
          _buildDetailsCard(context, expense),
          const SizedBox(height: 16),
          _buildPaymentCard(context, expense),
          if (expense.attachments?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildAttachmentsCard(context, expense),
          ],
          if (expense.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildNotesCard(context, expense),
          ],
          const SizedBox(height: 100), // Espacio para bottom actions
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, Expense expense) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, expense),
                const SizedBox(height: 20),
                _buildDetailsCard(context, expense),
                const SizedBox(height: 20),
                _buildPaymentCard(context, expense),
                if (expense.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  _buildNotesCard(context, expense),
                ],
              ],
            ),
          ),
        ),

        // Panel lateral
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildStatusCard(context, expense),
                if (expense.attachments?.isNotEmpty == true)
                  Expanded(child: _buildAttachmentsCard(context, expense)),
                if (expense.attachments?.isEmpty == true)
                  const Expanded(child: _EmptyAttachmentsWidget()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Expense expense) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context, expense),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDetailsCard(context, expense)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildPaymentCard(context, expense)),
                    ],
                  ),
                  if (expense.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    _buildNotesCard(context, expense),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Panel lateral derecho
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildStatusCard(context, expense),
                const Divider(height: 1),
                if (expense.attachments?.isNotEmpty == true)
                  Expanded(child: _buildAttachmentsCard(context, expense)),
                if (expense.attachments?.isEmpty == true)
                  const Expanded(child: _EmptyAttachmentsWidget()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${expense.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    expense.formattedAmount,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildInfoItem(
                  context,
                  Icons.calendar_today,
                  'Fecha',
                  _formatDate(expense.date),
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  context,
                  Icons.category,
                  'Tipo',
                  expense.type.displayName,
                ),
                if (expense.vendor != null) ...[
                  const SizedBox(width: 24),
                  _buildInfoItem(
                    context,
                    Icons.store,
                    'Proveedor',
                    expense.vendor!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Expense expense) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado y Flujo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Estado actual
            _buildStatusItem(context, expense.status),

            const SizedBox(height: 16),

            // Timeline del gasto
            _buildTimeline(context, expense),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              context,
              'Categoría',
              'Obtener nombre de categoría',
            ), // TODO: Implementar
            _buildDetailRow(
              context,
              'Método de Pago',
              expense.paymentMethod.displayName,
            ),

            if (expense.invoiceNumber != null)
              _buildDetailRow(
                context,
                'Número de Factura',
                expense.invoiceNumber!,
              ),

            if (expense.reference != null)
              _buildDetailRow(context, 'Referencia', expense.reference!),

            if (expense.tags?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Etiquetas',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    expense.tags!.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Pago',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(context, 'Monto', expense.formattedAmount),
            _buildDetailRow(
              context,
              'Método',
              expense.paymentMethod.displayName,
            ),

            if (expense.paidAt != null)
              _buildDetailRow(
                context,
                'Fecha de Pago',
                _formatDate(expense.paidAt!),
              ),

            if (expense.approvedAt != null) ...[
              _buildDetailRow(
                context,
                'Aprobado el',
                _formatDate(expense.approvedAt!),
              ),
              if (expense.approvedBy != null)
                _buildDetailRow(context, 'Aprobado por', expense.approvedBy!),
            ],

            if (expense.rejectedAt != null) ...[
              _buildDetailRow(
                context,
                'Rechazado el',
                _formatDate(expense.rejectedAt!),
              ),
              if (expense.rejectionReason != null)
                _buildDetailRow(context, 'Motivo', expense.rejectionReason!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(BuildContext context, Expense expense) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjuntos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: expense.attachments!.length,
                itemBuilder: (context, index) {
                  final attachment = expense.attachments![index];
                  return ListTile(
                    leading: _getFileIcon(attachment),
                    title: Text(attachment),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadAttachment(attachment),
                    ),
                    onTap: () => _openAttachment(attachment),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, Expense expense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(expense.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    if (!GetPlatform.isMobile) return const SizedBox.shrink();

    return Obx(() {
      final expense = controller.expense.value;
      if (expense == null) return const SizedBox.shrink();

      final actions = <Widget>[];

      if (expense.canBeSubmitted) {
        actions.add(
          Expanded(
            child: CustomButton(
              text: 'Enviar',
              onPressed: () => controller.submitExpense(),
              icon: Icons.send,
            ),
          ),
        );
      }

      if (expense.canBeApproved) {
        if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
        actions.add(
          Expanded(
            child: CustomButton(
              text: 'Aprobar',
              onPressed: () => controller.approveExpense(),
              icon: Icons.check_circle,
              backgroundColor: Colors.green,
            ),
          ),
        );
      }

      if (actions.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: Row(children: actions),
      );
    });
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).hintColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusItem(BuildContext context, ExpenseStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            status.displayName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, Expense expense) {
    final events = <Map<String, dynamic>>[];

    events.add({
      'title': 'Gasto Creado',
      'date': expense.createdAt,
      'icon': Icons.add_circle,
      'color': Colors.blue,
    });

    if (expense.submittedAt != null) {
      events.add({
        'title': 'Enviado para Aprobación',
        'date': expense.submittedAt,
        'icon': Icons.send,
        'color': Colors.orange,
      });
    }

    if (expense.approvedAt != null) {
      events.add({
        'title': 'Aprobado',
        'date': expense.approvedAt,
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    if (expense.rejectedAt != null) {
      events.add({
        'title': 'Rechazado',
        'date': expense.rejectedAt,
        'icon': Icons.cancel,
        'color': Colors.red,
      });
    }

    if (expense.paidAt != null) {
      events.add({
        'title': 'Pagado',
        'date': expense.paidAt,
        'icon': Icons.payment,
        'color': Colors.purple,
      });
    }

    return Column(
      children:
          events.map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(event['icon'], color: event['color'], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['title'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _formatDate(event['date']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Gasto no encontrado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(text: 'Volver', onPressed: () => Get.back()),
        ],
      ),
    );
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return Colors.grey;
      case ExpenseStatus.pending:
        return Colors.orange;
      case ExpenseStatus.approved:
        return Colors.green;
      case ExpenseStatus.rejected:
        return Colors.red;
      case ExpenseStatus.paid:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return Icons.edit;
      case ExpenseStatus.pending:
        return Icons.pending_actions;
      case ExpenseStatus.approved:
        return Icons.check_circle;
      case ExpenseStatus.rejected:
        return Icons.cancel;
      case ExpenseStatus.paid:
        return Icons.payment;
    }
  }

  Widget _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image, color: Colors.blue);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.indigo);
      default:
        return const Icon(Icons.attach_file, color: Colors.grey);
    }
  }

  void _handleAction(String action, BuildContext context, Expense expense) {
    switch (action) {
      case 'edit':
        Get.toNamed('/expenses/edit/${expense.id}');
        break;
      case 'duplicate':
        _duplicateExpense(expense);
        break;
      case 'export':
        _exportExpense(expense);
        break;
      case 'delete':
        _confirmDelete(context, expense);
        break;
    }
  }

  void _duplicateExpense(Expense expense) {
    Get.toNamed('/expenses/create', arguments: {'duplicate': expense});
  }

  void _exportExpense(Expense expense) {
    // Implementar exportación
    Get.snackbar('Info', 'Función de exportación próximamente disponible');
  }

  void _confirmDelete(BuildContext context, Expense expense) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Está seguro que desea eliminar el gasto "${expense.description}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteExpense();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _openAttachment(String attachment) {
    // Implementar apertura de adjunto
    Get.snackbar('Info', 'Abriendo: $attachment');
  }

  void _downloadAttachment(String attachment) {
    // Implementar descarga de adjunto
    Get.snackbar('Info', 'Descargando: $attachment');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyAttachmentsWidget extends StatelessWidget {
  const _EmptyAttachmentsWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_file, size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 16),
          Text(
            'Sin Adjuntos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este gasto no tiene archivos adjuntos',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
