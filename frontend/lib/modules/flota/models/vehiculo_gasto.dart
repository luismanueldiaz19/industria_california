class VehiculoGasto {
  final int id;
  final int vehiculoId;
  final String? tipoGasto;
  final DateTime? fechaGasto;
  final String concepto;
  final double cantidad;
  final String? unidadMedida;
  final double precioUnitario;
  final double montoTotal;
  final Map<String, dynamic>? vehiculo;

  VehiculoGasto({
    required this.id,
    required this.vehiculoId,
    this.tipoGasto,
    this.fechaGasto,
    required this.concepto,
    required this.cantidad,
    this.unidadMedida,
    required this.precioUnitario,
    required this.montoTotal,
    this.vehiculo,
  });

  factory VehiculoGasto.fromJson(Map<String, dynamic> json) {
    return VehiculoGasto(
      id: json['id'],
      vehiculoId: json['vehiculo_id'],
      tipoGasto: json['tipo_gasto'],
      fechaGasto: json['fecha_gasto'] != null
          ? DateTime.parse(json['fecha_gasto'])
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
      vehiculo: json['vehiculo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_gasto': tipoGasto,
      'concepto': concepto,
      'cantidad': cantidad,
      'unidad_medida': unidadMedida,
      'precio_unitario': precioUnitario,
    };
  }
}

