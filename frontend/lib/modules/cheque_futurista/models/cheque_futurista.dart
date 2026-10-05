class ChequeFuturista {
  final int id;
  final int idCliente;
  final String nombreCliente;
  final String numCheque;
  final String? numPedido;
  final double monto;
  final String estado;
  final String? comentario;
  final String createdAt;
  final String? fechaDeposito;
  final String? nombreVendedor;
  final int documentosCount;

  ChequeFuturista({
    required this.id,
    required this.idCliente,
    required this.nombreCliente,
    required this.numCheque,
    this.numPedido,
    required this.monto,
    required this.estado,
    this.comentario,
    required this.createdAt,
    this.fechaDeposito,
    this.nombreVendedor,
    this.documentosCount = 0,
  });

  factory ChequeFuturista.fromJson(Map<String, dynamic> json) {
    return ChequeFuturista(
      id: json['id'],
      idCliente: json['id_cliente'],
      nombreCliente: json['cliente']?['nombre'] ?? 'Desconocido',
      numCheque: json['num_cheque'] ?? '',
      numPedido: json['num_pedido'],
      monto: json['monto'] != null
          ? double.tryParse(json['monto'].toString()) ?? 0.0
          : 0.0,
      estado: json['estado'] ?? 'pendiente',
      comentario: json['comentario'],
      createdAt: json['created_at'] ?? '',
      fechaDeposito: json['fecha_deposito'],
      nombreVendedor: json['vendedor']?['name'],
      documentosCount: json['documentos_count'] is int
          ? json['documentos_count']
          : int.tryParse('${json['documentos_count'] ?? 0}') ?? 0,
    );
  }

  ChequeFuturista copyWith({String? estado, int? documentosCount}) {
    return ChequeFuturista(
      id: id,
      idCliente: idCliente,
      nombreCliente: nombreCliente,
      numCheque: numCheque,
      numPedido: numPedido,
      monto: monto,
      estado: estado ?? this.estado,
      comentario: comentario,
      createdAt: createdAt,
      fechaDeposito: fechaDeposito,
      nombreVendedor: nombreVendedor,
      documentosCount: documentosCount ?? this.documentosCount,
    );
  }
}
