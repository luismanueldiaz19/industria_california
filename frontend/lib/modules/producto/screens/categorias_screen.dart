import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/http_service.dart';
import '../../../core/widgets/general_header.dart';
import '../models/categoria.dart';
import '../providers/categoria_provider.dart';
import 'categoria_productos_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  static const _dark = Color(0xFF1A1C1E);
  static const _accentRed = Color(0xFFE31E24);
  static const _cardColor = Color(0xFF2C2F33);

  String _search = '';
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      Future.microtask(() {
        if (mounted) {
          context.read<CategoriaProvider>().fetchCategorias(soloActivas: false);
        }
      });
      _isInit = true;
    }
  }

  void _showFormDialog([Categoria? categoria]) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoriaFormDialog(categoria: categoria),
    );
  }

  Future<void> _confirmDelete(int id, String nombre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text(
          'Eliminar Categoría',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Desea eliminar la categoría "$nombre"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<CategoriaProvider>().deleteCategoria(id);
      if (mounted) {
        context.read<CategoriaProvider>().fetchCategorias(soloActivas: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GeneralHeader(
          title: 'Categorías',
          subtitle: 'Listado de categorías',
          icon: Icons.category,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar categoría...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: _dark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  'NUEVA CATEGORÍA',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<CategoriaProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.categorias.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _accentRed),
                );
              }

              final filtradas = provider.categorias
                  .where(
                    (c) =>
                        c.nombre.toLowerCase().contains(_search.toLowerCase()),
                  )
                  .toList();

              if (filtradas.isEmpty) {
                return Center(
                  child: Text(
                    'No se encontraron categorías',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filtradas.length,
                itemBuilder: (ctx, i) {
                  final cat = filtradas[i];
                  return Card(
                    color: _cardColor,
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CategoriaProductosScreen(categoria: cat),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: cat.imagenUrl != null
                                ? Image.network(
                                    cat.imagenUrl!,
                                    headers: {
                                      'Authorization':
                                          'Bearer ${HttpService.token}',
                                    },
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.white54,
                                        ),
                                  )
                                : const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.white24,
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: _dark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _showFormDialog(cat),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: _accentRed,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _confirmDelete(cat.id!, cat.nombre),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoriaFormDialog extends StatefulWidget {
  final Categoria? categoria;
  const _CategoriaFormDialog({this.categoria});

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  PlatformFile? _imagenSeleccionada;
  List<int>? _imagenBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.categoria?.nombre ?? '');
  }

  Future<void> _seleccionarImagen() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imagenSeleccionada = file;
        _imagenBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final cat = Categoria(
      id: widget.categoria?.id,
      nombre: _nombreCtrl.text.trim().toUpperCase(),
    );

    final prov = context.read<CategoriaProvider>();
    bool success;
    if (widget.categoria != null) {
      success = await prov.updateCategoria(
        cat,
        imageBytes: _imagenBytes,
        imageName: _imagenSeleccionada?.name,
      );
    } else {
      success = await prov.createCategoria(
        cat,
        imageBytes: _imagenBytes,
        imageName: _imagenSeleccionada?.name,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        prov.fetchCategorias(soloActivas: false);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.error ?? 'Ocurrió un error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.categoria != null
                    ? 'Editar Categoría'
                    : 'Nueva Categoría',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Selector de Imagen
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: _imagenBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            Uint8List.fromList(_imagenBytes!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : (widget.categoria?.imagenUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.categoria!.imagenUrl!,

                                  fit: BoxFit.cover,
                                  headers: {
                                    'Authorization':
                                        'Bearer ${HttpService.token}',
                                  },
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Subir Imagen',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1A1C1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Guardar',
                            style: TextStyle(color: Colors.white),
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
