class NominaConcepto {
  final int id;
  final String codigo;
  final String nombre;
  final String tipo; // ingreso, deduccion
  final String categoria;
  final bool esAutomatico;
  final bool esPorcentual;
  final double? porcentaje;
  final bool esCotizableTss;
  final bool esGravableIsr;
  final bool activo;

  NominaConcepto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.categoria,
    this.esAutomatico = false,
    this.esPorcentual = false,
    this.porcentaje,
    this.esCotizableTss = false,
    this.esGravableIsr = false,
    this.activo = true,
  });

  factory NominaConcepto.fromJson(Map<String, dynamic> json) {
    return NominaConcepto(
      id: json['id'] as int? ?? 0,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'ingreso',
      categoria: json['categoria'] as String? ?? 'general',
      esAutomatico: json['es_automatico'] as bool? ?? false,
      esPorcentual: json['es_porcentual'] as bool? ?? false,
      porcentaje: json['porcentaje'] != null ? double.tryParse(json['porcentaje'].toString()) : null,
      esCotizableTss: json['es_cotizable_tss'] as bool? ?? false,
      esGravableIsr: json['es_gravable_isr'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
