class Vehiculo {
  final int id;
  final String ficha;
  final String? placa;
  final String? marca;
  final String? modelo;
  final int? anio;
  final String tipoEnergia;
  final double? capacidadCarga;
  final String estado;

  Vehiculo({
    required this.id,
    required this.ficha,
    this.placa,
    this.marca,
    this.modelo,
    this.anio,
    required this.tipoEnergia,
    this.capacidadCarga,
    required this.estado,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      ficha: json['ficha'] ?? '',
      placa: json['placa'],
      marca: json['marca'],
      modelo: json['modelo'],
      anio: json['anio'],
      tipoEnergia: json['tipo_energia'] ?? 'diesel',
      capacidadCarga: json['capacidad_carga'] != null 
          ? double.tryParse(json['capacidad_carga'].toString()) 
          : null,
      estado: json['estado'] ?? 'disponible',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ficha': ficha,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'tipo_energia': tipoEnergia,
      'capacidad_carga': capacidadCarga,
      'estado': estado,
    };
  }
}