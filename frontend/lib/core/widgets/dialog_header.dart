import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class DialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Color>? gradientColors;
  final VoidCallback? onClose;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const DialogHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.receipt_long_rounded,
    this.gradientColors,
    this.onClose,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorsToUse =
        gradientColors ?? [AppTheme.primaryBlue, AppTheme.secondaryBlue];

    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorsToUse,
        ),
        borderRadius:
            borderRadius ??
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.of(context).pop(false),
            tooltip: 'Cerrar',
            splashRadius: 20,
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
