import '../../empleado/models/empleado.dart';
import 'nomina_concepto.dart';

class NominaEmpleadoRecurrente {
  final int id;
  final int empleadoId;
  final int conceptoId;
  final String descripcion;
  final double montoTotal;
  final double montoCuota;
  final int cuotasTotales;
  final int cuotasPagadas;
  final double saldoRestante;
  final bool activo;
  final Empleado? empleado;
  final NominaConcepto? concepto;

  NominaEmpleadoRecurrente({
    required this.id,
    required this.empleadoId,
    required this.conceptoId,
    required this.descripcion,
    required this.montoTotal,
    required this.montoCuota,
    required this.cuotasTotales,
    required this.cuotasPagadas,
    required this.saldoRestante,
    this.activo = true,
    this.empleado,
    this.concepto,
  });

  String get referenciaCuota => '$cuotasPagadas/$cuotasTotales';

  factory NominaEmpleadoRecurrente.fromJson(Map<String, dynamic> json) {
    return NominaEmpleadoRecurrente(
      id: json['id'] as int? ?? 0,
      empleadoId: json['empleado_id'] as int? ?? 0,
      conceptoId: json['concepto_id'] as int? ?? 0,
      descripcion: json['descripcion'] as String? ?? '',
      montoTotal: _toDouble(json['monto_total']),
      montoCuota: _toDouble(json['monto_cuota']),
      cuotasTotales: json['cuotas_totales'] as int? ?? 1,
      cuotasPagadas: json['cuotas_pagadas'] as int? ?? 0,
      saldoRestante: _toDouble(json['saldo_restante']),
      activo: json['activo'] as bool? ?? true,
      empleado: json['empleado'] != null ? Empleado.fromJson(json['empleado']) : null,
      concepto: json['concepto'] != null ? NominaConcepto.fromJson(json['concepto']) : null,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
