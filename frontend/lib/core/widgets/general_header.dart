import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../utils/constants.dart';

class GeneralHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Widget>? actions;
  final List<Color>? gradientColors;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool isCompact;

  const GeneralHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor = AppTheme.ledhouseBlue,
    this.actions,
    this.gradientColors,
    this.showBackButton = false,
    this.onBackPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorsToUse =
        gradientColors ??
        const [AppTheme.primaryColor, AppTheme.secondaryColor];

    final shouldShowBack = showBackButton || onBackPressed != null;

    final effectivePadding = isCompact
        ? const EdgeInsets.fromLTRB(14, 10, 10, 10)
        : const EdgeInsets.fromLTRB(24, 20, 16, 20);

    final iconBoxSize = isCompact ? 36.0 : 44.0;
    final iconInnerSize = isCompact ? 20.0 : 24.0;
    final titleFontSize = isCompact ? 15.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorsToUse,
        ),
      ),
      padding: effectivePadding,
      child: Row(
        children: [
          if (shouldShowBack) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed:
                  onBackPressed ?? () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Volver',
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            ),
            child: Icon(icon, color: iconColor, size: iconInnerSize),
          ),
          SizedBox(width: isCompact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDemoMode) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.amber.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 10,
                              color: Colors.amberAccent,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'DEMO',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }
}

class HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final double iconSize;

  const HeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color = Colors.white,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size <= 36 ? 9 : 12);

    return Padding(
      padding: EdgeInsets.only(right: size <= 36 ? 3.0 : 4.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: borderRadius,
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}
