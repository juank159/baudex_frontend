// lib/features/reports/presentation/widgets/date_range_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';

class DateRangePickerWidget extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;
  final String label;

  const DateRangePickerWidget({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
    this.label = 'Rango de Fechas',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDateRangePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range),
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (startDate != null || endDate != null)
                IconButton(
                  onPressed: () => onDateRangeChanged(null, null),
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Limpiar',
                ),
              IconButton(
                onPressed: () => _showQuickRanges(context),
                icon: const Icon(Icons.expand_more, size: 16),
                tooltip: 'Rangos rápidos',
              ),
            ],
          ),
        ),
        child: Text(
          _formatDateRange(),
          style: Get.textTheme.bodyMedium,
        ),
      ),
    );
  }

  String _formatDateRange() {
    if (startDate == null && endDate == null) {
      return 'Seleccionar rango de fechas';
    }
    
    if (startDate != null && endDate != null) {
      return '${AppFormatters.formatDate(startDate!)} - ${AppFormatters.formatDate(endDate!)}';
    }
    
    if (startDate != null) {
      return 'Desde ${AppFormatters.formatDate(startDate!)}';
    }
    
    if (endDate != null) {
      return 'Hasta ${AppFormatters.formatDate(endDate!)}';
    }
    
    return 'Seleccionar rango de fechas';
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      onDateRangeChanged(range.start, range.end);
    }
  }

  void _showQuickRanges(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        PopupMenuItem(
          value: 'today',
          child: Row(
            children: [
              const Icon(Icons.today, size: 16),
              const SizedBox(width: 8),
              const Text('Hoy'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'yesterday',
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              const Text('Ayer'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'last7days',
          child: Row(
            children: [
              const Icon(Icons.date_range, size: 16),
              const SizedBox(width: 8),
              const Text('Últimos 7 días'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'last30days',
          child: Row(
            children: [
              const Icon(Icons.date_range, size: 16),
              const SizedBox(width: 8),
              const Text('Últimos 30 días'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'thismonth',
          child: Row(
            children: [
              const Icon(Icons.calendar_view_month, size: 16),
              const SizedBox(width: 8),
              const Text('Este mes'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'lastmonth',
          child: Row(
            children: [
              const Icon(Icons.calendar_view_month, size: 16),
              const SizedBox(width: 8),
              const Text('Mes anterior'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'thisquarter',
          child: Row(
            children: [
              const Icon(Icons.calendar_view_week, size: 16),
              const SizedBox(width: 8),
              const Text('Este trimestre'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'thisyear',
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              const Text('Este año'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _applyQuickRange(value);
      }
    });
  }

  void _applyQuickRange(String range) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (range) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'last7days':
        start = now.subtract(const Duration(days: 6));
        end = now;
        break;
      case 'last30days':
        start = now.subtract(const Duration(days: 29));
        end = now;
        break;
      case 'thismonth':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'lastmonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = lastMonth;
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'thisquarter':
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        start = quarterStart;
        end = now;
        break;
      case 'thisyear':
        start = DateTime(now.year, 1, 1);
        end = now;
        break;
      default:
        return;
    }

    onDateRangeChanged(start, end);
  }
}