import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../providers/producto_provider.dart';
import '../providers/categoria_provider.dart';

class ProductoFormDialog extends StatefulWidget {
  final Producto? producto;
  final ProductoProvider productoProvider;
  final CategoriaProvider categoriaProvider;

  const ProductoFormDialog({
    super.key,
    this.producto,
    required this.productoProvider,
    required this.categoriaProvider,
  });

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Controllers
  late TextEditingController _codigoCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _medidasCtrl;
  late TextEditingController _capacidadCtrl;
  late TextEditingController _unidadCtrl;
  late TextEditingController _cantPaqueteCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _costoCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _stockMinCtrl;
  late TextEditingController _stockMaxCtrl;

  int? _selectedCategoriaId;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;

    _codigoCtrl = TextEditingController(text: p?.codigo ?? '');
    _descCtrl = TextEditingController(text: p?.descripcion ?? '');
    _medidasCtrl = TextEditingController(text: p?.medidas ?? '');
    _capacidadCtrl = TextEditingController(text: p?.capacidad ?? '');
    _unidadCtrl = TextEditingController(text: p?.unidad ?? 'UNIDAD');
    _cantPaqueteCtrl = TextEditingController(
      text: p?.cantXPackages?.toString() ?? '',
    );
    _precioCtrl = TextEditingController(text: p?.precio.toString() ?? '0.0');
    _costoCtrl = TextEditingController(text: p?.costo.toString() ?? '0.0');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0.0');
    _stockMinCtrl = TextEditingController(
      text: p?.stockMinimo?.toString() ?? '',
    );
    _stockMaxCtrl = TextEditingController(
      text: p?.stockMaximo?.toString() ?? '',
    );

    _selectedCategoriaId = p?.categoriaId;
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descCtrl.dispose();
    _medidasCtrl.dispose();
    _capacidadCtrl.dispose();
    _unidadCtrl.dispose();
    _cantPaqueteCtrl.dispose();
    _precioCtrl.dispose();
    _costoCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    _stockMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoriaId == null) {
      _showError('Seleccione una categoría');
      return;
    }

    setState(() => _isLoading = true);

    final productoData = Producto(
      id: widget.producto?.id,
      codigo: _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      categoriaId: _selectedCategoriaId,
      medidas: _medidasCtrl.text.trim().isEmpty
          ? null
          : _medidasCtrl.text.trim(),
      capacidad: _capacidadCtrl.text.trim().isEmpty
          ? null
          : _capacidadCtrl.text.trim(),
      unidad: _unidadCtrl.text.trim().isEmpty
          ? 'UNIDAD'
          : _unidadCtrl.text.trim().toUpperCase(),
      cantXPackages: int.tryParse(_cantPaqueteCtrl.text),
      precio: double.tryParse(_precioCtrl.text) ?? 0,
      costo: double.tryParse(_costoCtrl.text) ?? 0,
      stock: double.tryParse(_stockCtrl.text) ?? 0,
      stockMinimo: double.tryParse(_stockMinCtrl.text),
      stockMaximo: double.tryParse(_stockMaxCtrl.text),
      activo: _activo,
    );

    bool success;
    if (widget.producto == null) {
      success = await widget.productoProvider.createProducto(productoData);
    } else {
      success = await widget.productoProvider.updateProducto(productoData);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      _showError(widget.productoProvider.error ?? 'Error al guardar');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE31E24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producto != null;
    final categorias = widget.categoriaProvider.categorias;

    return Dialog(
      backgroundColor: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(isEditing),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE31E24),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Información Básica'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    controller: _descCtrl,
                                    label: 'Descripción (Nombre)*',
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller: _codigoCtrl,
                                    label: 'Código (Opcional)',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCategoryDropdown(categorias),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _medidasCtrl,
                                    label: 'Medidas (Ej. 1/2 X 90)',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _capacidadCtrl,
                                    label: 'Capacidad (Ej. Presión)',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            _buildSectionTitle('Empaque y Precios'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _unidadCtrl,
                                    label: 'Unidad de medida',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _cantPaqueteCtrl,
                                    label: 'Cant. por paquete',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _costoCtrl,
                                    label: 'Costo',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _precioCtrl,
                                    label: 'Precio de venta*',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            _buildSectionTitle('Inventario y Stock'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stockCtrl,
                                    label: 'Stock Actual',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stockMinCtrl,
                                    label: 'Stock Mínimo (Alerta)',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stockMaxCtrl,
                                    label: 'Stock Máximo',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            SwitchListTile(
                              title: const Text(
                                'Producto Activo',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: const Text(
                                'Si está inactivo, no se mostrará en ventas',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              value: _activo,
                              activeColor: const Color(0xFFE31E24),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _activo = v),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFFE31E24),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Editar Producto' : 'Nuevo Producto',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1C1E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Guardar Producto',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFE31E24),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE31E24), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Categoria> categorias) {
    return DropdownButtonFormField<int>(
      value: _selectedCategoriaId,
      dropdownColor: const Color(0xFF2C2F33),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Categoría*',
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE31E24), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: categorias.map((cat) {
        return DropdownMenuItem<int>(value: cat.id, child: Text(cat.nombre));
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedCategoriaId = val;
        });
      },
      validator: (v) => v == null ? 'Seleccione categoría' : null,
    );
  }
}
