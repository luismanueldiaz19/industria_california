class Ruta {
  final int id;
  final String nombre;
  final String? chofer;
  final String? fichaCamion;
  final int createdBy;

  Ruta({
    required this.id,
    required this.nombre,
    this.chofer,
    this.fichaCamion,
    required this.createdBy,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      id: json['id'],
      nombre: json['nombre'],
      chofer: json['chofer'],
      fichaCamion: json['ficha_camion'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'chofer': chofer,
      'ficha_camion': fichaCamion,
      'created_by': createdBy,
    };
  }
}
