import 'pedido_detalle.dart';

class Pedido {
  final int id;
  final int clienteId;
  final int? rutaId;
  final int vendedorId;
  final int? facturadorId;
  final String estado;
  final String? comentario;
  final double total;
  final DateTime createdAt;
  final DateTime? fechaEntrega;
  final String? notaProduccion;
  final String? numFactura;
  
  // Relations mapped from JSON
  final String? clienteNombre;
  final String? rutaNombre;
  final String? vendedorNombre;
  final int? ordenProduccionId;
  final String? ordenProduccionEstado;
  final List<PedidoDetalle> detalles;

  Pedido({
    required this.id,
    required this.clienteId,
    this.rutaId,
    required this.vendedorId,
    this.facturadorId,
    required this.estado,
    this.comentario,
    required this.total,
    required this.createdAt,
    this.fechaEntrega,
    this.notaProduccion,
    this.numFactura,
    this.clienteNombre,
    this.rutaNombre,
    this.vendedorNombre,
    this.ordenProduccionId,
    this.ordenProduccionEstado,
    this.detalles = const [],
  });

  bool get tieneOrdenProduccion => ordenProduccionId != null;
  bool get tieneFaltantes => detalles.any((d) => d.cantidadEnProduccion > 0);

  factory Pedido.fromJson(Map<String, dynamic> json) {
    var list = json['detalles'] as List? ?? [];
    List<PedidoDetalle> detallesList = list.map((i) => PedidoDetalle.fromJson(i)).toList();

    return Pedido(
      id: json['id'],
      clienteId: json['cliente_id'],
      rutaId: json['ruta_id'],
      vendedorId: json['vendedor_id'],
      facturadorId: json['facturador_id'],
      estado: json['estado'],
      comentario: json['comentario'],
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      fechaEntrega: json['fecha_entrega'] != null ? DateTime.parse(json['fecha_entrega']) : null,
      notaProduccion: json['nota_produccion'],
      numFactura: json['num_factura']?.toString(),
      clienteNombre: json['cliente']?['nombre'],
      rutaNombre: json['ruta']?['nombre'],
      vendedorNombre: json['vendedor']?['name'],
      ordenProduccionId: json['orden_produccion']?['id'],
      ordenProduccionEstado: json['orden_produccion']?['estado'],
      detalles: detallesList,
    );
  }
}
