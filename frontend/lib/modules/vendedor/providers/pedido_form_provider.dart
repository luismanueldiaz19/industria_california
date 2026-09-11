import 'package:flutter/material.dart';
import '../../led_house/models/ledhouse_cliente.dart';
import '../../logistica/models/ruta.dart';
import '../../logistica/models/pedido.dart';
import '../../inventario/models/inventario_producto.dart';
import '../models/cart_item.dart';

class PedidoFormProvider extends ChangeNotifier {
  LedhouseCliente? _cliente;
  Ruta? _ruta;
  String _comentario = '';
  final List<CartItem> _carrito = [];

  // En caso de edición
  Pedido? _pedidoOriginal;
  bool get isEditing => _pedidoOriginal != null;
  int? get originalId => _pedidoOriginal?.id;

  LedhouseCliente? get cliente => _cliente;
  Ruta? get ruta => _ruta;
  String get comentario => _comentario;
  List<CartItem> get carrito => _carrito;

  double get total => _carrito.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => _carrito.length;

  void initFromPedido(
    Pedido pedido,
    List<LedhouseCliente> clientes,
    List<Ruta> rutas,
    List<InventarioProducto> productos,
  ) {
    _pedidoOriginal = pedido;
    _comentario = pedido.comentario ?? '';

    try {
      _cliente = clientes.firstWhere((c) => c.id == pedido.clienteId);
    } catch (_) {}

    if (pedido.rutaId != null) {
      try {
        _ruta = rutas.firstWhere((r) => r.id == pedido.rutaId);
      } catch (_) {}
    }

    _carrito.clear();
    for (final det in pedido.detalles) {
      InventarioProducto? prod;
      try {
        prod = productos.firstWhere((p) => p.id == det.productoId);
      } catch (_) {}

      final item = CartItem(
        productoId: det.productoId,
        productoNombre:
            det.productoNombre ?? prod?.nombre ?? 'Producto #${det.productoId}',
        productoCodigo: det.productoCodigo ?? prod?.codigo ?? '',
        unidad: prod?.unidad ?? 'UN',
        precioBase: prod?.venta ?? det.precioUnitario,
        precioController: TextEditingController(
          text: det.precioUnitario.toStringAsFixed(2),
        ),
        cantidadController: TextEditingController(
          text: det.cantidad % 1 == 0
              ? det.cantidad.toInt().toString()
              : det.cantidad.toStringAsFixed(3),
        ),
        observacionController: TextEditingController(
          text: det.observacion ?? '',
        ),
      );
      // Añadir listener a los controladores para recalcular total
      item.cantidadController.addListener(notifyListeners);
      item.precioController.addListener(notifyListeners);
      _carrito.add(item);
    }
    notifyListeners();
  }

  void setCliente(LedhouseCliente? c) {
    _cliente = c;
    notifyListeners();
  }

  void setRuta(Ruta? r) {
    _ruta = r;
    notifyListeners();
  }

  void setComentario(String text) {
    _comentario = text;
    // No hace falta notifyListeners si solo actualiza el modelo en textchange
  }

  void agregarProducto(
    InventarioProducto producto,
    double cantidad,
    double precioUnitario,
  ) {
    // Si ya existe, actualizamos la cantidad en vez de agregar otro (opcional)
    final idx = _carrito.indexWhere((i) => i.productoId == producto.id);
    if (idx != -1) {
      final item = _carrito[idx];
      final cantActual = double.tryParse(item.cantidadController.text) ?? 0;
      final nuevaCant = cantActual + cantidad;
      item.cantidadController.text = nuevaCant % 1 == 0
          ? nuevaCant.toInt().toString()
          : nuevaCant.toStringAsFixed(3);
      item.precioController.text = precioUnitario.toStringAsFixed(2);
      notifyListeners();
      return;
    }

    final item = CartItem.fromProducto(producto);
    item.cantidadController.text = cantidad % 1 == 0
        ? cantidad.toInt().toString()
        : cantidad.toStringAsFixed(3);
    item.precioController.text = precioUnitario.toStringAsFixed(2);

    // Escuchar cambios en precio/cantidad para el subtotal reactivo
    item.cantidadController.addListener(notifyListeners);
    item.precioController.addListener(notifyListeners);

    _carrito.add(item);
    notifyListeners();
  }

  void quitarProducto(int productoId) {
    final item = _carrito.firstWhere((i) => i.productoId == productoId);
    item.cantidadController.removeListener(notifyListeners);
    item.precioController.removeListener(notifyListeners);
    item.dispose();
    _carrito.removeWhere((i) => i.productoId == productoId);
    notifyListeners();
  }

  bool get esValidoPaso1 => _cliente != null;
  bool get esValidoPaso2 =>
      _carrito.isNotEmpty && _carrito.every((i) => i.precioEsValido);

  Map<String, dynamic> buildPayload(String estado) {
    return {
      'cliente_id': _cliente!.id,
      'ruta_id': _ruta?.id,
      'estado': estado,
      'comentario': _comentario.isEmpty ? null : _comentario,
      'detalles': _carrito.map((i) => i.toJson()).toList(),
    };
  }

  @override
  void dispose() {
    for (final item in _carrito) {
      item.cantidadController.removeListener(notifyListeners);
      item.precioController.removeListener(notifyListeners);
      item.dispose();
    }
    super.dispose();
  }
}
