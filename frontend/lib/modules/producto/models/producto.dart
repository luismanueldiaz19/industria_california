import '../../../core/network/net_work.dart';
import 'categoria.dart';

/// Estado de stock del producto
enum EstadoStock { ok, alerta, critico, negativo }

class Producto {
  final int? id;
  final String? codigo;
  final String descripcion;
  final int? parentId;
  final String? imagenProducto;
  final String? imagenUrl;
  final int? cantXPackages;
  final String? medidas;
  final String? capacidad;
  final String unidad;
  final double precio;
  final double costo;
  final double stock;
  final double? stockMaximo;
  final double? stockMinimo;
  final int? categoriaId;
  final Categoria? categoria;
  final bool activo;
  final List<Producto> variants;

  const Producto({
    this.id,
    this.codigo,
    required this.descripcion,
    this.parentId,
    this.imagenProducto,
    this.imagenUrl,
    this.cantXPackages,
    this.medidas,
    this.capacidad,
    this.unidad = 'UNIDAD',
    this.precio = 0,
    this.costo = 0,
    this.stock = 0,
    this.stockMaximo,
    this.stockMinimo,
    this.categoriaId,
    this.categoria,
    this.activo = true,
    this.variants = const [],
  });

  EstadoStock get estadoStockEnum {
    if (stock < 0) return EstadoStock.negativo;
    if (stock == 0) return EstadoStock.critico;
    if (stockMinimo != null && stock <= stockMinimo!) return EstadoStock.alerta;
    return EstadoStock.ok;
  }

  String get nombreCompleto {
    final parts = [
      descripcion,
      if (medidas != null && medidas!.isNotEmpty) medidas!,
      if (capacidad != null && capacidad!.isNotEmpty) capacidad!,
      if (unidad.isNotEmpty && unidad.toUpperCase() != 'UNIDAD') unidad,
    ];
    return parts.join(' ').trim().toUpperCase();
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    String? url = json['imagen_url'] as String?;
    if (url != null && url.startsWith('/')) {
      url = '$host$url';
    }

    return Producto(
      id: json['id'] as int?,
      codigo: json['codigo'] as String?,
      descripcion: (json['descripcion'] as String?) ?? '',
      parentId: json['parent_id'] as int?,
      imagenProducto: json['imagen_producto'] as String?,
      imagenUrl: url,
      cantXPackages: json['cant_x_packages'] as int?,
      medidas: json['medidas'] as String?,
      capacidad: json['capacidad'] as String?,
      unidad: (json['unidad'] as String?) ?? 'UNIDAD',
      precio: _parseDouble(json['precio']),
      costo: _parseDouble(json['costo']),
      stock: _parseDouble(json['stock']),
      stockMaximo: json['stock_maximo'] != null
          ? _parseDouble(json['stock_maximo'])
          : null,
      stockMinimo: json['stock_minimo'] != null
          ? _parseDouble(json['stock_minimo'])
          : null,
      categoriaId: json['category_id'] as int?,
      categoria: json['categoria'] != null
          ? Categoria.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
      activo: json['activo'] == true || json['activo'] == 1,
      variants: (json['variants'] as List? ?? [])
          .map((v) => Producto.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      'descripcion': descripcion,
      if (parentId != null) 'parent_id': parentId,
      if (cantXPackages != null) 'cant_x_packages': cantXPackages,
      if (medidas != null) 'medidas': medidas,
      if (capacidad != null) 'capacidad': capacidad,
      'unidad': unidad,
      'precio': precio,
      'costo': costo,
      'stock': stock,
      if (stockMaximo != null) 'stock_maximo': stockMaximo,
      if (stockMinimo != null) 'stock_minimo': stockMinimo,
      if (categoriaId != null) 'category_id': categoriaId,
      'activo': activo,
    };
  }

  Producto copyWith({
    int? id,
    String? codigo,
    String? descripcion,
    int? parentId,
    String? imagenProducto,
    String? imagenUrl,
    int? cantXPackages,
    String? medidas,
    String? capacidad,
    String? unidad,
    double? precio,
    double? costo,
    double? stock,
    double? stockMaximo,
    double? stockMinimo,
    int? categoriaId,
    Categoria? categoria,
    bool? activo,
    List<Producto>? variants,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      parentId: parentId ?? this.parentId,
      imagenProducto: imagenProducto ?? this.imagenProducto,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      cantXPackages: cantXPackages ?? this.cantXPackages,
      medidas: medidas ?? this.medidas,
      capacidad: capacidad ?? this.capacidad,
      unidad: unidad ?? this.unidad,
      precio: precio ?? this.precio,
      costo: costo ?? this.costo,
      stock: stock ?? this.stock,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      categoria: categoria ?? this.categoria,
      activo: activo ?? this.activo,
      variants: variants ?? this.variants,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
