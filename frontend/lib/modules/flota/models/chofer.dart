class Chofer {
  final int id;
  final int userId;
  final String? numeroLicencia;
  final String? tipoLicencia;
  final String estado; // activo, inactivo, vacaciones
  final String? name; // Del user
  final String? email; // Del user
  final String? username; // Del user
  final String? vencimientoLicencia;
  final String? contactoEmergencia;

  Chofer({
    required this.id,
    required this.userId,
    this.numeroLicencia,
    this.tipoLicencia,
    required this.estado,
    this.name,
    this.email,
    this.username,
    this.vencimientoLicencia,
    this.contactoEmergencia,
  });

  factory Chofer.fromJson(Map<String, dynamic> json) {
    return Chofer(
      id: json['id'],
      userId: json['user_id'],
      numeroLicencia: json['numero_licencia'],
      tipoLicencia: json['tipo_licencia'],
      estado: json['estado'] ?? 'activo',
      name: json['user']?['name'],
      email: json['user']?['email'],
      username: json['user']?['username'],
      vencimientoLicencia: json['vencimiento_licencia'],
      contactoEmergencia: json['contacto_emergencia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'numero_licencia': numeroLicencia,
      'tipo_licencia': tipoLicencia,
      'estado': estado,
      'name': name,
      'email': email,
      'username': username,
      'vencimiento_licencia': vencimientoLicencia,
      'contacto_emergencia': contactoEmergencia,
    };
  }
}
