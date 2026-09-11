import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../inventario/models/inventario_producto.dart';

/// Representa un ítem dentro del carrito de pedido.
/// Encapsula los controladores de texto y la lógica de subtotal.
class CartItem {
  final int productoId;
  final String productoNombre;
  final String productoCodigo;
  final String unidad;

  /// Precio base tomado de inventario_producto.venta
  final double precioBase;

  final TextEditingController precioController;
  final TextEditingController cantidadController;
  final TextEditingController observacionController;

  CartItem({
    required this.productoId,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidad,
    required this.precioBase,
    required this.precioController,
    required this.cantidadController,
    required this.observacionController,
  });

  /// Crea un CartItem a partir de un producto de inventario con valores por defecto.
  factory CartItem.fromProducto(InventarioProducto producto) {
    return CartItem(
      productoId: producto.id!,
      productoNombre: producto.nombre,
      productoCodigo: producto.codigo,
      unidad: producto.unidad,
      precioBase: producto.venta,
      precioController: TextEditingController(
        text: producto.venta.toStringAsFixed(2),
      ),
      cantidadController: TextEditingController(text: '1'),
      observacionController: TextEditingController(),
    );
  }

  double get subtotal {
    final cantidad = double.tryParse(cantidadController.text) ?? 0;
    final precio = double.tryParse(precioController.text) ?? 0;
    return cantidad * precio;
  }

  double get precioActual =>
      double.tryParse(precioController.text) ?? precioBase;

  double get minPrecio => precioBase * 0.8;
  double get maxPrecio => precioBase * 1.2;

  bool get precioEsValido {
    final p = precioActual;
    if (precioBase <= 0) return p >= 0;
    return p >= minPrecio && p <= maxPrecio;
  }

  Map<String, dynamic> toJson() => {
        'producto_id': productoId,
        'cantidad': double.tryParse(cantidadController.text) ?? 1,
        'precio_unitario': precioActual,
        'observacion': observacionController.text.isEmpty
            ? null
            : observacionController.text,
      };

  void dispose() {
    precioController.dispose();
    cantidadController.dispose();
    observacionController.dispose();
  }
}
