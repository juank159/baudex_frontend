// lib/features/expenses/presentation/widgets/expense_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../controllers/expenses_controller.dart';
import '../../domain/entities/expense.dart';

class ExpenseFilterWidget extends StatelessWidget {
  final ExpensesController controller;

  const ExpenseFilterWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _clearAllFilters(context),
                child: const Text('Limpiar Todo'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filtros de estado
          _buildStatusFilters(context),
          
          const SizedBox(height: 20),
          
          // Filtros de tipo
          _buildTypeFilters(context),
          
          const SizedBox(height: 20),
          
          // Filtros de fecha
          _buildDateFilters(context),
          
          const SizedBox(height: 20),
          
          // Filtros de monto
          _buildAmountFilters(context),
          
          const SizedBox(height: 24),
          
          // Botones de acción
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Opción "Todos"
            FilterChip(
              label: const Text('Todos'),
              selected: controller.currentStatus == null,
              onSelected: (_) => controller.applyStatusFilter(null),
            ),
            
            // Estados específicos
            ...ExpenseStatus.values.map((status) => FilterChip(
              label: Text(status.displayName),
              selected: controller.currentStatus == status,
              onSelected: (_) => controller.applyStatusFilter(status),
              avatar: _getStatusIcon(status),
            )),
          ],
        )),
      ],
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Gasto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Opción "Todos"
            FilterChip(
              label: const Text('Todos'),
              selected: controller.currentType == null,
              onSelected: (_) => controller.applyTypeFilter(null),
            ),
            
            // Tipos específicos
            ...ExpenseType.values.map((type) => FilterChip(
              label: Text(type.displayName),
              selected: controller.currentType == type,
              onSelected: (_) => controller.applyTypeFilter(type),
            )),
          ],
        )),
      ],
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de Fechas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Filtros predefinidos
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDatePreset(context, 'Hoy', _getTodayRange()),
            _buildDatePreset(context, 'Esta Semana', _getThisWeekRange()),
            _buildDatePreset(context, 'Este Mes', _getThisMonthRange()),
            _buildDatePreset(context, 'Últimos 30 días', _getLast30DaysRange()),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Selector de fecha personalizado
        Row(
          children: [
            Expanded(
              child: Obx(() => OutlinedButton.icon(
                onPressed: () => _selectStartDate(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  controller.startDate != null
                      ? _formatDate(controller.startDate!)
                      : 'Fecha Inicio',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(() => OutlinedButton.icon(
                onPressed: () => _selectEndDate(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  controller.endDate != null
                      ? _formatDate(controller.endDate!)
                      : 'Fecha Fin',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de Monto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Filtros predefinidos de monto
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAmountPreset(context, 'Bajo', 0, 50000),
            _buildAmountPreset(context, 'Medio', 50000, 200000),
            _buildAmountPreset(context, 'Alto', 200000, 1000000),
            _buildAmountPreset(context, 'Muy Alto', 1000000, double.infinity),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePreset(BuildContext context, String label, DateTimeRange range) {
    return Obx(() {
      final isSelected = controller.startDate != null && 
                        controller.endDate != null &&
                        _isSameDay(controller.startDate!, range.start) &&
                        _isSameDay(controller.endDate!, range.end);
      
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.applyDateFilter(range.start, range.end),
      );
    });
  }

  Widget _buildAmountPreset(BuildContext context, String label, double min, double max) {
    return FilterChip(
      label: Text(label),
      selected: false, // TODO: Implementar lógica de selección
      onSelected: (_) {
        // TODO: Implementar filtro por monto
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            onPressed: () => Get.back(),
            type: ButtonType.outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Aplicar Filtros',
            onPressed: () {
              Get.back();
              // Los filtros ya se aplicaron automáticamente
            },
          ),
        ),
      ],
    );
  }

  Widget? _getStatusIcon(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return const Icon(Icons.edit, size: 16, color: Colors.grey);
      case ExpenseStatus.pending:
        return const Icon(Icons.pending_actions, size: 16, color: Colors.orange);
      case ExpenseStatus.approved:
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case ExpenseStatus.rejected:
        return const Icon(Icons.cancel, size: 16, color: Colors.red);
      case ExpenseStatus.paid:
        return const Icon(Icons.payment, size: 16, color: Colors.blue);
    }
  }

  void _clearAllFilters(BuildContext context) {
    controller.clearFilters();
    Get.back();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      controller.applyDateFilter(date, controller.endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.endDate ?? DateTime.now(),
      firstDate: controller.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      controller.applyDateFilter(controller.startDate, date);
    }
  }

  DateTimeRange _getTodayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateTimeRange(start: today, end: endOfDay);
  }

  DateTimeRange _getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: startOfMonth, end: endOfMonth);
  }

  DateTimeRange _getLast30DaysRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}