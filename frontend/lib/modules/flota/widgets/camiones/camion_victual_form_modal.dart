import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';
import '../../../flota/providers/chofer_provider.dart';
import '../../../users/providers/users_provider.dart';

class CamionVictualFormModal extends StatefulWidget {
  final CamionVictual? camion;

  const CamionVictualFormModal({super.key, this.camion});

  @override
  State<CamionVictualFormModal> createState() => _CamionVictualFormModalState();
}

class _CamionVictualFormModalState extends State<CamionVictualFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _notasController;
  late TextEditingController _minimoSalidaController;

  int? _selectedChoferId;
  int? _selectedVendedorId;
  String _estado = 'vacio';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.camion?.nombre ?? '',
    );
    _notasController = TextEditingController(text: widget.camion?.notas ?? '');
    _minimoSalidaController = TextEditingController(
      text: widget.camion?.minimoSalida.toString() ?? '5000',
    );

    if (widget.camion != null) {
      _selectedChoferId = widget.camion!.choferID == 0
          ? null
          : widget.camion!.choferID;
      _selectedVendedorId = widget.camion!.vendedorId == 0
          ? null
          : widget.camion!.vendedorId;
      _estado = widget.camion!.estado;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoferProvider>().fetchChoferes();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _notasController.dispose();
    _minimoSalidaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChoferId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un chofer')));
      return;
    }
    if (_selectedVendedorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un vendedor')));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'nombre': _nombreController.text.trim(),
      'notas': _notasController.text.trim(),
      'minimo_salida': _minimoSalidaController.text.trim(),
      'chofer_id': _selectedChoferId,
      'vendedor_id': _selectedVendedorId,
      'estado': _estado,
    };

    try {
      if (widget.camion == null) {
        await context.read<CamionVictualProvider>().create(data);
      } else {
        await context.read<CamionVictualProvider>().update(
          widget.camion!.id,
          data,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.camion == null
                  ? 'Camión creado correctamente'
                  : 'Camión actualizado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.camion != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar Camión' : 'Añadir Camión',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre del Camión',
                icon: Icons.local_shipping,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _minimoSalidaController,
                label: 'Mínimo de Salida (\$)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              Consumer<ChoferProvider>(
                builder: (context, choferProvider, child) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedChoferId,
                    dropdownColor: const Color(0xFF3B3E43),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Chofer Asignado',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white54,
                      ),
                    ),
                    items: choferProvider.choferes.map((chofer) {
                      return DropdownMenuItem<int>(
                        value: chofer.id,
                        child: Text(chofer.name ?? 'Chofer ${chofer.id}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedChoferId = v),
                  );
                },
              ),

              const SizedBox(height: 16),

              Consumer<UsersProvider>(
                builder: (context, usersProvider, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedVendedorId,
                    dropdownColor: const Color(0xFF3B3E43),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Vendedor Responsable',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.storefront,
                        color: Colors.white54,
                      ),
                    ),
                    items: usersProvider.users.where((user) {
                      final roles = user['roles'];
                      if (roles == null || roles is! List) return false;
                      return roles.any((r) => r['name'] == 'vendedor');
                    }).map((user) {
                      return DropdownMenuItem<int>(
                        value: user['id'],
                        child: Text(user['name'] ?? 'Usuario ${user['id']}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedVendedorId = v),
                  );
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estado,
                dropdownColor: const Color(0xFF3B3E43),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1C1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.info, color: Colors.white54),
                ),
                items: const [
                  DropdownMenuItem(value: 'vacio', child: Text('VACIO')),
                  DropdownMenuItem(value: 'armando', child: Text('ARMANDO')),
                  DropdownMenuItem(value: 'listo', child: Text('LISTO')),
                  DropdownMenuItem(value: 'en_ruta', child: Text('EN RUTA')),
                  DropdownMenuItem(value: 'cerrado', child: Text('CERRADO')),
                ],
                onChanged: (v) => setState(() => _estado = v!),
              ),

              const SizedBox(height: 16),
              _buildTextField(
                controller: _notasController,
                label: 'Notas adicionales',
                icon: Icons.notes,
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF232529),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF2C2F33),
                                      title: const Text(
                                        'Eliminar Camión',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        '¿Estás seguro de eliminar este camión?',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    setState(() => _isLoading = true);
                                    try {
                                      await context
                                          .read<CamionVictualProvider>()
                                          .delete(widget.camion!.id);
                                      if (mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Camión eliminado'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  }
                                },
                          child: const Text(
                            'ELIMINAR',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'GUARDAR' : 'CREAR CAMIÓN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.white54),
      ),
    );
  }
}
