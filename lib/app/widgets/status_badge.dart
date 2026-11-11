import 'package:flutter/material.dart';

/// A reusable status badge widget for displaying item/transaction statuses.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final StatusBadgeType status;

  factory StatusBadge.fromLabel(String label, {String? type}) {
    final lower = label.toLowerCase();
    StatusBadgeType badgeType;
    if (lower.contains('active') || lower.contains('in stock') || lower.contains('completed') || lower.contains('received') || lower.contains('returned') || lower.contains('working')) {
      badgeType = StatusBadgeType.success;
    } else if (lower.contains('pending') || lower.contains('draft') || lower.contains('scheduled') || lower.contains('requested') || lower.contains('sent') || lower.contains('needs repair')) {
      badgeType = StatusBadgeType.warning;
    } else if (lower.contains('overdue') || lower.contains('rejected') || lower.contains('cancelled') || lower.contains('out of stock') || lower.contains('damaged') || lower.contains('error') || lower.contains('condemned') || lower.contains('missing')) {
      badgeType = StatusBadgeType.error;
    } else if (lower.contains('low stock') || lower.contains('partial') || lower.contains('borrowed') || lower.contains('progress')) {
      badgeType = StatusBadgeType.info;
    } else if (lower.contains('approved') || lower.contains('acknowledged') || lower.contains('converted')) {
      badgeType = StatusBadgeType.success;
    } else {
      badgeType = StatusBadgeType.neutral;
    }
    return StatusBadge(label: label, status: badgeType);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color bgColor;
    Color fgColor;

    switch (status) {
      case StatusBadgeType.success:
        bgColor = Colors.green.withValues(alpha: 0.12);
        fgColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
      case StatusBadgeType.warning:
        bgColor = Colors.orange.withValues(alpha: 0.12);
        fgColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      case StatusBadgeType.error:
        bgColor = Colors.red.withValues(alpha: 0.12);
        fgColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
      case StatusBadgeType.info:
        bgColor = Colors.blue.withValues(alpha: 0.12);
        fgColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      case StatusBadgeType.neutral:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        fgColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum StatusBadgeType { success, warning, error, info, neutral }
