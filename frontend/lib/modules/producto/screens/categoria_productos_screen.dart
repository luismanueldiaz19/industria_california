import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/categoria.dart';
import '../providers/producto_provider.dart';
import '../widgets/producto_grid_card.dart';
import '../../../core/widgets/general_header.dart';
import '../../../core/services/http_service.dart';

class CategoriaProductosScreen extends StatefulWidget {
  final Categoria categoria;
  
  const CategoriaProductosScreen({super.key, required this.categoria});

  @override
  State<CategoriaProductosScreen> createState() => _CategoriaProductosScreenState();
}

class _CategoriaProductosScreenState extends State<CategoriaProductosScreen> {
  static const _accentRed = Color(0xFFE31E24);
  bool _isInit = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      Future.microtask(() {
        if (mounted) {
          final prodProvider = context.read<ProductoProvider>();
          prodProvider.clearFiltros();
          prodProvider.setFiltros(categoriaId: widget.categoria.id);
          prodProvider.fetchProductos();
        }
      });
      _isInit = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final prodProvider = context.read<ProductoProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (prodProvider.hasMore && !prodProvider.isLoadingMore) {
        prodProvider.fetchMore();
      }
    }
  }

  Future<void> _importarExcel() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx', 'csv'],
    );
    
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      final prov = context.read<ProductoProvider>();
      final result = await prov.importExcelPorCategoria(widget.categoria.id!, bytes, file.name);
      
      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Productos importados exitosamente'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${prov.error ?? 'Ocurrió un error'}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141517),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          GeneralHeader(
            title: 'Productos: ${widget.categoria.nombre}',
            subtitle: 'Catálogo de productos de esta categoría',
            icon: Icons.inventory_2_outlined,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _importarExcel,
                  icon: const Icon(Icons.upload_file, size: 18, color: Colors.white),
                  label: const Text(
                    'IMPORTAR EXCEL',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.productos.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: _accentRed));
                }

                if (provider.productos.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay productos en esta categoría',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: provider.productos.length + (provider.isLoadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.productos.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: _accentRed),
                        ),
                      );
                    }
                    final prod = provider.productos[i];
                    return ProductoGridCard(
                      producto: prod,
                      onEdit: () {}, 
                      onDelete: () {},
                      onMovimiento: () {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
