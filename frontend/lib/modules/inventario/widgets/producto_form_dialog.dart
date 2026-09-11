import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/http_service.dart';
import '../models/inventario_producto.dart';
import '../models/inventario_categoria.dart';
import '../providers/inventario_producto_provider.dart';
import '../providers/inventario_categoria_provider.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/auth_submit_button.dart';

class ProductoFormDialog extends StatefulWidget {
  final InventarioProducto? producto; // null = crear, non-null = editar
  final InventarioProductoProvider productoProvider;
  final InventarioCategoriaProvider categoriaProvider;

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
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _ventaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinCtrl;
  late final TextEditingController _stockMaxCtrl;

  String _unidad = 'UNIDAD';
  int? _categoriaId;
  bool _activo = true;
  bool _isLoading = false;
  String? _error;

  static const _accentRed = Color(0xFFE31E24);
  static const _dark = Color(0xFF1A1C1E);
  static const _card = Color(0xFF2C2F33);

  bool get _isEditing => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _codigoCtrl = TextEditingController(text: p?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _costoCtrl = TextEditingController(
      text: p != null ? p.costo.toStringAsFixed(2) : '',
    );
    _ventaCtrl = TextEditingController(
      text: p != null ? p.venta.toStringAsFixed(2) : '',
    );
    _stockCtrl = TextEditingController(
      text: p != null ? p.stock.toStringAsFixed(2) : '0',
    );
    _stockMinCtrl = TextEditingController(
      text: p?.stockMinimo?.toStringAsFixed(2) ?? '',
    );
    _stockMaxCtrl = TextEditingController(
      text: p?.stockMaximo?.toStringAsFixed(2) ?? '',
    );
    _unidad = p?.unidad ?? 'UNIDAD';
    _categoriaId = p?.categoriaId;
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _codigoCtrl,
      _nombreCtrl,
      _costoCtrl,
      _ventaCtrl,
      _stockCtrl,
      _stockMinCtrl,
      _stockMaxCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final producto = InventarioProducto(
      id: widget.producto?.id,
      codigo: _codigoCtrl.text.trim().toUpperCase(),
      nombre: _nombreCtrl.text.trim().toUpperCase(),
      unidad: _unidad,
      costo: double.tryParse(_costoCtrl.text) ?? 0,
      venta: double.tryParse(_ventaCtrl.text) ?? 0,
      stock: double.tryParse(_stockCtrl.text) ?? 0,
      stockMinimo: _stockMinCtrl.text.isNotEmpty
          ? double.tryParse(_stockMinCtrl.text)
          : null,
      stockMaximo: _stockMaxCtrl.text.isNotEmpty
          ? double.tryParse(_stockMaxCtrl.text)
          : null,
      categoriaId: _categoriaId,
      activo: _activo,
    );

    bool success;
    if (_isEditing) {
      success = await widget.productoProvider.updateProducto(producto);
    } else {
      success = await widget.productoProvider.createProducto(producto);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _error = widget.productoProvider.error ?? 'Error desconocido',
      );
    }
  }

  Future<void> _pickAndUploadImagen() async {
    if (widget.producto?.id == null) return;
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() => _isLoading = true);
    await widget.productoProvider.uploadImagen(
      widget.producto!.id!,
      bytes,
      file.name,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteImagen() async {
    if (widget.producto?.id == null) return;
    setState(() => _isLoading = true);
    await widget.productoProvider.deleteImagen(widget.producto!.id!);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final categorias = widget.categoriaProvider.categorias;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _card.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: _accentRed,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Editar Producto' : 'Nuevo Producto',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) _errorBanner(),

                      // Imagen (solo edición)
                      if (_isEditing) _buildImageSection(),

                      _sectionTitle('Datos del Producto'),
                      const SizedBox(height: 10),

                      // Fila: Código + Unidad
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _codigoCtrl,
                              hintText: 'Código único',
                              prefixIcon: Icons.qr_code,
                              accentColor: _accentRed,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _unidadDropdown(),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Nombre
                      AuthTextField(
                        controller: _nombreCtrl,
                        hintText: 'Nombre del producto',
                        prefixIcon: Icons.label_outline,
                        accentColor: _accentRed,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // Categoría
                      _categoriaDropdown(categorias),
                      const SizedBox(height: 14),

                      _sectionTitle('Precios'),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _costoCtrl,
                              hintText: 'Costo',
                              prefixIcon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              accentColor: _accentRed,
                              validator: (v) =>
                                  (v == null || double.tryParse(v) == null)
                                  ? 'Número válido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AuthTextField(
                              controller: _ventaCtrl,
                              hintText: 'Precio de venta',
                              prefixIcon: Icons.sell_outlined,
                              keyboardType: TextInputType.number,
                              accentColor: _accentRed,
                              validator: (v) =>
                                  (v == null || double.tryParse(v) == null)
                                  ? 'Número válido'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _sectionTitle('Stock'),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _stockCtrl,
                              hintText: 'Stock actual',
                              prefixIcon: Icons.inventory_outlined,
                              keyboardType: TextInputType.number,
                              accentColor: _accentRed,
                              validator: (v) =>
                                  (v == null || double.tryParse(v) == null)
                                  ? 'Número'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AuthTextField(
                              controller: _stockMinCtrl,
                              hintText: 'Stock mínimo',
                              prefixIcon: Icons.warning_amber_outlined,
                              keyboardType: TextInputType.number,
                              accentColor: _accentRed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AuthTextField(
                              controller: _stockMaxCtrl,
                              hintText: 'Stock máximo',
                              prefixIcon: Icons.arrow_upward,
                              keyboardType: TextInputType.number,
                              accentColor: _accentRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Activo switch
                      Row(
                        children: [
                          Switch(
                            value: _activo,
                            onChanged: (v) => setState(() => _activo = v),
                            activeColor: _accentRed,
                            trackColor: WidgetStateProperty.resolveWith(
                              (s) => s.contains(WidgetState.selected)
                                  ? _accentRed.withValues(alpha: 0.3)
                                  : Colors.white12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activo ? 'Producto activo' : 'Producto inactivo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Submit
                      AuthSubmitButton(
                        text: _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR PRODUCTO',
                        isLoading: _isLoading,
                        onPressed: _submit,
                        backgroundColor: _accentRed,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final prod = widget.productoProvider.productos.firstWhere(
      (p) => p.id == widget.producto?.id,
      orElse: () => widget.producto!,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: prod.imagenUrl != null
                  ? Image.network(
                      prod.imagenUrl!,
                      fit: BoxFit.cover,
                      headers: {'Authorization': 'Bearer ${HttpService.token}'},
                    )
                  : Container(
                      color: const Color(0xFF1A1C1E),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white24,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Imagen del producto',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'JPEG comprimido • máx 1.5MB',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _imgActionBtn(
                    Icons.upload_outlined,
                    'Subir',
                    _pickAndUploadImagen,
                  ),
                  if (prod.imagenUrl != null) ...[
                    const SizedBox(width: 8),
                    _imgActionBtn(
                      Icons.delete_outline,
                      'Eliminar',
                      _deleteImagen,
                      color: _accentRed,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgActionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? Colors.white54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: c, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accentRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _unidadDropdown() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unidad,
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
          icon: const Icon(Icons.expand_more, color: Colors.white38, size: 16),
          isDense: true,
          items: [
            'UNIDAD',
            'LIBRA',
            'KG',
            'OTRO',
          ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (v) => setState(() => _unidad = v ?? 'UNIDAD'),
        ),
      ),
    );
  }

  Widget _categoriaDropdown(List<InventarioCategoria> categorias) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categoriaId,
          hint: Text(
            'Seleccionar categoría',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12.5,
            ),
          ),
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
          icon: const Icon(Icons.expand_more, color: Colors.white38, size: 16),
          isDense: true,
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Sin categoría'),
            ),
            ...categorias.map(
              (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
            ),
          ],
          onChanged: (v) => setState(() => _categoriaId = v),
        ),
      ),
    );
  }
}
