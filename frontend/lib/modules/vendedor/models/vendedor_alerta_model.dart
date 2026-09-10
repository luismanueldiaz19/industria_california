class VendedorAlertaModel {
  final int id;
  final int ledhouseCxcId;
  final int? vendedorId;
  final String? tipo;
  final String? montoInformado;
  final String? nota;
  final String estadoAlerta;
  final DateTime createdAt;
  final AlertaCxcModel? cxc;
  final List<dynamic>? evidencias;

  VendedorAlertaModel({
    required this.id,
    required this.ledhouseCxcId,
    this.vendedorId,
    this.tipo,
    this.montoInformado,
    this.nota,
    required this.estadoAlerta,
    required this.createdAt,
    this.cxc,
    this.evidencias,
  });

  factory VendedorAlertaModel.fromJson(Map<String, dynamic> json) {
    return VendedorAlertaModel(
      id: json['id'] ?? 0,
      ledhouseCxcId: json['ledhouse_cxc_id'] ?? 0,
      vendedorId: json['vendedor_id'],
      tipo: json['tipo'],
      montoInformado: json['monto_informado']?.toString(),
      nota: json['nota'],
      estadoAlerta: json['estado_alerta'] ?? 'pendiente',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
      cxc: json['cxc'] != null ? AlertaCxcModel.fromJson(json['cxc']) : null,
      evidencias: json['evidencias'] as List?,
    );
  }
}

class AlertaCxcModel {
  final int id;
  final String documento;
  final AlertaClienteModel? cliente;
  final List<dynamic>? evidencias;

  AlertaCxcModel({
    required this.id,
    required this.documento,
    this.cliente,
    this.evidencias,
  });

  factory AlertaCxcModel.fromJson(Map<String, dynamic> json) {
    return AlertaCxcModel(
      id: json['id'] ?? 0,
      documento: json['documento'] ?? 'Doc Desconocido',
      cliente: json['cliente'] != null ? AlertaClienteModel.fromJson(json['cliente']) : null,
      evidencias: json['evidencias'] as List?,
    );
  }
}

class AlertaClienteModel {
  final int id;
  final String nombre;

  AlertaClienteModel({
    required this.id,
    required this.nombre,
  });

  factory AlertaClienteModel.fromJson(Map<String, dynamic> json) {
    return AlertaClienteModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Cliente Desconocido',
    );
  }
}
