import 'package:industria_california/modules/led_house/models/cxc_alerta_model.dart';

import '../../led_house/models/ledhouse_cliente.dart';
import '../../inventario/models/inventario_producto.dart';
import 'pedido.dart';

class OrdenProduccionDetalle {
  final int id;
  final int ordenProduccionId;
  final int productoId;
  final int? pedidoDetalleId;
  final double cantidadFaltante;
  final double cantidadProducida;
  final String estado;
  final InventarioProducto? producto;

  OrdenProduccionDetalle({
    required this.id,
    required this.ordenProduccionId,
    required this.productoId,
    this.pedidoDetalleId,
    required this.cantidadFaltante,
    required this.cantidadProducida,
    required this.estado,
    this.producto,
  });

  factory OrdenProduccionDetalle.fromJson(Map<String, dynamic> json) {
    return OrdenProduccionDetalle(
      id: json['id'],
      ordenProduccionId: json['orden_produccion_id'],
      productoId: json['producto_id'],
      pedidoDetalleId: json['pedido_detalle_id'],
      cantidadFaltante: double.parse(json['cantidad_faltante'].toString()),
      cantidadProducida: double.parse(json['cantidad_producida'].toString()),
      estado: json['estado'],
      producto: json['producto'] != null
          ? InventarioProducto.fromJson(json['producto'])
          : null,
    );
  }
}

class OrdenProduccion {
  final int id;
  final int? pedidoId;
  final int clienteId;
  final int vendedorId;
  final String estado;
  final DateTime? fechaEstimadaEntrega;
  final String? notas;
  final DateTime createdAt;

  final LedhouseCliente? cliente;
  final UserModel? vendedor;
  final Pedido? pedido;
  final List<OrdenProduccionDetalle> detalles;

  OrdenProduccion({
    required this.id,
    this.pedidoId,
    required this.clienteId,
    required this.vendedorId,
    required this.estado,
    this.fechaEstimadaEntrega,
    this.notas,
    required this.createdAt,
    this.cliente,
    this.vendedor,
    this.pedido,
    this.detalles = const [],
  });

  factory OrdenProduccion.fromJson(Map<String, dynamic> json) {
    return OrdenProduccion(
      id: json['id'],
      pedidoId: json['pedido_id'],
      clienteId: json['cliente_id'],
      vendedorId: json['vendedor_id'],
      estado: json['estado'],
      fechaEstimadaEntrega: json['fecha_estimada_entrega'] != null
          ? DateTime.parse(json['fecha_estimada_entrega'])
          : null,
      notas: json['notas'],
      createdAt: DateTime.parse(json['created_at']),
      cliente: json['cliente'] != null
          ? LedhouseCliente.fromJson(json['cliente'])
          : null,
      vendedor: json['vendedor'] != null
          ? UserModel.fromJson(json['vendedor'])
          : null,
      pedido: json['pedido'] != null ? Pedido.fromJson(json['pedido']) : null,
      detalles: json['detalles'] != null
          ? (json['detalles'] as List)
                .map((d) => OrdenProduccionDetalle.fromJson(d))
                .toList()
          : [],
    );
  }
}
