import 'package:flutter/material.dart';
import '../screens/vendedor_pedido_flow_screen.dart';
import '../screens/vendedor_pedidos_screen.dart';
import '../screens/vendedor_rutas_screen.dart';
import '../screens/vendedor_ordenes_produccion_screen.dart';
import '../screens/clientes/vendedor_clientes_screen.dart';
import 'build_action_button.dart';
import '../../cheque_futurista/screens/cheques_futuristas_screen.dart';

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
          Wrap(
            spacing: 20,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              _ActionTile(
                icon: Icons.add_shopping_cart,
                label: 'Agregar\nPedido',
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
              _ActionTile(
                icon: Icons.people_outline,
                label: 'Clientes',
                isPrimary: false,
                showBadge: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendedorClientesScreen(),
                  ),
                ),
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
              _ActionTile(
                icon: Icons.precision_manufacturing,
                label: 'Producción',
                isPrimary: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendedorOrdenesProduccionScreen(),
                  ),
                ),
              ),
              // Botón destacado — Cheques Futuristas
              _ChequeFuturistaActionTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChequesFuturistasScreen(),
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
  final bool showBadge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BuildActionButton(icon, label, isPrimary, showBadge: showBadge),
    );
  }
}

/// Botón especial de Cheques Futuristas.
/// Fondo rojo con opacidad + icono y texto blancos para destacarse.
class _ChequeFuturistaActionTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ChequeFuturistaActionTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const redColor = Color(0xFFB71C1C);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: redColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: redColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cheques\nFuturistas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB71C1C),
            ),
          ),
        ],
      ),
    );
  }
}
