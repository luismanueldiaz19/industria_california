import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logistica/providers/ruta_provider.dart';
import '../../logistica/models/ruta.dart';

/// Pantalla de Rutas para el vendedor.
/// Puede: ver todas las rutas, crear nueva.
/// No puede: editar ni eliminar (solo admin).
class VendedorRutasScreen extends StatefulWidget {
  const VendedorRutasScreen({super.key});

  @override
  State<VendedorRutasScreen> createState() => _VendedorRutasScreenState();
}

class _VendedorRutasScreenState extends State<VendedorRutasScreen> {
  static const _bgPrimary = Color(0xFF1E2F4C);
  static const _accentBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RutaProvider>().fetchRutas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _bgPrimary,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rutas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _mostrarFormularioCrear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _accentBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Nueva',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<RutaProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _accentBlue),
          );
        }
        if (provider.error != null && provider.rutas.isEmpty) {
          return _buildError(provider.error!);
        }
        if (provider.rutas.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          color: _accentBlue,
          onRefresh: () => provider.fetchRutas(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.rutas.length,
            itemBuilder: (ctx, i) => _buildRutaCard(provider.rutas[i]),
          ),
        );
      },
    );
  }

  Widget _buildRutaCard(Ruta ruta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.map_rounded, color: _accentBlue, size: 22),
        ),
        title: Text(
          ruta.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _bgPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ruta.chofer != null) ...[
              const SizedBox(height: 4),
              _subtitleRow(Icons.person_outline, ruta.chofer!),
            ],
            if (ruta.fichaCamion != null) ...[
              const SizedBox(height: 2),
              _subtitleRow(Icons.local_shipping_outlined, ruta.fichaCamion!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subtitleRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'No hay rutas creadas',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca "Nueva" para crear la primera ruta',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(err,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<RutaProvider>().fetchRutas(),
            style: ElevatedButton.styleFrom(backgroundColor: _accentBlue),
            child: const Text('Reintentar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Diálogo para crear ruta ─────────────────────────────────────────────

  void _mostrarFormularioCrear() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RutaFormSheet(
        onGuardar: (data) async {
          final ok = await context.read<RutaProvider>().createRuta(data);
          if (!mounted) return;
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ruta creada correctamente'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          } else {
            final err = context.read<RutaProvider>().error ?? 'Error';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }
}

/// Bottom sheet con formulario de creación de ruta.
/// Separado en widget propio (SRP).
class _RutaFormSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onGuardar;

  const _RutaFormSheet({required this.onGuardar});

  @override
  State<_RutaFormSheet> createState() => _RutaFormSheetState();
}

class _RutaFormSheetState extends State<_RutaFormSheet> {
  static const _accentBlue = Color(0xFF1976D2);
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _choferCtrl = TextEditingController();
  final _fichaCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _choferCtrl.dispose();
    _fichaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle visual
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Nueva Ruta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2F4C),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _nombreCtrl,
              label: 'Nombre de la ruta *',
              icon: Icons.map_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _choferCtrl,
              label: 'Chofer (opcional)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _fichaCtrl,
              label: 'Ficha del camión (opcional)',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar Ruta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _accentBlue),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await widget.onGuardar({
      'nombre': _nombreCtrl.text.trim(),
      'chofer': _choferCtrl.text.trim().isEmpty
          ? null
          : _choferCtrl.text.trim(),
      'ficha_camion': _fichaCtrl.text.trim().isEmpty
          ? null
          : _fichaCtrl.text.trim(),
    });

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }
}
