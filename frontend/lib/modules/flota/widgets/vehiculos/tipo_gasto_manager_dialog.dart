import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gasto_vehiculo_provider.dart';
import '../../models/tipo_gasto.dart';

class TipoGastoManagerDialog extends StatefulWidget {
  const TipoGastoManagerDialog({super.key});

  @override
  State<TipoGastoManagerDialog> createState() => _TipoGastoManagerDialogState();
}

class _TipoGastoManagerDialogState extends State<TipoGastoManagerDialog> {
  final _controller = TextEditingController();
  TipoGasto? _editingTipo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(GastoVehiculoProvider provider) async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) return;

    bool success;
    if (_editingTipo == null) {
      success = await provider.createTipoGasto(nombre);
    } else {
      success = await provider.updateTipoGasto(_editingTipo!.id, nombre);
    }

    if (success) {
      setState(() {
        _controller.clear();
        _editingTipo = null;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _delete(GastoVehiculoProvider provider, TipoGasto tipo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F33),
        title: const Text('Eliminar Tipo de Gasto', style: TextStyle(color: Colors.white)),
        content: const Text('¿Está seguro de eliminar este tipo?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteTipoGasto(tipo.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(16),
        child: Consumer<GastoVehiculoProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gestionar Tipos de Gasto',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Nombre del tipo (Ej. Mantenimiento, Multas)',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF1A1C1E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _save(provider),
                      child: Text(
                        _editingTipo == null ? 'AGREGAR' : 'GUARDAR',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_editingTipo != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white54),
                        onPressed: () {
                          setState(() {
                            _editingTipo = null;
                            _controller.clear();
                          });
                        },
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                if (provider.tiposGasto.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay tipos registrados', style: TextStyle(color: Colors.white54)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.tiposGasto.length,
                      itemBuilder: (context, index) {
                        final tipo = provider.tiposGasto[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C1E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            title: Text(tipo.nombre, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _editingTipo = tipo;
                                      _controller.text = tipo.nombre;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _delete(provider, tipo),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
