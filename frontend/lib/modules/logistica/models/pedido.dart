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
  
  // Relations mapped from JSON
  final String? clienteNombre;
  final String? rutaNombre;
  final String? vendedorNombre;
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
    this.clienteNombre,
    this.rutaNombre,
    this.vendedorNombre,
    this.detalles = const [],
  });

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
      clienteNombre: json['cliente']?['nombre'],
      rutaNombre: json['ruta']?['nombre'],
      vendedorNombre: json['vendedor']?['name'],
      detalles: detallesList,
    );
  }
}
