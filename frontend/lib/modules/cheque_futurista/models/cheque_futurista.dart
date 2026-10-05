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
    );
  }
}
