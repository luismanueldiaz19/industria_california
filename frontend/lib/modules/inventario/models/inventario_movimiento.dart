import 'inventario_producto.dart';

class InventarioMovimiento {
  final int? id;
  final int productoId;
  final InventarioProducto? producto;
  final int? userId;
  final String? userName;
  final String tipo; // AJUSTE, PRODUCCION, VENTA, BAJA
  final String? subtipo; // MALO, PERDIDO, DAÑADO
  final double cantidad;
  final double stockAnterior;
  final double stockResultante;
  final String? nota;
  final DateTime? createdAt;

  const InventarioMovimiento({
    this.id,
    required this.productoId,
    this.producto,
    this.userId,
    this.userName,
    required this.tipo,
    this.subtipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockResultante,
    this.nota,
    this.createdAt,
  });

  bool get esEntrada => cantidad > 0;

  factory InventarioMovimiento.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return InventarioMovimiento(
      id: json['id'] as int?,
      productoId: (json['producto_id'] as int?) ?? 0,
      producto: json['producto'] != null
          ? InventarioProducto.fromJson(json['producto'] as Map<String, dynamic>)
          : null,
      userId: user?['id'] as int? ?? json['user_id'] as int?,
      userName: user?['name'] as String?,
      tipo: (json['tipo'] as String?) ?? 'AJUSTE',
      subtipo: json['subtipo'] as String?,
      cantidad: _parseDouble(json['cantidad']),
      stockAnterior: _parseDouble(json['stock_anterior']),
      stockResultante: _parseDouble(json['stock_resultante']),
      nota: json['nota'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto_id': productoId,
      'tipo': tipo,
      if (subtipo != null) 'subtipo': subtipo,
      'cantidad': cantidad,
      if (nota != null) 'nota': nota,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
