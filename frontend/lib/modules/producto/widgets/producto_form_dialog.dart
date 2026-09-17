import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/http_service.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../providers/producto_provider.dart';
import '../providers/categoria_provider.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/auth_submit_button.dart';

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
  late final TextEditingController _descripcionCtrl;
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
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _categoriaId = p?.categoriaId;
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      setState(() => _error = 'Debes seleccionar una categoría');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final producto = Producto(
      id: widget.producto?.id,
      descripcion: _descripcionCtrl.text.trim().toUpperCase(),
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
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _card.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: _accentRed, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Editar Producto Padre' : 'Nuevo Producto Padre',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white38, size: 18),
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
                      if (_isEditing) _buildImageSection(),

                      _sectionTitle('Datos del Producto Agrupador'),
                      const SizedBox(height: 10),

                      AuthTextField(
                        controller: _descripcionCtrl,
                        hintText: 'Descripción General (Ej. Tubos PVC)',
                        prefixIcon: Icons.label_outline,
                        accentColor: _accentRed,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),

                      _categoriaDropdown(categorias),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Switch(
                            value: _activo,
                            onChanged: (v) => setState(() => _activo = v),
                            activeColor: _accentRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      AuthSubmitButton(
                        text: _isEditing ? 'GUARDAR' : 'CREAR',
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
      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11.5)),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: prod.imagenUrl != null
                  ? Image.network(prod.imagenUrl!, fit: BoxFit.cover, headers: {'Authorization': 'Bearer ${HttpService.token}'})
                  : const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Imagen del producto', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Row(
                children: [
                  TextButton(onPressed: _pickAndUploadImagen, child: const Text('Subir')),
                  if (prod.imagenUrl != null) TextButton(onPressed: _deleteImagen, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: _accentRed),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _categoriaDropdown(List<Categoria> categorias) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(9)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categoriaId,
          hint: const Text('Seleccionar categoría', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
          isExpanded: true,
          items: categorias.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre))).toList(),
          onChanged: (v) => setState(() => _categoriaId = v),
        ),
      ),
    );
  }
}
