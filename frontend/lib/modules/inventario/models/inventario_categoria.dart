class InventarioCategoria {
  final int? id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  const InventarioCategoria({
    this.id,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });

  factory InventarioCategoria.fromJson(Map<String, dynamic> json) {
    return InventarioCategoria(
      id: json['id'] as int?,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] == true || json['activo'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'activo': activo,
    };
  }
}
