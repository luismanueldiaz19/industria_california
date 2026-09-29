import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import '../../producto/providers/producto_provider.dart';
import '../../producto/providers/categoria_provider.dart';
import '../../producto/models/producto.dart';
import '../widgets/vendedor_producto_card.dart';
import '../../../core/utils/dimension_parser.dart';
import '../../producto/widgets/filter_bar.dart';
import '../../../core/utils/grid_utils.dart';

class VendedorInventarioScreen extends StatefulWidget {
  const VendedorInventarioScreen({super.key});

  @override
  State<VendedorInventarioScreen> createState() =>
      _VendedorInventarioScreenState();
}

class _VendedorInventarioScreenState extends State<VendedorInventarioScreen> {
  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ProductoProvider>();

      // Limpiar filtros y pedir inventario nuevo siempre que se entra
      prov.clearFiltros();
      prov.fetchProductos();

      final catProv = context.read<CategoriaProvider>();
      if (catProv.categorias.isEmpty) {
        catProv.fetchCategorias();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoriaProvider>();
    final prodProvider = context.watch<ProductoProvider>();
    final crossAxisCount = GridUtils.getCrossAxisCount(context);

    return Column(
      children: [
        _buildHeader(prodProvider),
        InventarioFilterBar(
          provider: prodProvider,
          categorias: catProvider.categorias,
          isAdmin: false,
          onApply: () {
            // Refrescar la pantalla localmente sin llamar al backend en cada tecla
            setState(() {});
          },
        ),
        Expanded(child: _buildGrid(prodProvider, crossAxisCount)),
      ],
    );
  }

  Widget _buildHeader(ProductoProvider prodProvider) {
    return GeneralHeader(
      title: 'Catálogo de Productos',
      subtitle: '${prodProvider.total} productos registrados',
      icon: Icons.inventory,
      iconColor: Colors.blue,
      gradientColors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
      actions: [
        HeaderButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Actualizar',
          onTap: () {
            context.read<ProductoProvider>().clearFiltros();
            context.read<ProductoProvider>().fetchProductos();
            context.read<CategoriaProvider>().fetchCategorias();
          },
        ),
      ],
    );

    // Container(
    //   color: _primaryBlue,
    //   width: double.infinity,
    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    //   child: const Text(
    //     'Catálogo de Productos',
    //     style: TextStyle(
    //       color: Colors.white,
    //       fontSize: 18,
    //       fontWeight: FontWeight.bold,
    //     ),
    //   ),
    // );
  }

  Widget _buildGrid(ProductoProvider prodProvider, int crossAxisCount) {
    if (prodProvider.isLoading && prodProvider.productos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE31E24),
          strokeWidth: 2,
        ),
      );
    }

    if (prodProvider.error != null && prodProvider.productos.isEmpty) {
      return Center(child: Text(prodProvider.error!));
    }

    final searchLower = prodProvider.search.toLowerCase();
    final catId = prodProvider.categoriaId;
    final soloNegativos = prodProvider.soloNegativos;

    final filtrados = prodProvider.productos.where((p) {
      if (!p.activo) return false;

      // Filtro de categoría
      if (catId != null && p.categoriaId != catId) return false;

      // Filtro de Agotados
      if (soloNegativos && p.stock > 0) return false;

      // Búsqueda libre
      if (searchLower.isNotEmpty) {
        final terms = searchLower.split(' ');
        final nombreLocal = p.nombreCompleto.toLowerCase();
        final codLocal = (p.codigo ?? '').toLowerCase();

        for (final term in terms) {
          if (term.isEmpty) continue;
          if (!nombreLocal.contains(term) && !codLocal.contains(term)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    filtrados.sort((a, b) {
      final valA = DimensionParser.parse(a.medidas ?? a.descripcion);
      final valB = DimensionParser.parse(b.medidas ?? b.descripcion);
      if (valA != valB) {
        return valA.compareTo(valB);
      }
      return a.descripcion.compareTo(b.descripcion);
    });

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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: filtrados.length,
      itemBuilder: (ctx, i) =>
          VendedorProductoCard(producto: filtrados[i], isReadOnly: true),
    );
  }
}
