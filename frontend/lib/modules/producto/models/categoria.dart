import '../../../core/network/net_work.dart';

class Categoria {
  final int? id;
  final String nombre;
  final String? imagenPath;
  final String? imagenUrl;

  const Categoria({
    this.id,
    required this.nombre,
    this.imagenPath,
    this.imagenUrl,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    String? url = json['imagen_url'] as String?;
    if (url != null && url.startsWith('/')) {
      url = '$host$url';
    }

    return Categoria(
      id: json['id'] as int?,
      nombre: (json['nombre'] as String?) ?? '',
      imagenPath: json['imagen_path'] as String?,
      imagenUrl: url,
    );
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'nombre': nombre};
  }
}
