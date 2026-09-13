import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../models/ruta.dart';
import '../providers/ruta_provider.dart';
import 'ruta_detalle_screen.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RutaProvider>().fetchRutas();
    });
  }

  void _showRutaForm({Ruta? ruta}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RutaFormDialog(ruta: ruta),
    );
  }

  void _confirmDelete(Ruta ruta) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F33),
          title: const Text(
            'Eliminar Ruta',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Estás seguro de eliminar la ruta "${ruta.nombre}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<RutaProvider>();
                final success = await provider.deleteRuta(ruta.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ruta eliminada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${provider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RutaProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2124),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(isAdmin),
          Expanded(child: _buildTable(provider, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F33),
        border: Border(bottom: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Color(0xFF2196F3),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Rutas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Oficina / Administración',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          if (isAdmin)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Agregar Ruta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showRutaForm(),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(RutaProvider provider, bool isAdmin) {
    if (provider.isLoading && provider.rutas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      );
    }

    if (provider.rutas.isEmpty) {
      return const Center(
        child: Text(
          'No hay rutas registradas.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF23272A)),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              dividerThickness: 0.5,
              columns: const [
                DataColumn(
                  label: Text(
                    'ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nombre de Ruta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Chofer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Ficha/Camión',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Acciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: provider.rutas.map((ruta) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '#${ruta.id}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        ruta.nombre,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    DataCell(
                      Text(
                        ruta.chofer ?? 'N/A',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    DataCell(
                      Text(
                        ruta.fichaCamion ?? 'N/A',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: Colors.greenAccent, size: 20),
                            tooltip: 'Ver Detalle (Despacho)',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RutaDetalleScreen(ruta: ruta),
                                ),
                              );
                            },
                          ),
                          if (isAdmin) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              tooltip: 'Editar Ruta',
                              onPressed: () => _showRutaForm(ruta: ruta),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white38,
                                size: 20,
                              ),
                              tooltip: 'Eliminar Ruta',
                              onPressed: () => _confirmDelete(ruta),
                            ),
                          ] else ...[
                            const Text(
                              'Sin permisos',
                              style: TextStyle(
                                color: Colors.white38,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RutaFormDialog extends StatefulWidget {
  final Ruta? ruta;
  const _RutaFormDialog({this.ruta});

  @override
  State<_RutaFormDialog> createState() => _RutaFormDialogState();
}

class _RutaFormDialogState extends State<_RutaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();
  final _fichaCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.ruta != null) {
      _nombreCtrl.text = widget.ruta!.nombre;
      _choferCtrl.text = widget.ruta!.chofer ?? '';
      _fichaCtrl.text = widget.ruta!.fichaCamion ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _choferCtrl.dispose();
    _fichaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<RutaProvider>();
    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'chofer': _choferCtrl.text.trim().isEmpty
          ? null
          : _choferCtrl.text.trim(),
      'ficha_camion': _fichaCtrl.text.trim().isEmpty
          ? null
          : _fichaCtrl.text.trim(),
    };

    bool success;
    if (widget.ruta == null) {
      success = await provider.createRuta(data);
    } else {
      success = await provider.updateRuta(widget.ruta!.id, data);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ruta == null ? 'Ruta creada' : 'Ruta actualizada',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2F33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(
        widget.ruta == null ? 'Nueva Ruta' : 'Editar Ruta',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Ruta *',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _choferCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Nombre del Chofer (Opcional)',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fichaCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Ficha/Placa del Camión (Opcional)',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 11),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Guardar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
