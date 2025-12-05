// lib/features/credit_notes/presentation/widgets/credit_note_status_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/credit_note.dart';

class CreditNoteStatusWidget extends StatelessWidget {
  final CreditNote creditNote;
  final bool isCompact;

  const CreditNoteStatusWidget({
    super.key,
    required this.creditNote,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final gradient = _getStatusGradient();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 3 : 4),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
            ),
            child: Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: isCompact ? 10 : 14,
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 9 : 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (creditNote.status) {
      case CreditNoteStatus.draft:
        return ElegantLightTheme.textSecondary;
      case CreditNoteStatus.confirmed:
        return const Color(0xFF10B981); // Verde éxito
      case CreditNoteStatus.cancelled:
        return const Color(0xFFEF4444); // Rojo error
    }
  }

  LinearGradient _getStatusGradient() {
    switch (creditNote.status) {
      case CreditNoteStatus.draft:
        return LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade500],
        );
      case CreditNoteStatus.confirmed:
        return ElegantLightTheme.successGradient;
      case CreditNoteStatus.cancelled:
        return ElegantLightTheme.errorGradient;
    }
  }

  IconData _getStatusIcon() {
    switch (creditNote.status) {
      case CreditNoteStatus.draft:
        return Icons.edit_outlined;
      case CreditNoteStatus.confirmed:
        return Icons.check_circle_outline;
      case CreditNoteStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusText() {
    switch (creditNote.status) {
      case CreditNoteStatus.draft:
        return 'BORRADOR';
      case CreditNoteStatus.confirmed:
        return 'CONFIRMADA';
      case CreditNoteStatus.cancelled:
        return 'CANCELADA';
    }
  }
}
