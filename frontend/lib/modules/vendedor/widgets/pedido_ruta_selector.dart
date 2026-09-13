import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logistica/providers/ruta_provider.dart';
import '../../logistica/models/ruta.dart';
import '../screens/vendedor_rutas_screen.dart';

/// Selector de ruta (opcional) con enlace rápido a gestión de rutas.
/// Responsabilidad única: seleccionar una Ruta o null.
class PedidoRutaSelector extends StatelessWidget {
  final Ruta? selected;
  final ValueChanged<Ruta?> onChanged;

  static const _accentBlue = Color(0xFF1976D2);

  const PedidoRutaSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RutaProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) return const LinearProgressIndicator();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Dropdown principal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Ruta?>(
                  value: selected,
                  isExpanded: true,
                  hint: const Text(
                    'Sin ruta asignada',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  items: [
                    const DropdownMenuItem<Ruta?>(
                      value: null,
                      child: Text(
                        'Sin ruta',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    ...provider.rutas.map(
                      (r) => DropdownMenuItem<Ruta>(
                        value: r,
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined,
                                size: 16, color: _accentBlue),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(r.nombre,
                                    style: const TextStyle(fontSize: 12)),
                                if (r.chofer != null)
                                  Text(
                                    r.chofer!,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Enlace rápido para ver / crear rutas sin salir del formulario
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const VendedorRutasScreen(),
                    ),
                  )
                  .then((_) => provider.fetchRutas()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Ver / crear rutas',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
