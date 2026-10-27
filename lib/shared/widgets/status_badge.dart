import 'package:flutter/material.dart';

enum BadgeType {
  success,
  warning,
  error,
  info,
  neutral;
}

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeType type;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = BadgeType.neutral,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case BadgeType.success:
        bg = isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
        border = isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0);
        break;
      case BadgeType.warning:
        bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        border = isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A);
        break;
      case BadgeType.error:
        bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B);
        border = isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
        break;
      case BadgeType.info:
        bg = isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE);
        fg = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF);
        border = isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE);
        break;
      case BadgeType.neutral:
        bg = isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);
        fg = isDark ? const Color(0xFFE5E5E5) : const Color(0xFF374151);
        border = isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
        break;
    }

    return Semantics(
      label: '$label status badge',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 12 : 14, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
