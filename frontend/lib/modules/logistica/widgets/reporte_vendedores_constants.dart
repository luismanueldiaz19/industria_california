// Colores compartidos del módulo de reporte de vendedores.
import 'package:flutter/material.dart';

const kVendorPalette = [
  Color(0xFFE31E24),
  Color(0xFF3B82F6),
  Color(0xFF16A34A),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
];

const kColorBorrador  = Color(0xFF64748B);
const kColorEnviado   = Color(0xFF3B82F6);
const kColorFacturado = Color(0xFF16A34A);
const kColorCancelado = Color(0xFFDC2626);
const kColorAccent    = Color(0xFFE31E24);
const kColorSurface   = Color(0xFF2C2F33);
const kColorBg        = Color(0xFF1A1C1E);

Color colorPorVendedor(int index) =>
    kVendorPalette[index % kVendorPalette.length];

String mesAbreviado(int mes) {
  const nombres = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  return (mes >= 1 && mes <= 12) ? nombres[mes - 1] : mes.toString();
}
