import 'package:flutter/material.dart';
import 'package:industria_california/core/themes/app_theme.dart';

class AppDatePicker {
  /// Muestra un selector de rango de fechas con el diseño limpio y moderno
  /// con los extremos redondeados y un resaltado suave en el medio.
  static Future<DateTimeRange?> showRangePicker({
    required BuildContext context,
    DateTimeRange? initialDateRange,
    DateTime? firstDate,
    DateTime? lastDate,
    Widget Function(BuildContext context, Widget? child)? builder,
  }) async {
    return await showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Sobreescribimos cualquier tema local o global rebelde
            colorScheme: ColorScheme.light(
              primary:
                  AppTheme.primaryBlue, // El color de los círculos (inicio/fin)
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: AppTheme.primaryBlue,
              headerForegroundColor: Colors.white,
              // El color de fondo del rango intermedio (transparente y suave)
              rangeSelectionBackgroundColor: AppTheme.primaryBlue.withValues(
                alpha: 0.1,
              ),
              rangePickerBackgroundColor: Colors.white,
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return null;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
            ),
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            insetPadding: const EdgeInsets.all(16.0),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400.0,
                maxHeight: 500.0,
              ),
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
