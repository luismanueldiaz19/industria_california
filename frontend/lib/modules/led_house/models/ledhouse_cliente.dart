class LedhouseCliente {
  final int? id;
  final String? idClienteExterno;
  final String nombre;
  final String? whatsapp;
  final String? direccion;
  final String? tipoDocumento;
  final String? documento;
  final double? limiteCredito;
  final int? diasCredito;
  final double? latitud;
  final double? longitud;

  LedhouseCliente({
    this.id,
    this.idClienteExterno,
    required this.nombre,
    this.whatsapp,
    this.direccion,
    this.tipoDocumento,
    this.documento,
    this.limiteCredito,
    this.diasCredito,
    this.latitud,
    this.longitud,
  });

  factory LedhouseCliente.fromJson(Map<String, dynamic> json) {
    return LedhouseCliente(
      id: json['id'] as int?,
      idClienteExterno: json['id_cliente_externo'] as String?,
      nombre: (json['nombre'] as String?) ?? '',
      whatsapp: json['whatsapp'] as String?,
      direccion: json['direccion'] as String?,
      tipoDocumento: json['tipo_documento'] as String?,
      documento: json['documento'] as String?,
      limiteCredito: json['limite_credito'] != null
          ? double.tryParse(json['limite_credito'].toString())
          : null,
      diasCredito: json['dias_credito'] as int?,
      latitud: json['latitud'] != null
          ? double.tryParse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.tryParse(json['longitud'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_cliente_externo': idClienteExterno,
      'nombre': nombre,
      'whatsapp': whatsapp,
      'direccion': direccion,
      'tipo_documento': tipoDocumento,
      'documento': documento,
      'limite_credito': limiteCredito,
      'dias_credito': diasCredito,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    };
  }
}
