import 'package:flutter/material.dart';

class PedidoUtils {
  static const List<String> estadosDisponibles = [
    'borrador',
    'cotizacion',
    'enviado',
    'facturado',
    'cancelado',
  ];

  static Color getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'borrador':
        return const Color(0xFFFF9800);
      case 'cotizacion':
        return const Color(0xFF9C27B0);
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

  static Color getEstadoColor(String estado) => getColorForEstado(estado);
}
