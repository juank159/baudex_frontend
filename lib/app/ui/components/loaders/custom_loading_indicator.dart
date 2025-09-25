// lib/app/ui/components/loaders/custom_loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const CustomLoadingIndicator({
    super.key,
    this.message,
    this.size = 32.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color ?? Get.theme.colorScheme.primary,
            strokeWidth: 3.0,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}