import 'package:intl/intl.dart';

class Formatters {
  /// Formateador de moneda (Ej: $1,234.56)
  static final NumberFormat currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Formatea la fecha en formato largo en español (Ej: 17 sept 2026, 13:45)
  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'es').format(date);
  }

  /// Formatea la fecha en formato corto (Ej: 17/09/2026)
  static String dateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }
}
