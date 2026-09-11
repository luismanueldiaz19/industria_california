import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Barra superior fija que muestra el total del carrito y cantidad de ítems.
/// Responsabilidad única: mostrar resumen, no manipular datos.
class PedidoCartSummaryBar extends StatelessWidget {
  final int itemCount;
  final double total;

  static const _primaryBlue = Color(0xFF1E3A5F);
  static final _currencyFmt =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  const PedidoCartSummaryBar({
    super.key,
    required this.itemCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryBlue,
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                '$itemCount ítem(s)',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Text(
            _currencyFmt.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
