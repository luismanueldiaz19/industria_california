import 'inventario_categoria.dart';

/// Estado de stock del producto
enum EstadoStock { ok, alerta, critico, negativo }

class InventarioProducto {
  final int? id;
  final String codigo;
  final String nombre;
  final String unidad;
  final double costo;
  final double venta;
  final double stock;
  final double? stockMaximo;
  final double? stockMinimo;
  final int? categoriaId;
  final InventarioCategoria? categoria;
  final String? imagenProducto;
  final String? imagenUrl;
  final bool activo;
  final String? estadoStock; // 'ok', 'alerta', 'critico', 'negativo' — del backend

  const InventarioProducto({
    this.id,
    required this.codigo,
    required this.nombre,
    this.unidad = 'UNIDAD',
    this.costo = 0,
    this.venta = 0,
    this.stock = 0,
    this.stockMaximo,
    this.stockMinimo,
    this.categoriaId,
    this.categoria,
    this.imagenProducto,
    this.imagenUrl,
    this.activo = true,
    this.estadoStock,
  });

  /// Estado de stock calculado en Flutter (usa el del backend si viene, si no calcula)
  EstadoStock get estadoStockEnum {
    final s = estadoStock;
    if (s == 'negativo' || stock < 0) return EstadoStock.negativo;
    if (s == 'critico' || stock == 0) return EstadoStock.critico;
    if (s == 'alerta' || (stockMinimo != null && stock <= stockMinimo!)) return EstadoStock.alerta;
    return EstadoStock.ok;
  }

  factory InventarioProducto.fromJson(Map<String, dynamic> json) {
    return InventarioProducto(
      id: json['id'] as int?,
      codigo: (json['codigo'] as String?) ?? '',
      nombre: (json['nombre'] as String?) ?? '',
      unidad: (json['unidad'] as String?) ?? 'UNIDAD',
      costo: _parseDouble(json['costo']),
      venta: _parseDouble(json['venta']),
      stock: _parseDouble(json['stock']),
      stockMaximo: json['stock_maximo'] != null ? _parseDouble(json['stock_maximo']) : null,
      stockMinimo: json['stock_minimo'] != null ? _parseDouble(json['stock_minimo']) : null,
      categoriaId: json['categoria_id'] as int?,
      categoria: json['categoria'] != null
          ? InventarioCategoria.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
      imagenProducto: json['imagen_producto'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      activo: json['activo'] == true || json['activo'] == 1,
      estadoStock: json['estado_stock'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'unidad': unidad,
      'costo': costo,
      'venta': venta,
      'stock': stock,
      if (stockMaximo != null) 'stock_maximo': stockMaximo,
      if (stockMinimo != null) 'stock_minimo': stockMinimo,
      if (categoriaId != null) 'categoria_id': categoriaId,
      'activo': activo,
    };
  }

  InventarioProducto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? unidad,
    double? costo,
    double? venta,
    double? stock,
    double? stockMaximo,
    double? stockMinimo,
    int? categoriaId,
    InventarioCategoria? categoria,
    String? imagenProducto,
    String? imagenUrl,
    bool? activo,
    String? estadoStock,
  }) {
    return InventarioProducto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      costo: costo ?? this.costo,
      venta: venta ?? this.venta,
      stock: stock ?? this.stock,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      categoria: categoria ?? this.categoria,
      imagenProducto: imagenProducto ?? this.imagenProducto,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      activo: activo ?? this.activo,
      estadoStock: estadoStock ?? this.estadoStock,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
