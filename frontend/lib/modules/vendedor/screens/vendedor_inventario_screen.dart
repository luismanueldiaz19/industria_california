import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../producto/providers/producto_provider.dart';
import '../../producto/providers/categoria_provider.dart';
import '../../producto/models/producto.dart';
import '../widgets/vendedor_producto_card.dart';
import '../../../core/utils/dimension_parser.dart';

class VendedorInventarioScreen extends StatefulWidget {
  const VendedorInventarioScreen({super.key});

  @override
  State<VendedorInventarioScreen> createState() =>
      _VendedorInventarioScreenState();
}

class _VendedorInventarioScreenState extends State<VendedorInventarioScreen> {
  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);

  String _searchQuery = '';
  int? _selectedCategoriaId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ProductoProvider>();
      if (prov.productos.isEmpty) {
        prov.fetchProductos();
      }
      final catProv = context.read<CategoriaProvider>();
      if (catProv.categorias.isEmpty) {
        catProv.fetchCategorias();
      }
    });
  }

  List<Producto> get _productosFiltrados {
    final prods = context.watch<ProductoProvider>().productos;
    final filtered = prods.where((p) {
      if (!p.activo) return false;

      final matchesSearch =
          _searchQuery.isEmpty ||
          p.descripcion.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.codigo ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCat =
          _selectedCategoriaId == null || p.categoriaId == _selectedCategoriaId;

      return matchesSearch && matchesCat;
    }).toList();

    filtered.sort((a, b) {
      final valA = DimensionParser.parse(a.medidas ?? a.descripcion);
      final valB = DimensionParser.parse(b.medidas ?? b.descripcion);
      if (valA != valB) {
        return valA.compareTo(valB);
      }
      return a.descripcion.compareTo(b.descripcion);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTopBar(),
        Expanded(child: _buildGrid()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primaryBlue,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: const Text(
        'Catálogo de Productos',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final totalProductos = context.watch<ProductoProvider>().productos.length;
    final mostrando = _productosFiltrados.length;
    final categorias = context.watch<CategoriaProvider>().categorias;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Búsqueda
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: TextStyle(fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de Categorías Horizontal
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoriaItem(null, 'Todas', null);
                }
                final cat = categorias[index - 1];
                return _buildCategoriaItem(cat.id, cat.nombre, cat.imagenUrl);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Mostrando $mostrando de $totalProductos disponibles',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  context.read<ProductoProvider>().fetchProductos();
                  context.read<CategoriaProvider>().fetchCategorias();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategoriaId = null;
                    _searchController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh,
                        size: 14,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Actualizar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaItem(int? id, String nombre, String? imagenUrl) {
    final isSelected = _selectedCategoriaId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoriaId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryBlue : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: imagenUrl != null
                  ? Image.network(
                      imagenUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.category,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 20,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              nombre,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        maxCrossAxisExtent: 220,
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
