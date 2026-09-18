class PedidoDetalle {
  final int id;
  final int? pedidoId;
  final int productoId;
  final double cantidad;
  final double cantidadEnProduccion;
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
    required this.cantidadEnProduccion,
    required this.precioUnitario,
    required this.subtotal,
    this.observacion,
    this.productoNombre,
    this.productoCodigo,
  });

  factory PedidoDetalle.fromJson(Map<String, dynamic> json) {
    String? buildNombreCompleto(Map<String, dynamic>? producto) {
      if (producto == null) return null;
      final descripcion = producto['descripcion'] ?? producto['nombre'] ?? '';
      final medidas = producto['medidas'];
      final capacidad = producto['capacidad'];
      final unidad = producto['unidad'] ?? '';

      final parts = [
        if (descripcion.toString().isNotEmpty) descripcion.toString(),
        if (medidas != null && medidas.toString().isNotEmpty)
          medidas.toString(),
        if (capacidad != null && capacidad.toString().isNotEmpty)
          capacidad.toString(),
        if (unidad.toString().isNotEmpty &&
            unidad.toString().toUpperCase() != 'UNIDAD')
          unidad.toString(),
      ];

      if (parts.isEmpty) return null;
      return parts.join(' ').trim().toUpperCase();
    }

    return PedidoDetalle(
      id: json['id'] ?? 0,
      pedidoId: json['pedido_id'],
      productoId: json['producto_id'],
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '0') ?? 0,
      cantidadEnProduccion:
          double.tryParse(json['cantidad_en_produccion']?.toString() ?? '0') ??
          0,
      precioUnitario:
          double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      observacion: json['observacion'],
      productoNombre:
          buildNombreCompleto(json['producto']) ??
          json['producto']?['nombre_completo'],
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
