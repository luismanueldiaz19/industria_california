import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/dimension_parser.dart';
import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../providers/categoria_provider.dart';
// import '../providers/inventario_movimiento_provider.dart';
import '../widgets/filter_bar.dart';
import '../widgets/producto_grid_card.dart';
import '../widgets/producto_form_dialog.dart';
// import '../widgets/movimiento_form_dialog.dart';
import '../screens/sync_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/general_header.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Color(0xFF1A1C1E);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _scrollController.addListener(_onScroll);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final catProvider = context.read<CategoriaProvider>();
    final prodProvider = context.read<ProductoProvider>();
    await Future.wait([
      catProvider.fetchCategorias(),
      prodProvider.fetchProductos(),
    ]);
    _fadeController.forward();
  }

  void _onScroll() {
    final prodProvider = context.read<ProductoProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (prodProvider.hasMore && !prodProvider.isLoadingMore) {
        prodProvider.fetchMore();
      }
    }
  }

  Future<void> _openFormDialog({Producto? producto}) async {
    final prodProvider = context.read<ProductoProvider>();
    final catProvider = context.read<CategoriaProvider>();

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => ProductoFormDialog(
        producto: producto,
        productoProvider: prodProvider,
        categoriaProvider: catProvider,
      ),
    );

    if (result == true) {
      _showSnack(
        producto != null ? 'Producto actualizado' : 'Producto creado',
        isError: false,
      );
    }
  }

  Future<void> _confirmDelete(int id, String nombre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text(
          'Eliminar producto',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: Text(
          '¿Eliminar "$nombre"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await context.read<ProductoProvider>().deleteProducto(id);
      _showSnack(
        success ? 'Producto eliminado' : 'Error al eliminar',
        isError: !success,
      );
    }
  }

  Future<void> _openMovimientoDialog(int index) async {
    // final prodProvider = context.read<ProductoProvider>();
    // final movProvider = context.read<InventarioMovimientoProvider>();
    // final producto = prodProvider.productos[index];

    // final result = await showDialog<bool>(
    //   context: context,
    //   barrierColor: Colors.black.withValues(alpha: 0.7),
    //   builder: (_) => MovimientoFormDialog(
    //     producto: producto,
    //     movimientoProvider: movProvider,
    //   ),
    // );
    // if (result == true) {
    //   _showSnack('Movimiento registrado', isError: false);
    //   await prodProvider.fetchProductos(); // refresca el stock en pantalla
    // }
  }

  // Future<void> _openSyncScreen() async {
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const InventarioSyncScreen()),
  //   );
  //   // Al volver, refrescar inventario (puede haber cambios)
  //   if (mounted) {
  //     await context.read<ProductoProvider>().fetchProductos();
  //   }
  // }

  Future<void> _openPdf() async {
    final url = await context.read<ProductoProvider>().getPdfUrl();
    if (!mounted) return;
    if (url == null) {
      _showSnack('Error al generar PDF', isError: true);
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12.5)),
        backgroundColor: isError
            ? const Color(0xFFE31E24)
            : const Color(0xFF34A853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final catProvider = context.watch<CategoriaProvider>();
    final prodProvider = context.watch<ProductoProvider>();

    final crossAxisCount = MediaQuery.of(context).size.width > 1400
        ? 5
        : MediaQuery.of(context).size.width > 1100
        ? 4
        : MediaQuery.of(context).size.width > 700
        ? 3
        : 2;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header general
          GeneralHeader(
            title: 'Inventario de Productos',
            subtitle: '${prodProvider.total} productos registrados',
            icon: Icons.inventory_2_outlined,
          ),

          // Filter bar
          InventarioFilterBar(
            provider: prodProvider,
            categorias: catProvider.categorias,
            isAdmin: isAdmin,
            onApply: () => prodProvider.fetchProductos(),
            onAddProducto: isAdmin ? () => _openFormDialog() : null,
            // onSync: isAdmin ? _openSyncScreen : null,
            onPdf: _openPdf,
          ),

          // Grid content
          Expanded(child: _buildContent(prodProvider, crossAxisCount, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildContent(
    ProductoProvider prodProvider,
    int crossAxisCount,
    bool isAdmin,
  ) {
    if (prodProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE31E24),
          strokeWidth: 2,
        ),
      );
    }

    if (prodProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: const Color(0xFFE31E24).withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              prodProvider.error!,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => prodProvider.fetchProductos(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    if (prodProvider.productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 64,
            ),
            const SizedBox(height: 14),
            Text(
              'No hay productos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajusta los filtros o agrega un nuevo producto',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final displayProducts = List<Producto>.from(prodProvider.productos);

    displayProducts.sort((a, b) {
      final valA = DimensionParser.parse(a.medidas ?? a.descripcion);
      final valB = DimensionParser.parse(b.medidas ?? b.descripcion);
      if (valA != valB) {
        return valA.compareTo(valB);
      }
      return a.descripcion.compareTo(b.descripcion);
    });

    return FadeTransition(
      opacity: _fadeAnim,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(14),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount:
            displayProducts.length + (prodProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayProducts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Color(0xFFE31E24),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final producto = displayProducts[index];
          return ProductoGridCard(
            producto: producto,
            isAdmin: isAdmin,
            onEdit: isAdmin ? () => _openFormDialog(producto: producto) : null,
            onDelete: isAdmin
                ? () => _confirmDelete(producto.id!, producto.descripcion)
                : null,
            onMovimiento: () => _openMovimientoDialog(index),
          );
        },
      ),
    );
  }
}
