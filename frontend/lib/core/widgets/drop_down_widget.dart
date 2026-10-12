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
  }) : assert(
         items != null || customItems != null,
         'Debe proporcionar items o customItems',
       );

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList() ??
            []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Opcional',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: icon != null
                ? Container(
                    margin: const EdgeInsets.all(10),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEA4335),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: dropdownItems,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
