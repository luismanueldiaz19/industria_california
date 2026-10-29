import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/app_theme.dart';

class InputField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hint;
  final IconData? icon;
  final Color iconColor;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool optional;
  final bool isRequired;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final Widget? suffixIcon;
  final bool obscureText;
  final FocusNode? focusNode;
  final Color focusedBorderColor;
  final bool isDark;
  final bool dense;
  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;

  const InputField({
    super.key,
    this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.iconColor = AppTheme.successColor,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.optional = false,
    this.isRequired = false,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.suffixIcon,
    this.obscureText = false,
    this.focusNode,
    this.focusedBorderColor = AppTheme.successColor,
    this.isDark = false,
    this.dense = false,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.textStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = labelStyle?.color ??
        (isDark ? Colors.grey.shade300 : const Color(0xFF374151));
    final effectiveTextColor = textStyle?.color ??
        (isDark ? Colors.white : const Color(0xFF1F2937));
    final effectiveFillColor = fillColor ??
        (isDark ? AppTheme.darkInputColor : const Color(0xFFF9FAFB));
    final effectiveBorderColor = borderColor ??
        (isDark ? AppTheme.darkBorderColor : Colors.grey.shade200);
    final effectiveRadius = borderRadius ?? (dense ? 8.0 : 14.0);
    final effectivePadding = dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: labelStyle ??
                  TextStyle(
                    fontSize: dense ? 11.5 : 13,
                    fontWeight: FontWeight.w600,
                    color: effectiveLabelColor,
                  ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
            if (optional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Opcional',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: dense ? 4 : 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          obscureText: obscureText,
          style: textStyle ??
              TextStyle(
                fontSize: dense ? 12.5 : 14,
                color: effectiveTextColor,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: dense ? 11.5 : 13,
            ),
            prefixIcon: icon != null
                ? Container(
                    margin: EdgeInsets.all(dense ? 6 : 10),
                    width: dense ? 28 : 36,
                    height: dense ? 28 : 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(dense ? 8 : 10),
                    ),
                    child: Icon(icon, color: iconColor, size: dense ? 15 : 18),
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: effectiveFillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            contentPadding: effectivePadding,
          ),
        ),
      ],
    );
  }
}
