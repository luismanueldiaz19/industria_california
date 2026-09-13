import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../services/http_service.dart';
import '../../../inventario/providers/inventario_producto_provider.dart';
import '../../../inventario/models/inventario_producto.dart';
import '../../providers/pedido_form_provider.dart';

class VendedorPedidoCatalogoScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const VendedorPedidoCatalogoScreen({
    super.key,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<VendedorPedidoCatalogoScreen> createState() =>
      _VendedorPedidoCatalogoScreenState();
}

class _VendedorPedidoCatalogoScreenState
    extends State<VendedorPedidoCatalogoScreen> {
  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);
  static final _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  String _searchQuery = '';
  String _selectedCategoria = 'Todas';

  List<String> get _categorias {
    final prods = context.read<InventarioProductoProvider>().productos;
    final cats = prods
        .map((p) => p.categoria?.nombre ?? 'Sin categoría')
        .toSet()
        .toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  List<InventarioProducto> get _productosFiltrados {
    final prods = context.watch<InventarioProductoProvider>().productos;
    return prods.where((p) {
      if (!p.activo) return false;

      final matchesSearch =
          _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.codigo.toLowerCase().contains(_searchQuery.toLowerCase());

      final cat = p.categoria?.nombre ?? 'Sin categoría';
      final matchesCat =
          _selectedCategoria == 'Todas' || cat == _selectedCategoria;

      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildGrid()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Botón para carrito con Badge en Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                color: _primaryBlue,
                onPressed: _mostrarCarritoBottomSheet,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              Consumer<PedidoFormProvider>(
                builder: (ctx, prov, _) => prov.itemCount > 0
                    ? Positioned(
                        right: -4,
                        top: -4,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.red,
                          child: Text(
                            '${prov.itemCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Búsqueda
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 32,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Filtro Categoría
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: DropdownButtonFormField<String>(
                value: _selectedCategoria,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  filled: true,
                  isDense: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _categorias
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoria = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final filtrados = _productosFiltrados;

    if (filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180, // Más pequeñas para caber más en móvil
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72, // Ajuste para que el texto encaje mejor
      ),
      itemCount: filtrados.length,
      itemBuilder: (ctx, i) => _buildProductoCard(filtrados[i]),
    );
  }

  Widget _buildProductoCard(InventarioProducto producto) {
    final hasStock = producto.stock > 0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _mostrarDialogoAgregar(producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  producto.imagenUrl != null
                      ? Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.cover,
                          headers: {
                            'Authorization': 'Bearer ${HttpService.token}',
                          },
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                  if (!hasStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  // Badge de Stock
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasStock
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stock: ${producto.stock % 1 == 0 ? producto.stock.toInt() : producto.stock.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.codigo,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11, // Letra más chica
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFmt.format(producto.venta),
                          style: const TextStyle(
                            color: _accentBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _accentBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: _accentBlue,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAgregar(InventarioProducto producto) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _AddProductDialog(
            producto: producto,
            onConfirm: (cant, precio) {
              context.read<PedidoFormProvider>().agregarProducto(
                producto,
                cant,
                precio,
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── CART BOTTOM SHEET ──────────────────────────────────────────────────────

  void _mostrarCarritoBottomSheet() {
    final provider = context.read<PedidoFormProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ChangeNotifierProvider<PedidoFormProvider>.value(
            value: provider,
            child: _buildCartBottomSheetContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCartBottomSheetContent() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer<PedidoFormProvider>(
            builder: (ctx, provider, _) {
              return Column(
                children: [
                  // Grabber
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header del carrito
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart,
                              color: _primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mi Pedido (${provider.itemCount})',
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Lista de ítems
                  Expanded(
                    child: provider.carrito.isEmpty
                        ? Center(
                            child: Text(
                              'El carrito está vacío',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.carrito.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 24),
                            itemBuilder: (context, i) {
                              final item = provider.carrito[i];
                              return _buildCartItemTile(item, provider);
                            },
                          ),
                  ),

                  // Footer (Total y botón Next)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _currencyFmt.format(provider.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: provider.esValidoPaso2
                                ? () {
                                    Navigator.pop(ctx);
                                    widget.onNext();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Revisar Pedido →',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCartItemTile(dynamic item, PedidoFormProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del ítem
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productoNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.cantidadController.text} ${item.unidad} x ${_currencyFmt.format(double.tryParse(item.precioController.text) ?? 0)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (!item.precioEsValido)
                  const Text(
                    'Precio fuera de rango (±20%)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Subtotal y Quitar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFmt.format(item.subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _accentBlue,
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: () => provider.quitarProducto(item.productoId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: widget.onPrev,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Atrás', style: TextStyle(fontSize: 13)),
          ),
          Consumer<PedidoFormProvider>(
            builder: (ctx, prov, _) => ElevatedButton(
              onPressed: prov.esValidoPaso2 ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Revisar →',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo flotante para ingresar Cantidad y Precio al tocar un producto.
class _AddProductDialog extends StatefulWidget {
  final InventarioProducto producto;
  final void Function(double cantidad, double precio) onConfirm;

  const _AddProductDialog({required this.producto, required this.onConfirm});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _cantCtrl = TextEditingController(text: '1');
  late final TextEditingController _precioCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _precioCtrl = TextEditingController(
      text: widget.producto.venta.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final minPrecio = p.venta * 0.8;
    final maxPrecio = p.venta * 1.2;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: p.imagenUrl != null
                        ? Image.network(
                            p.imagenUrl!,
                            fit: BoxFit.cover,
                            headers: {
                              'Authorization': 'Bearer ${HttpService.token}',
                            },
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.inventory, color: Colors.blue),
                          )
                        : const Icon(Icons.inventory_2, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Stock actual: ${p.stock % 1 == 0 ? p.stock.toInt() : p.stock.toStringAsFixed(2)} ${p.unidad}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inputs
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cantCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,3}'),
                        ),
                      ],
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Inválido';
                        // No validamos contra stock porque el user pidió poder mandar a pedir si falta
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Inválido';
                        if (p.venta > 0 && (val < minPrecio || val > maxPrecio))
                          return 'Rango ±20%\n(${fmt.format(minPrecio)} - ${fmt.format(maxPrecio)})';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final cant = double.parse(_cantCtrl.text);
                        final precio = double.parse(_precioCtrl.text);
                        widget.onConfirm(cant, precio);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Agregar',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
