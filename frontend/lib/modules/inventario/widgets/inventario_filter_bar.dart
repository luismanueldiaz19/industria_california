import 'package:flutter/material.dart';
import '../models/inventario_categoria.dart';
import '../providers/inventario_producto_provider.dart';

class InventarioFilterBar extends StatefulWidget {
  final InventarioProductoProvider provider;
  final List<InventarioCategoria> categorias;
  final VoidCallback onApply;
  final VoidCallback? onAddProducto;
  final VoidCallback? onImport;
  final VoidCallback? onPdf;
  final bool isAdmin;

  const InventarioFilterBar({
    super.key,
    required this.provider,
    required this.categorias,
    required this.onApply,
    this.onAddProducto,
    this.onImport,
    this.onPdf,
    this.isAdmin = false,
  });

  @override
  State<InventarioFilterBar> createState() => _InventarioFilterBarState();
}

class _InventarioFilterBarState extends State<InventarioFilterBar> {
  final _searchController = TextEditingController();
  int? _selectedCategoriaId;
  String _estadoStock = '';
  String _orderBy = 'nombre';
  String _orderDir = 'asc';

  static const _dark = Color(0xFF1A1C1E);
  static const _card = Color(0xFF2C2F33);
  static const _red = Color(0xFFE31E24);

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.provider.search;
    _selectedCategoriaId = widget.provider.categoriaId;
    _estadoStock = widget.provider.estadoStock;
    _orderBy = widget.provider.orderBy;
    _orderDir = widget.provider.orderDir;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.provider.setFiltros(
      search: _searchController.text.trim(),
      categoriaId: _selectedCategoriaId,
      estadoStock: _estadoStock,
      orderBy: _orderBy,
      orderDir: _orderDir,
    );
    widget.onApply();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoriaId = null;
      _estadoStock = '';
      _orderBy = 'nombre';
      _orderDir = 'asc';
    });
    widget.provider.clearFiltros();
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _dark,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Barra de búsqueda
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar código o nombre...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                filled: true,
                fillColor: _card.withValues(alpha: 0.7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _red, width: 1.2),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),

          // Filtro categoría
          _buildDropdown<int?>(
            value: _selectedCategoriaId,
            hint: 'Categoría',
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
              ...widget.categorias.map(
                (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
              ),
            ],
            onChanged: (v) {
              setState(() => _selectedCategoriaId = v);
              _applyFilters();
            },
          ),

          // Filtro estado stock
          _buildDropdown<String>(
            value: _estadoStock,
            hint: 'Estado',
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos')),
              DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
              DropdownMenuItem(value: 'alerta', child: Text('En alerta')),
              DropdownMenuItem(value: 'agotado', child: Text('Agotado')),
              DropdownMenuItem(value: 'negativo', child: Text('Negativos')),
            ],
            onChanged: (v) {
              setState(() => _estadoStock = v ?? '');
              _applyFilters();
            },
          ),

          // Order by
          _buildDropdown<String>(
            value: _orderBy,
            hint: 'Ordenar',
            items: const [
              DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
              DropdownMenuItem(value: 'codigo', child: Text('Código')),
              DropdownMenuItem(value: 'stock', child: Text('Stock')),
              DropdownMenuItem(value: 'costo', child: Text('Costo')),
              DropdownMenuItem(value: 'venta', child: Text('Venta')),
            ],
            onChanged: (v) {
              setState(() => _orderBy = v ?? 'nombre');
              _applyFilters();
            },
          ),

          // Order dir toggle
          _orderDirButton(),

          // Botón aplicar
          _actionButton(
            icon: Icons.filter_list,
            label: 'Aplicar',
            color: _red,
            onTap: _applyFilters,
          ),

          // Botón limpiar
          _actionButton(
            icon: Icons.clear,
            label: 'Limpiar',
            color: Colors.white38,
            onTap: _clearFilters,
          ),

          const SizedBox(width: 4),

          // Acciones admin
          if (widget.isAdmin) ...[
            _actionButton(
              icon: Icons.add,
              label: 'Agregar',
              color: const Color(0xFF34A853),
              onTap: widget.onAddProducto,
            ),
            _actionButton(
              icon: Icons.upload_file,
              label: 'Importar',
              color: const Color(0xFF1A73E8),
              onTap: widget.onImport,
            ),
          ],

          // PDF
          _actionButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            color: Colors.orange.shade400,
            onTap: widget.onPdf,
          ),

          // Total counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.provider.total} productos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 16),
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _orderDirButton() {
    return InkWell(
      onTap: () {
        setState(() => _orderDir = _orderDir == 'asc' ? 'desc' : 'asc');
        _applyFilters();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: _card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _orderDir == 'asc' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: Colors.white54,
          size: 16,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
