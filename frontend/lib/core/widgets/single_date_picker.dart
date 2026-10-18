import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../themes/app_theme.dart';

class SingleDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? hint;
  final IconData? icon;
  final Color iconColor;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool optional;
  final bool isDark;
  final bool dense;
  final bool allowClear;
  final DateFormat? dateFormat;
  final String? Function(DateTime?)? validator;
  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final Color? pickerColor;
  final bool enabled;

  const SingleDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Seleccionar fecha',
    this.icon = Icons.calendar_today_rounded,
    this.iconColor = AppTheme.successColor,
    this.firstDate,
    this.lastDate,
    this.optional = false,
    this.isDark = false,
    this.dense = false,
    this.allowClear = true,
    this.dateFormat,
    this.validator,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.labelStyle,
    this.textStyle,
    this.pickerColor,
    this.enabled = true,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    final initial = value ?? now;

    final effectiveInitial = initial.isBefore(first)
        ? first
        : (initial.isAfter(last) ? last : initial);

    final activeColor = pickerColor ?? const Color(0xFFE31E24);

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        if (!isDark) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: activeColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: const Color(0xFF1F2937),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: activeColor,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            child: child!,
          );
        }
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: activeColor,
              onPrimary: Colors.white,
              surface: AppTheme.darkCardColor,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.darkCardColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: activeColor,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (validator != null) {
      return FormField<DateTime?>(
        initialValue: value,
        validator: validator,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPicker(context, hasError: state.hasError),
              if (state.hasError) ...[
                const SizedBox(height: 4),
                Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    color: Color(0xFFEA4335),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          );
        },
      );
    }

    return _buildPicker(context);
  }

  Widget _buildPicker(BuildContext context, {bool hasError = false}) {
    final effectiveLabelColor = labelStyle?.color ??
        (isDark ? Colors.grey.shade300 : const Color(0xFF374151));
    final effectiveTextColor = textStyle?.color ??
        (isDark ? Colors.white : const Color(0xFF1F2937));
    final effectiveFillColor = fillColor ??
        (isDark ? AppTheme.darkInputColor : const Color(0xFFF9FAFB));
    final effectiveBorderColor = hasError
        ? const Color(0xFFEA4335)
        : (borderColor ??
            (isDark ? AppTheme.darkBorderColor : Colors.grey.shade200));
    final effectiveRadius = borderRadius ?? (dense ? 8.0 : 14.0);
    final effectivePadding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);

    final fmt = dateFormat ?? DateFormat('dd/MM/yyyy');
    final formattedDate = value != null ? fmt.format(value!) : null;

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
        InkWell(
          onTap: enabled ? () => _pickDate(context) : null,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Container(
            padding: effectivePadding,
            decoration: BoxDecoration(
              color: enabled
                  ? effectiveFillColor
                  : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: Border.all(
                color: effectiveBorderColor,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    margin: EdgeInsets.only(right: dense ? 8 : 10),
                    width: dense ? 28 : 36,
                    height: dense ? 28 : 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(dense ? 8 : 10),
                    ),
                    child: Icon(icon, color: iconColor, size: dense ? 15 : 18),
                  ),
                ],
                Expanded(
                  child: Text(
                    formattedDate ?? (hint ?? 'Seleccionar fecha'),
                    style: TextStyle(
                      fontSize: dense ? 12.5 : 14,
                      color: formattedDate != null
                          ? effectiveTextColor
                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    ),
                  ),
                ),
                if (!enabled)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: dense ? 15 : 17,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  )
                else if (allowClear && value != null)
                  InkWell(
                    onTap: () => onChanged(null),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: dense ? 16 : 18,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.calendar_month_outlined,
                    size: dense ? 16 : 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
