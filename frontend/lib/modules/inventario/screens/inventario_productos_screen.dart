import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/inventario_producto_provider.dart';
import '../providers/inventario_categoria_provider.dart';
import '../providers/inventario_movimiento_provider.dart';
import '../widgets/inventario_filter_bar.dart';
import '../widgets/producto_grid_card.dart';
import '../widgets/producto_form_dialog.dart';
import '../widgets/movimiento_form_dialog.dart';
import '../../../core/auth_provider.dart';
import '../../../widgets/general_header.dart';

class InventarioProductosScreen extends StatefulWidget {
  const InventarioProductosScreen({super.key});

  @override
  State<InventarioProductosScreen> createState() =>
      _InventarioProductosScreenState();
}

class _InventarioProductosScreenState extends State<InventarioProductosScreen>
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
    final catProvider = context.read<InventarioCategoriaProvider>();
    final prodProvider = context.read<InventarioProductoProvider>();
    await Future.wait([
      catProvider.fetchCategorias(),
      prodProvider.fetchProductos(),
    ]);
    _fadeController.forward();
  }

  void _onScroll() {
    final prodProvider = context.read<InventarioProductoProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (prodProvider.hasMore && !prodProvider.isLoadingMore) {
        prodProvider.fetchMore();
      }
    }
  }

  Future<void> _openFormDialog({bool edit = false, int? index}) async {
    final prodProvider = context.read<InventarioProductoProvider>();
    final catProvider = context.read<InventarioCategoriaProvider>();

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => ProductoFormDialog(
        producto: edit && index != null ? prodProvider.productos[index] : null,
        productoProvider: prodProvider,
        categoriaProvider: catProvider,
      ),
    );
    if (result == true) {
      _showSnack(
        edit ? 'Producto actualizado' : 'Producto creado',
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
      final success = await context
          .read<InventarioProductoProvider>()
          .deleteProducto(id);
      _showSnack(
        success ? 'Producto eliminado' : 'Error al eliminar',
        isError: !success,
      );
    }
  }

  Future<void> _openMovimientoDialog(int index) async {
    final prodProvider = context.read<InventarioProductoProvider>();
    final movProvider = context.read<InventarioMovimientoProvider>();
    final producto = prodProvider.productos[index];

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => MovimientoFormDialog(
        producto: producto,
        movimientoProvider: movProvider,
      ),
    );
    if (result == true) {
      _showSnack('Movimiento registrado', isError: false);
      await prodProvider.fetchProductos(); // refresca el stock en pantalla
    }
  }

  Widget _buildFormatRow(String col, String desc, {required bool isRequired}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              col,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: isRequired
                    ? const Color(0xFFE31E24).withValues(alpha: 0.4)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(4),
              color: isRequired
                  ? const Color(0xFFE31E24).withValues(alpha: 0.04)
                  : Colors.transparent,
            ),
            child: Text(
              isRequired ? 'Obligatorio' : 'Opcional',
              style: TextStyle(
                fontSize: 10,
                color: isRequired
                    ? const Color(0xFFE31E24)
                    : Colors.grey.shade600,
                fontWeight: isRequired ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importExcel() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        elevation: 24,
        shadowColor: Colors.black26,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      color: Colors.grey.shade800,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Formato de Importación',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 20),
                Text(
                  'El archivo Excel (o CSV) debe seguir estrictamente el siguiente orden de columnas. La primera fila se ignorará (encabezados).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFormatRow(
                        'Columna A',
                        'Código de Producto',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna B',
                        'Nombre / Descripción',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna C',
                        'ID de Categoría (Número)',
                        isRequired: false,
                      ),
                      _buildFormatRow('Columna D', 'Costo', isRequired: false),
                      _buildFormatRow(
                        'Columna E',
                        'Precio de Venta',
                        isRequired: false,
                      ),
                      _buildFormatRow(
                        'Columna F',
                        'Stock Inicial',
                        isRequired: false,
                      ),
                      _buildFormatRow(
                        'Columna G',
                        'Stock Mínimo',
                        isRequired: false,
                      ),
                      _buildFormatRow(
                        'Columna H',
                        'Stock Máximo',
                        isRequired: false,
                      ),
                      _buildFormatRow(
                        'Columna I',
                        'Unidad (UNIDAD, LIBRA, KG)',
                        isRequired: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1A1A1A,
                        ), // Classic premium black
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    // Mostrar un Snackbar de carga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Importando productos...', style: TextStyle(fontSize: 12.5)),
          ],
        ),
        backgroundColor: const Color(0xFF1A73E8), // Blue para loading
        duration: const Duration(
          seconds: 10,
        ), // Duración larga, se sobrescribirá
      ),
    );

    final success = await context
        .read<InventarioProductoProvider>()
        .importExcel(bytes, file.name);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Ocultar el loading

    _showSnack(
      success ? 'Importación exitosa' : 'Error en importación',
      isError: !success,
    );
  }

  Future<void> _openPdf() async {
    final url = await context.read<InventarioProductoProvider>().getPdfUrl();
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
    final catProvider = context.watch<InventarioCategoriaProvider>();
    final prodProvider = context.watch<InventarioProductoProvider>();

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
            onImport: isAdmin ? _importExcel : null,
            onPdf: _openPdf,
          ),

          // Grid content
          Expanded(child: _buildContent(prodProvider, crossAxisCount, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildContent(
    InventarioProductoProvider prodProvider,
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

    return FadeTransition(
      opacity: _fadeAnim,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(14),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount:
            prodProvider.productos.length +
            (prodProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= prodProvider.productos.length) {
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

          final producto = prodProvider.productos[index];
          return ProductoGridCard(
            producto: producto,
            isAdmin: isAdmin,
            onEdit: isAdmin
                ? () => _openFormDialog(edit: true, index: index)
                : null,
            onDelete: isAdmin
                ? () => _confirmDelete(producto.id!, producto.nombre)
                : null,
            onMovimiento: () => _openMovimientoDialog(index),
          );
        },
      ),
    );
  }
}
