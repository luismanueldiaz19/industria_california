class PedidoDetalle {
  final int id;
  final int? pedidoId;
  final int productoId;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? observacion;
  
  // Extra fields for UI mapping
  final String? productoNombre;
  final String? productoCodigo;

  PedidoDetalle({
    required this.id,
    this.pedidoId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.observacion,
    this.productoNombre,
    this.productoCodigo,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> json) {
    return PedidoDetalle(
      id: json['id'] ?? 0,
      pedidoId: json['pedido_id'],
      productoId: json['producto_id'],
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0,
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      observacion: json['observacion'],
      productoNombre: json['producto']?['nombre'],
      productoCodigo: json['producto']?['codigo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'observacion': observacion,
    };
  }
}
