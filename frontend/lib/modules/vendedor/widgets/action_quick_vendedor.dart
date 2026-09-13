import 'package:flutter/material.dart';
import '../screens/vendedor_pedido_flow_screen.dart';
import '../screens/vendedor_pedidos_screen.dart';
import '../screens/vendedor_rutas_screen.dart';
import 'build_action_button.dart';

/// Acciones rápidas del dashboard del vendedor.
/// Cada acción navega a su pantalla correspondiente.
class ActionQuickVendedor extends StatelessWidget {
  const ActionQuickVendedor({super.key, required this.styleTheme});

  final TextTheme styleTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: styleTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionTile(
                icon: Icons.add_shopping_cart,
                label: 'Agregar Pedido',
                isPrimary: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendedorPedidoFlowScreen(),
                  ),
                ),
              ),
              _ActionTile(
                icon: Icons.map_outlined,
                label: 'Rutas',
                isPrimary: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendedorRutasScreen(),
                  ),
                ),
              ),
              const BuildActionButton(
                Icons.people_outline,
                'Clientes',
                false,
                showBadge: true,
              ),
              _ActionTile(
                icon: Icons.list_alt,
                label: 'Pedidos',
                isPrimary: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendedorPedidosScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón de acción con navegación — separado de BuildActionButton para
/// no agregar lógica de Navigator al widget genérico (SRP).
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BuildActionButton(icon, label, isPrimary),
    );
  }
}
