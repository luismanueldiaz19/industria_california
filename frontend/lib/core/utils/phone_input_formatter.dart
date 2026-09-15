import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo números
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limitar a 10 dígitos
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    String formatted = '';

    if (digits.isNotEmpty) {
      formatted += digits.substring(0, digits.length >= 3 ? 3 : digits.length);
    }

    if (digits.length >= 4) {
      formatted +=
          '-${digits.substring(3, digits.length >= 6 ? 6 : digits.length)}';
    }

    if (digits.length >= 7) {
      formatted += '-${digits.substring(6)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
