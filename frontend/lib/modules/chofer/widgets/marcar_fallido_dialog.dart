import 'package:flutter/material.dart';

class MarcarFallidoDialog extends StatefulWidget {
  final int pedidoId;
  final String clienteNombre;

  const MarcarFallidoDialog({
    super.key,
    required this.pedidoId,
    required this.clienteNombre,
  });

  @override
  State<MarcarFallidoDialog> createState() => _MarcarFallidoDialogState();
}

class _MarcarFallidoDialogState extends State<MarcarFallidoDialog> {
  final TextEditingController _comentarioController = TextEditingController();

  static const List<String> _motivosComunes = [
    'Cliente cerrado / no se encontraba',
    'No tenía dinero para recibir',
    'Rechazó la mercancía / error en pedido',
    'Dirección errónea o inaccesible',
    'Falta de tiempo en la ruta',
    'Otro motivo',
  ];

  String _motivoSeleccionado = _motivosComunes.first;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: const [
          Icon(Icons.cancel, color: Color(0xFFDC2626), size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Marcar Pedido Fallido',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${widget.pedidoId} · ${widget.clienteNombre}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Motivo del fallo:',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _motivoSeleccionado,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12),
                  items: _motivosComunes.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(
                        m,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF1E293B)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _motivoSeleccionado = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Comentarios adicionales (opcional):',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comentarioController,
              maxLines: 2,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Ej. Se llamó al cliente pero no respondió...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {
            final motivoFinal = _comentarioController.text.trim().isNotEmpty
                ? '$_motivoSeleccionado: ${_comentarioController.text.trim()}'
                : _motivoSeleccionado;
            Navigator.pop(context, motivoFinal);
          },
          child: const Text(
            'CONFIRMAR FALLIDO',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
