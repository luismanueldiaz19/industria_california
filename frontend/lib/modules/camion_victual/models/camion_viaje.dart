/// Modelo que representa un Viaje Histórico Liquidado de Camión.
class CamionViaje {
  final int id;
  final String codigo;
  final int? camionVictualId;
  final int? choferId;
  final int? vendedorId;
  final int? vehiculoId;
  final DateTime? fechaSalida;
  final DateTime? fechaCierre;
  final double totalFacturado;
  final double totalGastos;
  final double margenNeto;
  final double porcentajeGastos;
  final int cantAyudantes;
  final String? nombresAyudantes;
  final String? comentarios;
  final String estado; // en_ruta | completado | cancelado
  final String? choferNombre;
  final String? vendedorNombre;
  final String? cerradoPorNombre;
  final List<CamionViajeGasto> gastos;
  final List<CamionViajePedido> pedidos;

  const CamionViaje({
    required this.id,
    required this.codigo,
    this.camionVictualId,
    this.choferId,
    this.vendedorId,
    this.vehiculoId,
    this.fechaSalida,
    this.fechaCierre,
    required this.totalFacturado,
    required this.totalGastos,
    required this.margenNeto,
    required this.porcentajeGastos,
    required this.cantAyudantes,
    this.nombresAyudantes,
    this.comentarios,
    required this.estado,
    this.choferNombre,
    this.vendedorNombre,
    this.cerradoPorNombre,
    this.gastos = const [],
    this.pedidos = const [],
  });

  factory CamionViaje.fromJson(Map<String, dynamic> json) {
    final gastosRaw = json['gastos'] as List? ?? [];
    final pedidosRaw = json['pedidos'] as List? ?? [];

    final totalFacturado =
        double.tryParse(json['total_facturado']?.toString() ?? '0') ?? 0;
    final totalGastos =
        double.tryParse(json['total_gastos']?.toString() ?? '0') ?? 0;
    final margenNeto =
        double.tryParse(
          json['margen_neto']?.toString() ?? '${totalFacturado - totalGastos}',
        ) ??
        (totalFacturado - totalGastos);
    final porcentajeGastos =
        double.tryParse(json['porcentaje_gastos']?.toString() ?? '0') ?? 0;

    return CamionViaje(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      codigo: json['codigo'] ?? '',
      camionVictualId: json['camion_victual_id'] != null
          ? int.tryParse(json['camion_victual_id'].toString())
          : null,
      choferId: json['chofer_id'] != null
          ? int.tryParse(json['chofer_id'].toString())
          : null,
      vendedorId: json['vendedor_id'] != null
          ? int.tryParse(json['vendedor_id'].toString())
          : null,
      vehiculoId: json['vehiculo_id'] != null
          ? int.tryParse(json['vehiculo_id'].toString())
          : null,
      fechaSalida: json['fecha_salida'] != null
          ? DateTime.tryParse(json['fecha_salida'])
          : null,
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.tryParse(json['fecha_cierre'])
          : null,
      totalFacturado: totalFacturado,
      totalGastos: totalGastos,
      margenNeto: margenNeto,
      porcentajeGastos: porcentajeGastos,
      cantAyudantes:
          int.tryParse(json['cant_ayudantes']?.toString() ?? '0') ?? 0,
      nombresAyudantes: json['nombres_ayudantes'],
      comentarios: json['comentarios'],
      estado: json['estado'] is Map
          ? (json['estado']['value'] ?? json['estado'].toString())
          : (json['estado'] ?? 'en_ruta'),
      choferNombre: json['chofer']?['user']?['name'] ?? json['chofer_nombre'],
      vendedorNombre: json['vendedor']?['name'] ?? json['vendedor_nombre'],
      cerradoPorNombre:
          json['cerrado_por']?['name'] ?? json['cerrado_por_nombre'],
      gastos: gastosRaw.map((g) => CamionViajeGasto.fromJson(g)).toList(),
      pedidos: pedidosRaw.map((p) => CamionViajePedido.fromJson(p)).toList(),
    );
  }
}

/// Gasto asociado a un viaje (combustible, dieta, peaje, etc.).
class CamionViajeGasto {
  final int id;
  final int viajeId;
  final String tipoGasto; // combustible | dieta | peaje | hotel | otro
  final String concepto;
  final double cantidad;
  final double precioUnitario;
  final double montoTotal;
  final String? comprobante;

  const CamionViajeGasto({
    required this.id,
    required this.viajeId,
    required this.tipoGasto,
    required this.concepto,
    required this.cantidad,
    required this.precioUnitario,
    required this.montoTotal,
    this.comprobante,
  });

  factory CamionViajeGasto.fromJson(Map<String, dynamic> json) {
    return CamionViajeGasto(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      viajeId: int.tryParse(json['viaje_id']?.toString() ?? '0') ?? 0,
      tipoGasto: json['tipo_gasto'] is Map
          ? (json['tipo_gasto']['value'] ?? json['tipo_gasto'].toString())
          : (json['tipo_gasto'] ?? 'otro'),
      concepto: json['concepto'] ?? '',
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0,
      precioUnitario:
          double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0,
      montoTotal: double.tryParse(json['monto_total']?.toString() ?? '0') ?? 0,
      comprobante: json['comprobante'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tipo_gasto': tipoGasto,
    'concepto': concepto,
    'cantidad': cantidad,
    'precio_unitario': precioUnitario,
    'monto_total': montoTotal,
    if (comprobante != null && comprobante!.isNotEmpty)
      'comprobante': comprobante,
  };
}

/// Registro histórico de un pedido dentro del viaje.
class CamionViajePedido {
  final int id;
  final int viajeId;
  final int pedidoId;
  final int ordenViaje;
  final String estadoEntrega; // pendiente | en_curso | entregado | fallido
  final DateTime? fechaEntregado;
  final String? comentarioEntrega;
  final double totalPedido;
  final String? clienteNombre;
  final String? numFactura;

  const CamionViajePedido({
    required this.id,
    required this.viajeId,
    required this.pedidoId,
    required this.ordenViaje,
    required this.estadoEntrega,
    this.fechaEntregado,
    this.comentarioEntrega,
    required this.totalPedido,
    this.clienteNombre,
    this.numFactura,
  });

  factory CamionViajePedido.fromJson(Map<String, dynamic> json) {
    final pedidoData = json['pedido'] as Map<String, dynamic>?;
    return CamionViajePedido(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      viajeId: int.tryParse(json['viaje_id']?.toString() ?? '0') ?? 0,
      pedidoId: int.tryParse(json['pedido_id']?.toString() ?? '0') ?? 0,
      ordenViaje: int.tryParse(json['orden_viaje']?.toString() ?? '0') ?? 0,
      estadoEntrega: json['estado_entrega'] is Map
          ? (json['estado_entrega']['value'] ??
                json['estado_entrega'].toString())
          : (json['estado_entrega'] ?? 'pendiente'),
      fechaEntregado: json['fecha_entregado'] != null
          ? DateTime.tryParse(json['fecha_entregado'])
          : null,
      comentarioEntrega: json['comentario_entrega'],
      totalPedido:
          double.tryParse(json['total_pedido']?.toString() ?? '0') ?? 0,
      clienteNombre: pedidoData?['cliente']?['nombre'],
      numFactura: pedidoData?['num_factura'],
    );
  }
}
