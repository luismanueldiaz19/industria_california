class CxcCuarentenaModel {
  final int id;
  final int? cxcIdOriginal;
  final String documento;
  final int? clienteId;
  final String clienteNombre;
  final int? vendedorId;
  final String vendedorNombre;
  final String? fechaFactura;
  final String? fechaVencimiento;
  final double montoFactura;
  final double montoPagado;
  final double montoPendiente;
  final String tipoNota;
  final double montoNota;
  final String motivo;
  final String justificacion;
  final String estado;
  final String? numeroNotaExterna;
  final String? notaResolucion;
  final String? fechaResolucion;
  final Map<String, dynamic>? snapshot;
  final String? enviadoPorNombre;
  final String? resueltoPorNombre;
  final String? createdAt;

  CxcCuarentenaModel({
    required this.id,
    this.cxcIdOriginal,
    required this.documento,
    this.clienteId,
    required this.clienteNombre,
    this.vendedorId,
    required this.vendedorNombre,
    this.fechaFactura,
    this.fechaVencimiento,
    required this.montoFactura,
    required this.montoPagado,
    required this.montoPendiente,
    required this.tipoNota,
    required this.montoNota,
    required this.motivo,
    required this.justificacion,
    required this.estado,
    this.numeroNotaExterna,
    this.notaResolucion,
    this.fechaResolucion,
    this.snapshot,
    this.enviadoPorNombre,
    this.resueltoPorNombre,
    this.createdAt,
  });

  bool get isCredito => tipoNota.toLowerCase() == 'credito';
  bool get isPendiente => estado.toLowerCase() == 'pendiente';
  bool get isAplicada => estado.toLowerCase() == 'aplicada';
  bool get isAnulada => estado.toLowerCase() == 'anulada';

  String get motivoLabel {
    switch (motivo.toLowerCase()) {
      case 'devolucion':
        return 'Devolución';
      case 'descuento':
        return 'Descuento';
      case 'diferencia_precio':
        return 'Diferencia de precio';
      case 'error_facturacion':
        return 'Error de facturación';
      case 'otro':
      default:
        return 'Otro';
    }
  }

  factory CxcCuarentenaModel.fromJson(Map<String, dynamic> json) {
    String clientName = json['cliente_nombre'] ?? '';
    if (clientName.isEmpty && json['cliente'] is Map) {
      clientName = json['cliente']['nombre'] ?? '';
    }

    String vendName = json['vendedor_nombre'] ?? '';
    if (vendName.isEmpty && json['vendedor'] is Map) {
      vendName = json['vendedor']['name'] ?? '';
    }

    String? envName = json['nombre_enviado_por'];
    if (envName == null && json['enviado_por'] is Map) {
      envName = json['enviado_por']['name'];
    }

    String? resName = json['nombre_resuelto_por'];
    if (resName == null && json['resuelto_por'] is Map) {
      resName = json['resuelto_por']['name'];
    }

    return CxcCuarentenaModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      cxcIdOriginal: json['cxc_id_original'] != null
          ? int.tryParse(json['cxc_id_original'].toString())
          : null,
      documento: json['documento']?.toString() ?? '',
      clienteId: json['cliente_id'] != null
          ? int.tryParse(json['cliente_id'].toString())
          : null,
      clienteNombre: clientName.isEmpty ? 'Cliente sin nombre' : clientName,
      vendedorId: json['vendedor_id'] != null
          ? int.tryParse(json['vendedor_id'].toString())
          : null,
      vendedorNombre: vendName.isEmpty ? 'Sin vendedor' : vendName,
      fechaFactura: json['fecha_factura']?.toString(),
      fechaVencimiento: json['fecha_vencimiento']?.toString(),
      montoFactura:
          double.tryParse(json['monto_factura']?.toString() ?? '0') ?? 0.0,
      montoPagado:
          double.tryParse(json['monto_pagado']?.toString() ?? '0') ?? 0.0,
      montoPendiente:
          double.tryParse(json['monto_pendiente']?.toString() ?? '0') ?? 0.0,
      tipoNota: json['tipo_nota']?.toString() ?? 'credito',
      montoNota: double.tryParse(json['monto_nota']?.toString() ?? '0') ?? 0.0,
      motivo: json['motivo']?.toString() ?? 'otro',
      justificacion: json['justificacion']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      numeroNotaExterna: json['numero_nota_externa']?.toString(),
      notaResolucion: json['nota_resolucion']?.toString(),
      fechaResolucion: json['fecha_resolucion']?.toString(),
      snapshot: json['snapshot'] is Map<String, dynamic>
          ? json['snapshot'] as Map<String, dynamic>
          : null,
      enviadoPorNombre: envName,
      resueltoPorNombre: resName,
      createdAt: json['created_at']?.toString(),
    );
  }
}
