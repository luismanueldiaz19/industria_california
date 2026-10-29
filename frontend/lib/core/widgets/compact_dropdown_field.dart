import 'package:flutter/material.dart';

/// Dropdown compacto con bordes definidos, fondo blanco nítido y floating label,
/// estandarizado para modales y formularios desktop/web.
class CompactDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T>? items;
  final List<DropdownMenuItem<T>>? customItems;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;
  final Color fillColor;
  final Color borderColor;
  final Color focusedBorderColor;

  const CompactDropdownField({
    super.key,
    required this.label,
    required this.value,
    this.items,
    this.customItems,
    this.itemLabel,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.fillColor = Colors.white,
    this.borderColor = const Color(0xFFCBD5E1),
    this.focusedBorderColor = const Color(0xFF2563EB),
  }) : assert(items != null || customItems != null, 'Debe proporcionar items o customItems');

  @override
  Widget build(BuildContext context) {
    final dropdownItems = customItems ??
        (items?.map((item) {
          final text = itemLabel != null ? itemLabel!(item) : item.toString().toUpperCase();
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          );
        }).toList() ??
            []);

    final bool hasMatchingItem = dropdownItems.any((item) => item.value == value);
    final T? safeValue = hasMatchingItem ? value : null;

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      items: dropdownItems,
      onChanged: onChanged,
      validator: validator ??
          (isRequired
              ? (v) => v == null ? 'Campo requerido' : null
              : null),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0F172A),
      ),
      icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
      decoration: InputDecoration(
        label: isRequired
            ? RichText(
                text: TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
      ),
    );
  }
}

