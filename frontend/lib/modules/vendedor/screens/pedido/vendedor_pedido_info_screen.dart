import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pedido_form_provider.dart';
import '../../widgets/pedido_cliente_selector.dart';
import '../../widgets/pedido_ruta_selector.dart';

class VendedorPedidoInfoScreen extends StatelessWidget {
  final VoidCallback onNext;

  const VendedorPedidoInfoScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoFormProvider>();
    final _comentarioCtrl = TextEditingController(text: provider.comentario);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Información del Cliente *', Icons.person_outline),
          const SizedBox(height: 12),
          PedidoClienteSelector(
            selected: provider.cliente,
            onChanged: (c) => provider.setCliente(c),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Ruta de Entrega (opcional)', Icons.map_outlined),
          const SizedBox(height: 12),
          PedidoRutaSelector(
            selected: provider.ruta,
            onChanged: (r) => provider.setRuta(r),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Comentarios o Notas (opcional)', Icons.notes_outlined),
          const SizedBox(height: 12),
          TextFormField(
            controller: _comentarioCtrl,
            maxLines: 3,
            onChanged: (v) => provider.setComentario(v),
            decoration: InputDecoration(
              hintText: 'Ej. Entregar por la tarde...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1976D2),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.esValidoPaso1 ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar al Catálogo →',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A5F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
