import 'package:flutter/material.dart';

/// Un botón de cancelación o acción secundaria con estilo delineado (Outlined),
/// diseñado según las guías visuales de los diálogos y formularios de la aplicación.
///
/// Si no se especifica [onPressed], por defecto ejecutará `Navigator.pop(context, false)`.
class CancelButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double? height;

  const CancelButton({
    super.key,
    this.onPressed,
    this.text = 'Cancelar',
    this.isLoading = false,
    this.icon,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.textStyle,
    this.height = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveForegroundColor = foregroundColor ?? Colors.grey.shade700;
    final effectiveBorderColor = borderColor ?? Colors.grey.shade300;
    final minSize = height != null ? Size(64, height!) : null;

    final effectiveStyle = OutlinedButton.styleFrom(
      foregroundColor: effectiveForegroundColor,
      side: BorderSide(color: effectiveBorderColor),
      padding: padding,
      minimumSize: minSize,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    final VoidCallback? effectiveOnPressed = isLoading
        ? null
        : (onPressed ?? () => Navigator.of(context).pop(false));

    final effectiveTextStyle = textStyle ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        style: effectiveStyle,
        icon: Icon(icon, size: 18),
        label: Text(text, style: effectiveTextStyle),
      );
    }

    return OutlinedButton(
      onPressed: effectiveOnPressed,
      style: effectiveStyle,
      child: Text(text, style: effectiveTextStyle),
    );
  }
}
