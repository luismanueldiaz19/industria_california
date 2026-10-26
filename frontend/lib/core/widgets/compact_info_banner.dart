import 'package:flutter/material.dart';

/// Un banner informativo compacto, moderno y reutilizable para consejos,
/// alertas contextuales o accesos rápidos a tours interactivos.
/// Cumple con las directrices de Clean Architecture y Compact UI.
class CompactInfoBanner extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? actionBackgroundColor;
  final Color? actionTextColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const CompactInfoBanner({
    super.key,
    this.icon = Icons.lightbulb_outline_rounded,
    this.iconColor,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.actionBackgroundColor,
    this.actionTextColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? const Color(0xFFD97706); // Amber 600
    final effectiveBgColor =
        backgroundColor ?? const Color(0xFFFFFBEB); // Amber 50
    final effectiveBorderColor =
        borderColor ?? const Color(0xFFFDE68A); // Amber 200
    final effectiveTextColor =
        textColor ?? const Color(0xFF78350F); // Amber 900

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: effectiveIconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: effectiveTextColor,
                  height: 1.3,
                ),
                children: [
                  if (title != null && title!.isNotEmpty) ...[
                    TextSpan(
                      text: '$title ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      actionBackgroundColor ??
                      effectiveIconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: actionBackgroundColor != null
                      ? null
                      : Border.all(
                          color: effectiveIconColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: actionTextColor ?? effectiveIconColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9,
                      color: actionTextColor ?? effectiveIconColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: effectiveTextColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
