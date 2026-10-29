class Empleado {
  final int id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String? ocupacion;
  final String? departamento;
  final String? telefono;
  final String? email;
  final String? direccion;
  final double salarioMensual;
  final double salarioQuincenal;
  final double salarioHora;
  final bool aplicaAfp;
  final bool aplicaArs;
  final bool aplicaIsr;
  final String tipoPago;
  final String? banco;
  final String? numeroCuenta;
  final String estado; // activo, inactivo, vacaciones, licencia
  final String? fechaIngreso;
  final String? fechaSalida;

  Empleado({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    this.ocupacion,
    this.departamento,
    this.telefono,
    this.email,
    this.direccion,
    required this.salarioMensual,
    required this.salarioQuincenal,
    required this.salarioHora,
    this.aplicaAfp = true,
    this.aplicaArs = true,
    this.aplicaIsr = true,
    this.tipoPago = 'transferencia',
    this.banco,
    this.numeroCuenta,
    this.estado = 'activo',
    this.fechaIngreso,
    this.fechaSalida,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] as int? ?? 0,
      cedula: json['cedula'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      ocupacion: json['ocupacion'] as String?,
      departamento: json['departamento'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      salarioMensual: _toDouble(json['salario_mensual']),
      salarioQuincenal: _toDouble(json['salario_quincenal']),
      salarioHora: _toDouble(json['salario_hora']),
      aplicaAfp: json['aplica_afp'] as bool? ?? true,
      aplicaArs: json['aplica_ars'] as bool? ?? true,
      aplicaIsr: json['aplica_isr'] as bool? ?? true,
      tipoPago: json['tipo_pago'] as String? ?? 'transferencia',
      banco: json['banco'] as String?,
      numeroCuenta: json['numero_cuenta'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      fechaIngreso: json['fecha_ingreso'] as String?,
      fechaSalida: json['fecha_salida'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'ocupacion': ocupacion,
      'departamento': departamento,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'salario_mensual': salarioMensual,
      'aplica_afp': aplicaAfp,
      'aplica_ars': aplicaArs,
      'aplica_isr': aplicaIsr,
      'tipo_pago': tipoPago,
      'banco': banco,
      'numero_cuenta': numeroCuenta,
      'estado': estado,
      if (fechaIngreso != null) 'fecha_ingreso': fechaIngreso,
      if (fechaSalida != null) 'fecha_salida': fechaSalida,
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
