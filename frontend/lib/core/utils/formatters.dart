import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  /// Formateador de moneda (Ej: $1,234.56)
  static final NumberFormat currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Helper para formatear cualquier valor a moneda
  static String formatCurrency(dynamic value) {
    if (value == null) return currency.format(0);
    if (value is num) return currency.format(value);
    if (value is String) return currency.format(double.tryParse(value) ?? 0);
    return currency.format(0);
  }

  /// Formatea la fecha en formato largo en español (Ej: 17 sept 2026, 13:45)
  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'es').format(date);
  }

  /// Formatea la fecha en formato corto (Ej: 17/09/2026)
  static String dateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }

  /// Formatea una fecha en string ISO (yyyy-MM-dd o yyyy-MM-ddTHH:mm:ss) a formato estándar dominicano (dd/MM/yyyy)
  static String formatDateStr(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    // Extraer parte de fecha si viene en ISO con hora o timezone (ej: 2026-10-16T00:00:00.000000Z)
    final datePart = raw.contains('T') ? raw.split('T').first : raw.trim();
    final parts = datePart.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      // yyyy-MM-dd -> dd/MM/yyyy directo sin riesgo de desfase por zona horaria UTC
      return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return dateShort(parsed);
  }

  /// Formatea la cédula dominicana al estándar oficial (Ej: xxx-xxxxxxx-x)
  static String formatCedula(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 10)}-${digits.substring(10)}';
    }
    if (digits.length > 3 && digits.length <= 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    if (digits.length > 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 10)}-${digits.substring(10, 11)}';
    }
    return digits;
  }
}

/// Formateador de entrada en tiempo real para Cédula Dominicana (xxx-xxxxxxx-x)
class CedulaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Si el usuario borró un guión directamente hacia atrás, borrar el dígito anterior
    if (oldValue.text.length > newValue.text.length &&
        oldValue.text.endsWith('-') &&
        digits.length == oldValue.text.replaceAll(RegExp(r'\D'), '').length &&
        digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
    }

    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 10) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
