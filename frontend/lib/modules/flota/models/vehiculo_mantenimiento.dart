class VehiculoMantenimiento {
  final int id;
  final int vehiculoId;
  final String tipo;
  final DateTime? fechaReporte;
  final String descripcion;
  final double costo;
  final String estado;
  final List<String>? evidencias;
  final int? reportadoPor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Relations
  final String? vehiculoFicha;
  final String? vehiculoPlaca;
  final String? reportadorNombre;

  VehiculoMantenimiento({
    required this.id,
    required this.vehiculoId,
    required this.tipo,
    this.fechaReporte,
    required this.descripcion,
    required this.costo,
    required this.estado,
    this.evidencias,
    this.reportadoPor,
    this.createdAt,
    this.updatedAt,
    this.vehiculoFicha,
    this.vehiculoPlaca,
    this.reportadorNombre,
  });

  factory VehiculoMantenimiento.fromJson(Map<String, dynamic> json) {
    return VehiculoMantenimiento(
      id: json['id'],
      vehiculoId: json['vehiculo_id'],
      tipo: json['tipo'] ?? 'preventivo',
      fechaReporte: json['fecha_reporte'] != null ? DateTime.parse(json['fecha_reporte']) : null,
      descripcion: json['descripcion'] ?? '',
      costo: json['costo'] != null ? double.tryParse(json['costo'].toString()) ?? 0.0 : 0.0,
      estado: json['estado'] ?? 'pendiente',
      evidencias: json['evidencias'] != null ? List<String>.from(json['evidencias']) : null,
      reportadoPor: json['reportado_por'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      vehiculoFicha: json['vehiculo'] != null ? json['vehiculo']['ficha'] : null,
      vehiculoPlaca: json['vehiculo'] != null ? json['vehiculo']['placa'] : null,
      reportadorNombre: json['reportador'] != null ? json['reportador']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'fecha_reporte': fechaReporte?.toIso8601String(),
      'descripcion': descripcion,
      'costo': costo,
      'estado': estado,
      'evidencias': evidencias,
    };
  }
}