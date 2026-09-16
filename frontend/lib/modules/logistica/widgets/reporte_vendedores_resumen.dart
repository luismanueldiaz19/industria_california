import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/reporte_vendedores_provider.dart';
import 'reporte_vendedores_constants.dart';

/// Tarjetas de resumen en la parte superior del reporte.
class ReporteVendedoresResumen extends StatelessWidget {
  final ReporteVendedoresProvider prov;

  const ReporteVendedoresResumen({super.key, required this.prov});

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,##0.00', 'en_US');
    return Row(
      children: [
        _ResumenCard(
          icon: Icons.people_alt_rounded,
          label: 'Vendedores',
          value: prov.totalVendedores.toString(),
          color: kColorEnviado,
        ),
        const SizedBox(width: 8),
        _ResumenCard(
          icon: Icons.shopping_cart_rounded,
          label: 'Pedidos',
          value: prov.totalPedidosGral.toString(),
          color: kColorFacturado,
        ),
        const SizedBox(width: 8),
        _ResumenCard(
          icon: Icons.attach_money_rounded,
          label: 'Total Orig',
          value: '\$${moneyFmt.format(prov.totalMontoGral)}',
          color: kColorAccent,
        ),
        const SizedBox(width: 8),
        _ResumenCard(
          icon: Icons.money_off_rounded,
          label: 'Faltantes',
          value: '\$${moneyFmt.format(prov.totalFaltanteGral)}',
          color: kColorCancelado,
        ),
        const SizedBox(width: 8),
        _ResumenCard(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Total Real',
          value: '\$${moneyFmt.format(prov.totalRealGral)}',
          color: kColorFacturado,
        ),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kColorSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
