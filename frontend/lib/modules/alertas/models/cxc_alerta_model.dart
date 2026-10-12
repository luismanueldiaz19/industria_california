import 'dart:convert';

class CxcAlertaModel {
  final int id;
  final String tipo;
  final String estadoAlerta;
  final String? nota;
  final double? montoInformado;
  final String? fechaRevision;
  final String? createdAt;
  final UserModel? vendedor;
  final UserModel? revisador;
  final CxcModel? cxc;
  final List<EvidenciaModel> evidencias;

  CxcAlertaModel({
    required this.id,
    required this.tipo,
    required this.estadoAlerta,
    this.nota,
    this.montoInformado,
    this.fechaRevision,
    this.createdAt,
    this.vendedor,
    this.revisador,
    this.cxc,
    this.evidencias = const [],
  });

  factory CxcAlertaModel.fromJson(Map<String, dynamic> json) {
    return CxcAlertaModel(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? 'informacion',
      estadoAlerta: json['estado_alerta'] ?? 'pendiente',
      nota: json['nota'],
      montoInformado: json['monto_informado'] != null
          ? double.tryParse(json['monto_informado'].toString())
          : null,
      fechaRevision: json['fecha_revision'],
      createdAt: json['created_at'],
      vendedor: json['vendedor'] != null
          ? UserModel.fromJson(json['vendedor'])
          : null,
      revisador: json['revisador'] != null
          ? UserModel.fromJson(json['revisador'])
          : null,
      cxc: json['cxc'] != null ? CxcModel.fromJson(json['cxc']) : null,
      evidencias:
          (json['evidencias'] as List?)
              ?.map((e) => EvidenciaModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
    "id": id,
    "tipo": tipo,
    "estado_alerta": estadoAlerta,
    "nota": nota,
    "monto_informado": montoInformado,
    "fecha_revision": fechaRevision,
    "created_at": createdAt,
    "vendedor": vendedor?.toRawJson(),
    "revisador": revisador?.toRawJson(),
    "cxc": cxc?.toRawJson(),
    "evidencias": List<dynamic>.from(evidencias.map((x) => x.toRawJson())),
  };
}

class UserModel {
  final int id;
  final String name;
  final String username;

  UserModel({required this.id, required this.name, required this.username});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
    );
  }

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "username": username,
  };
}

class CxcModel {
  final int id;
  final String noFactura;
  final String? idClienteExterno;
  final double totalFactura;
  final double montoPendiente;
  final ClienteModel? cliente;
  final List<EvidenciaModel> evidencias;

  CxcModel({
    required this.id,
    required this.noFactura,
    this.idClienteExterno,
    required this.totalFactura,
    required this.montoPendiente,
    this.cliente,
    this.evidencias = const [],
  });

  factory CxcModel.fromJson(Map<String, dynamic> json) {
    return CxcModel(
      id: json['id'] ?? 0,
      noFactura: json['no_factura'] ?? json['documento'] ?? '',
      idClienteExterno: json['id_cliente_externo'],
      totalFactura:
          double.tryParse(
            json['total_factura']?.toString() ??
                json['monto_factura']?.toString() ??
                '0',
          ) ??
          0.0,
      montoPendiente:
          double.tryParse(json['monto_pendiente']?.toString() ?? '0') ?? 0.0,
      cliente: json['cliente'] != null
          ? ClienteModel.fromJson(json['cliente'])
          : null,
      evidencias:
          (json['evidencias'] as List?)
              ?.map((e) => EvidenciaModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
    "id": id,
    "no_factura": noFactura,
    "id_cliente_externo": idClienteExterno,
    "total_factura": totalFactura,
    "monto_pendiente": montoPendiente,
    "cliente": cliente?.toJson(),
    "evidencias": List<dynamic>.from(evidencias.map((x) => x.toJson())),
  };
}

class ClienteModel {
  final int id;
  final String nombre;

  ClienteModel({required this.id, required this.nombre});

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'] ?? 0,
      nombre: json['nombre_cliente'] ?? json['nombre'] ?? '',
    );
  }

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {"id": id, "nombre_cliente": nombre};
}

class EvidenciaModel {
  final int id;
  final String nombreArchivo;
  final String rutaArchivo;
  final String tipoArchivo;

  EvidenciaModel({
    required this.id,
    required this.nombreArchivo,
    required this.rutaArchivo,
    required this.tipoArchivo,
  });

  factory EvidenciaModel.fromJson(Map<String, dynamic> json) {
    return EvidenciaModel(
      id: json['id'] ?? 0,
      nombreArchivo: json['nombre_archivo'] ?? '',
      rutaArchivo: json['ruta_archivo'] ?? '',
      tipoArchivo: json['tipo_archivo'] ?? '',
    );
  }

  bool get isImage =>
      ['jpg', 'jpeg', 'png'].contains(tipoArchivo.toLowerCase());

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
    "id": id,
    "nombre_archivo": nombreArchivo,
    "ruta_archivo": rutaArchivo,
    "tipo_archivo": tipoArchivo,
  };
}
