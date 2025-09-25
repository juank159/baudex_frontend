// lib/app/core/widgets/custom_date_picker.dart
import 'package:baudex_desktop/app/config/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/formatters.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final String hintText;
  final String? labelText;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? errorText;
  final InputDecoration? decoration;

  const CustomDatePicker({
    super.key,
    required this.selectedDate,
    required this.hintText,
    required this.onChanged,
    this.labelText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      child: InputDecorator(
        decoration:
            decoration ??
            InputDecoration(
              labelText: labelText,
              hintText: hintText,
              errorText: errorText,
              suffixIcon: Icon(
                Icons.calendar_today,
                color: enabled ? AppColors.primary : Colors.grey,
              ),
              border: const OutlineInputBorder(),
              enabled: enabled,
            ),
        child: Text(
          selectedDate != null
              ? AppFormatters.formatDate(selectedDate!)
              : hintText,
          style: Get.textTheme.bodyMedium?.copyWith(
            color:
                selectedDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onChanged(picked);
    }
  }

  static Widget field({
    required DateTime? selectedDate,
    required String hintText,
    required ValueChanged<DateTime?> onChanged,
    String? labelText,
    DateTime? firstDate,
    DateTime? lastDate,
    bool enabled = true,
    String? errorText,
  }) {
    return CustomDatePicker(
      selectedDate: selectedDate,
      hintText: hintText,
      onChanged: onChanged,
      labelText: labelText,
      firstDate: firstDate,
      lastDate: lastDate,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
