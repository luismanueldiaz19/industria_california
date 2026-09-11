import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../inventario/providers/inventario_producto_provider.dart';
import '../../inventario/models/inventario_producto.dart';

/// Buscador de productos del catálogo.
/// Responsabilidad única: buscar y seleccionar un producto del inventario.
class PedidoProductoSearch extends StatefulWidget {
  final Set<int> productosEnCarrito; // IDs ya agregados
  final ValueChanged<InventarioProducto> onAgregar;

  const PedidoProductoSearch({
    super.key,
    required this.productosEnCarrito,
    required this.onAgregar,
  });

  @override
  State<PedidoProductoSearch> createState() => _PedidoProductoSearchState();
}

class _PedidoProductoSearchState extends State<PedidoProductoSearch> {
  static const _accentBlue = Color(0xFF1976D2);
  static final _currencyFmt =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<InventarioProductoProvider>(
      builder: (ctx, provider, _) {
        final filtrados = provider.productos.where((p) {
          if (!p.activo || _search.isEmpty) return false;
          final q = _search.toLowerCase();
          return p.nombre.toLowerCase().contains(q) ||
              p.codigo.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            _buildSearchField(),
            if (filtrados.isNotEmpty) _buildResultList(filtrados),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      decoration: InputDecoration(
        hintText: 'Buscar producto por nombre o código...',
        prefixIcon:
            const Icon(Icons.search, size: 20, color: _accentBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _search = ''),
              )
            : null,
      ),
    );
  }

  Widget _buildResultList(List<InventarioProducto> productos) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: productos.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16),
          itemBuilder: (ctx, i) => _buildProductoTile(productos[i]),
        ),
      ),
    );
  }

  Widget _buildProductoTile(InventarioProducto producto) {
    final yaAgregado = widget.productosEnCarrito.contains(producto.id);

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: _accentBlue.withValues(alpha: 0.1),
        child: Text(
          producto.codigo.length > 2
              ? producto.codigo.substring(0, 2)
              : producto.codigo,
          style: const TextStyle(
            color: _accentBlue,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        producto.nombre,
        style:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${producto.codigo} · ${_currencyFmt.format(producto.venta)} / ${producto.unidad}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: yaAgregado
          ? Icon(Icons.check_circle, color: Colors.green.shade400, size: 20)
          : IconButton(
              icon: const Icon(Icons.add_circle,
                  color: _accentBlue, size: 24),
              onPressed: () {
                widget.onAgregar(producto);
                setState(() => _search = '');
              },
            ),
    );
  }
}
