import 'package:flutter/material.dart';
import 'package:industria_california/core/themes/app_theme.dart';

class AppDatePickerDark {
  static const _darkBg = Color(0xFF1A1C1E);
  static const _cardColor = Color(0xFF2C2F33);

  /// Muestra un selector de rango de fechas con diseño oscuro.
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
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: _cardColor,
              onSurface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _darkBg,
              headerBackgroundColor: AppTheme.primaryBlue,
              headerForegroundColor: Colors.white,
              rangeSelectionBackgroundColor: AppTheme.primaryBlue.withValues(
                alpha: 0.2,
              ),
              rangePickerBackgroundColor: _darkBg,
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
                if (states.contains(WidgetState.disabled)) {
                  return Colors.white30;
                }
                return Colors.white70;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppTheme.primaryBlue;
              }),
            ),
          ),
          child: Dialog(
            backgroundColor: _darkBg,
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
