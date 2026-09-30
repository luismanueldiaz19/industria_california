import 'package:flutter/material.dart';

class PedidoUtils {
  static Color getColorForEstado(String estado) {
    switch (estado) {
      case 'borrador':
        return const Color(0xFFFF9800);
      case 'enviado':
        return const Color(0xFF2196F3);
      case 'facturado':
        return const Color(0xFF4CAF50);
      case 'cancelado':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }
}
