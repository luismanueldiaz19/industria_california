class VehiculoGasto {
  final int id;
  final int? vehiculoId;
  final int? viajeId;
  final String? tipoGasto;
  final DateTime? fechaGasto;
  final String concepto;
  final double cantidad;
  final String? unidadMedida;
  final double precioUnitario;
  final double montoTotal;
  final String? comprobante;
  final List<dynamic>? comprobantes;
  final Map<String, dynamic>? registrador;
  final Map<String, dynamic>? vehiculo;
  final Map<String, dynamic>? viaje;

  VehiculoGasto({
    required this.id,
    this.vehiculoId,
    this.viajeId,
    this.tipoGasto,
    this.fechaGasto,
    required this.concepto,
    required this.cantidad,
    this.unidadMedida,
    required this.precioUnitario,
    required this.montoTotal,
    this.comprobante,
    this.comprobantes,
    this.registrador,
    this.vehiculo,
    this.viaje,
  });

  factory VehiculoGasto.fromJson(Map<String, dynamic> json) {
    List<dynamic>? compList;
    if (json['comprobantes'] is List) {
      compList = json['comprobantes'];
    } else if (json['comprobantes'] is String && (json['comprobantes'] as String).isNotEmpty) {
      compList = [json['comprobantes']];
    }

    String? singleComp = json['comprobante']?.toString();
    if ((singleComp == null || singleComp.isEmpty) && compList != null && compList.isNotEmpty) {
      singleComp = compList.first.toString();
    }

    return VehiculoGasto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      vehiculoId: json['vehiculo_id'] != null
          ? int.tryParse(json['vehiculo_id'].toString())
          : null,
      viajeId: json['viaje_id'] != null
          ? int.tryParse(json['viaje_id'].toString())
          : null,
      tipoGasto: json['tipo_gasto'],
      fechaGasto: json['fecha_gasto'] != null
          ? DateTime.tryParse(json['fecha_gasto'].toString())
          : null,
      concepto: json['concepto'] ?? '',
      cantidad: json['cantidad'] != null
          ? double.tryParse(json['cantidad'].toString()) ?? 0.0
          : 0.0,
      unidadMedida: json['unidad_medida'],
      precioUnitario: json['precio_unitario'] != null
          ? double.tryParse(json['precio_unitario'].toString()) ?? 0.0
          : 0.0,
      montoTotal: json['monto_total'] != null
          ? double.tryParse(json['monto_total'].toString()) ?? 0.0
          : 0.0,
      comprobante: singleComp,
      comprobantes: compList,
      registrador: json['registrador'] is Map<String, dynamic> ? json['registrador'] : null,
      vehiculo: json['vehiculo'],
      viaje: json['viaje'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_gasto': tipoGasto,
      'concepto': concepto,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
      'precio_unitario': precioUnitario,
      'comprobante': comprobante,
      'comprobantes': comprobantes,
    };
  }
}

