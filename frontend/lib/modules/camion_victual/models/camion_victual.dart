/// Modelo de un Camión Victual.
/// Contiene los pedidos cargados por el vendedor, ordenados por [ordenViaje].
class CamionVictual {
  final int id;
  final int choferID;
  final int vendedorId;
  final String nombre;
  final int slotNumero;
  final String estado; // armando | listo | en_ruta | cerrado
  final double montoTotal;
  final double minimoSalida;
  final DateTime? fechaCierre;
  final String? choferNombre;
  final String? vendedorNombre;
  final String? notas;
  final List<CamionPedido> pedidos;

  const CamionVictual({
    required this.id,
    required this.choferID,
    required this.vendedorId,
    required this.nombre,
    required this.slotNumero,
    required this.estado,
    required this.montoTotal,
    required this.minimoSalida,
    this.fechaCierre,
    this.choferNombre,
    this.vendedorNombre,
    this.notas,
    this.pedidos = const [],
  });

  factory CamionVictual.fromJson(Map<String, dynamic> json) {
    final pedidosRaw = json['pedidos'] as List? ?? [];
    return CamionVictual(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      choferID: int.tryParse(json['chofer_id']?.toString() ?? '0') ?? 0,
      vendedorId: int.tryParse(json['vendedor_id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre'] ?? '',
      slotNumero: int.tryParse(json['slot_numero']?.toString() ?? '1') ?? 1,
      estado: json['estado'] is Map
          ? (json['estado']['value'] ?? json['estado'].toString())
          : (json['estado'] ?? 'armando'),
      montoTotal: double.tryParse(json['monto_total']?.toString() ?? '0') ?? 0,
      minimoSalida: double.tryParse(json['minimo_salida']?.toString() ?? '5000') ?? 5000,
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.tryParse(json['fecha_cierre'])
          : null,
      choferNombre: json['chofer']?['user']?['name'],
      vendedorNombre: json['vendedor']?['name'],
      notas: json['notas'],
      pedidos: pedidosRaw.map((p) => CamionPedido.fromJson(p)).toList(),
    );
  }

  bool get puedeModificar => estado == 'armando' || estado == 'vacio';
  bool get estaListo => estado == 'listo';
  bool get estaEnRuta => estado == 'en_ruta';
  bool get estaCerrado => estado == 'cerrado';
}

/// Pedido dentro de un camión victual con sus datos de pivot.
class CamionPedido {
  final int id;
  final int clienteId;
  final double total;
  final String estadoPedido;
  final String? clienteNombre;
  final String? clienteDireccion;
  // Pivot fields
  final int ordenViaje;
  final String estadoEntrega; // pendiente | en_curso | entregado | fallido
  final String? comentarioEntrega;
  final DateTime? fechaEntregado;

  const CamionPedido({
    required this.id,
    required this.clienteId,
    required this.total,
    required this.estadoPedido,
    this.clienteNombre,
    this.clienteDireccion,
    required this.ordenViaje,
    required this.estadoEntrega,
    this.comentarioEntrega,
    this.fechaEntregado,
  });

  factory CamionPedido.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>? ?? {};
    return CamionPedido(
      id: json['id'],
      clienteId: json['cliente_id'],
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      estadoPedido: json['estado'] is Map
          ? (json['estado']['value'] ?? '')
          : (json['estado'] ?? ''),
      clienteNombre: json['cliente']?['nombre'],
      clienteDireccion: json['cliente']?['direccion'],
      ordenViaje: pivot['orden_viaje'] ?? 0,
      estadoEntrega: pivot['estado_entrega'] ?? 'pendiente',
      comentarioEntrega: pivot['comentario_entrega'],
      fechaEntregado: pivot['fecha_entregado'] != null
          ? DateTime.tryParse(pivot['fecha_entregado'])
          : null,
    );
  }
}

/// Pedido disponible para agregar a un camión (estado: facturado, sin camión activo).
class PedidoDisponible {
  final int id;
  final int clienteId;
  final double total;
  final String? clienteNombre;
  final DateTime createdAt;

  const PedidoDisponible({
    required this.id,
    required this.clienteId,
    required this.total,
    this.clienteNombre,
    required this.createdAt,
  });

  factory PedidoDisponible.fromJson(Map<String, dynamic> json) {
    return PedidoDisponible(
      id: json['id'],
      clienteId: json['cliente_id'],
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      clienteNombre: json['cliente']?['nombre'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
