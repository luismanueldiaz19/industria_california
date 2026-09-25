class TipoGasto {
  final int id;
  final String nombre;

  TipoGasto({required this.id, required this.nombre});

  factory TipoGasto.fromJson(Map<String, dynamic> json) {
    return TipoGasto(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}
