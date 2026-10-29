import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class DropDownWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final IconData? icon;
  final Color iconColor;
  final List<T>? items;
  final List<DropdownMenuItem<T>>? customItems;
  final String Function(T)? itemLabel;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final bool optional;
  final bool isRequired;
  final bool isDark;
  final bool dense;
  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final TextStyle? labelStyle;

  const DropDownWidget({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor = AppTheme.successColor,
    this.items,
    this.customItems,
    this.itemLabel,
    required this.onChanged,
    this.validator,
    this.hint,
    this.optional = false,
    this.isRequired = false,
    this.isDark = false,
    this.dense = false,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.labelStyle,
  }) : assert(
         items != null || customItems != null,
         'Debe proporcionar items o customItems',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = labelStyle?.color ??
        (isDark ? Colors.grey.shade300 : const Color(0xFF374151));
    final effectiveFillColor = fillColor ??
        (isDark ? AppTheme.darkInputColor : const Color(0xFFF9FAFB));
    final effectiveBorderColor = borderColor ??
        (isDark ? AppTheme.darkBorderColor : Colors.grey.shade200);
    final effectiveRadius = borderRadius ?? (dense ? 8.0 : 14.0);
    final effectivePadding = dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    final dropdownItems =
        customItems ??
        (items?.map((item) {
              final text = itemLabel != null
                  ? itemLabel!(item)
                  : item.toString().toUpperCase();
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: dense ? 12.5 : 14,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList() ??
            []);

    final bool hasMatchingItem =
        dropdownItems.any((item) => item.value == value);
    final T? safeValue = hasMatchingItem ? value : null;

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
        DropdownButtonFormField<T>(
          initialValue: safeValue,
          dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.grey.shade400 : Colors.grey,
            size: dense ? 18 : 24,
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
            filled: true,
            fillColor: effectiveFillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
              borderSide: BorderSide(color: iconColor, width: 1.5),
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
          items: dropdownItems,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
