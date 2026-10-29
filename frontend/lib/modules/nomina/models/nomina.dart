import '../../../../core/utils/formatters.dart';
import '../../empleado/models/empleado.dart';
import 'nomina_concepto.dart';

class Nomina {
  final int id;
  final String codigo;
  final String titulo;
  final String tipoPeriodo; // quincenal, mensual, extraordinaria
  final String fechaInicio;
  final String fechaFin;
  final String fechaPago;
  final String estado; // borrador, calculada, aprobada, pagada, anulada
  final double totalIngresos;
  final double totalDeducciones;
  final double totalNeto;
  final String? notas;
  final int? detallesCount;
  final List<NominaDetalle> detalles;

  String get fechaInicioFormatted => Formatters.formatDateStr(fechaInicio);
  String get fechaFinFormatted => Formatters.formatDateStr(fechaFin);
  String get fechaPagoFormatted => Formatters.formatDateStr(fechaPago);

  Nomina({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.tipoPeriodo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaPago,
    required this.estado,
    required this.totalIngresos,
    required this.totalDeducciones,
    required this.totalNeto,
    this.notas,
    this.detallesCount,
    this.detalles = const [],
  });

  factory Nomina.fromJson(Map<String, dynamic> json) {
    final detallesRaw = json['detalles'] as List? ?? [];
    return Nomina(
      id: json['id'] as int? ?? 0,
      codigo: json['codigo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      tipoPeriodo: json['tipo_periodo'] as String? ?? 'quincenal',
      fechaInicio: json['fecha_inicio'] as String? ?? '',
      fechaFin: json['fecha_fin'] as String? ?? '',
      fechaPago: json['fecha_pago'] as String? ?? '',
      estado: json['estado'] as String? ?? 'borrador',
      totalIngresos: _toDouble(json['total_ingresos']),
      totalDeducciones: _toDouble(json['total_deducciones']),
      totalNeto: _toDouble(json['total_neto']),
      notas: json['notas'] as String?,
      detallesCount: json['detalles_count'] as int?,
      detalles: detallesRaw.map((d) => NominaDetalle.fromJson(d)).toList(),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}

class NominaDetalle {
  final int id;
  final int nominaId;
  final int empleadoId;
  final double salarioMensual;
  final double salarioPeriodo;
  final double salarioHora;
  final double diasTrabajados;
  final double horasTrabajadas;
  final double horasNoLaboradas;
  final double horasExtras;
  final double totalIngresos;
  final double totalDeducciones;
  final double netoPagar;
  final String? comentarios;
  final Empleado? empleado;
  final List<NominaDetalleConcepto> conceptos;

  NominaDetalle({
    required this.id,
    required this.nominaId,
    required this.empleadoId,
    required this.salarioMensual,
    required this.salarioPeriodo,
    required this.salarioHora,
    this.diasTrabajados = 15,
    this.horasTrabajadas = 120,
    this.horasNoLaboradas = 0,
    this.horasExtras = 0,
    required this.totalIngresos,
    required this.totalDeducciones,
    required this.netoPagar,
    this.comentarios,
    this.empleado,
    this.conceptos = const [],
  });

  factory NominaDetalle.fromJson(Map<String, dynamic> json) {
    final conceptosRaw = json['conceptos'] as List? ?? [];
    return NominaDetalle(
      id: json['id'] as int? ?? 0,
      nominaId: json['nomina_id'] as int? ?? 0,
      empleadoId: json['empleado_id'] as int? ?? 0,
      salarioMensual: Nomina._toDouble(json['salario_mensual']),
      salarioPeriodo: Nomina._toDouble(json['salario_periodo']),
      salarioHora: Nomina._toDouble(json['salario_hora']),
      diasTrabajados: Nomina._toDouble(json['dias_trabajados']),
      horasTrabajadas: Nomina._toDouble(json['horas_trabajadas']),
      horasNoLaboradas: Nomina._toDouble(json['horas_no_laboradas']),
      horasExtras: Nomina._toDouble(json['horas_extras']),
      totalIngresos: Nomina._toDouble(json['total_ingresos']),
      totalDeducciones: Nomina._toDouble(json['total_deducciones']),
      netoPagar: Nomina._toDouble(json['neto_pagar']),
      comentarios: json['comentarios'] as String?,
      empleado: json['empleado'] != null ? Empleado.fromJson(json['empleado']) : null,
      conceptos: conceptosRaw.map((c) => NominaDetalleConcepto.fromJson(c)).toList(),
    );
  }
}

class NominaDetalleConcepto {
  final int id;
  final int nominaDetalleId;
  final int conceptoId;
  final String tipo; // ingreso, deduccion
  final double monto;
  final double? cantidad;
  final double? valorUnitario;
  final String? referenciaCuota;
  final String? notas;
  final NominaConcepto? concepto;

  NominaDetalleConcepto({
    required this.id,
    required this.nominaDetalleId,
    required this.conceptoId,
    required this.tipo,
    required this.monto,
    this.cantidad,
    this.valorUnitario,
    this.referenciaCuota,
    this.notas,
    this.concepto,
  });

  factory NominaDetalleConcepto.fromJson(Map<String, dynamic> json) {
    return NominaDetalleConcepto(
      id: json['id'] as int? ?? 0,
      nominaDetalleId: json['nomina_detalle_id'] as int? ?? 0,
      conceptoId: json['concepto_id'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? 'ingreso',
      monto: Nomina._toDouble(json['monto']),
      cantidad: json['cantidad'] != null ? Nomina._toDouble(json['cantidad']) : null,
      valorUnitario: json['valor_unitario'] != null ? Nomina._toDouble(json['valor_unitario']) : null,
      referenciaCuota: json['referencia_cuota'] as String?,
      notas: json['notas'] as String?,
      concepto: json['concepto'] != null ? NominaConcepto.fromJson(json['concepto']) : null,
    );
  }
}
