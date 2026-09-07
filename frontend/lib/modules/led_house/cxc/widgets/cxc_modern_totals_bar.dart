import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme.dart';

class ModernTotalsBar extends StatelessWidget {
  final double facturado;
  final double pendiente;
  final double vencido;
  final int intervenciones;

  const ModernTotalsBar({
    super.key,
    required this.facturado,
    required this.pendiente,
    required this.vencido,
    required this.intervenciones,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactTotal(
                  'Facturado',
                  currencyFormatter.format(facturado),
                  AppTheme.ledhouseBlue,
                  Icons.receipt_long_rounded,
                ),
                _buildDivider(),
                _buildCompactTotal(
                  'Pendiente',
                  currencyFormatter.format(pendiente),
                  const Color(0xFFFB8C00),
                  Icons.account_balance_wallet_rounded,
                ),
                _buildDivider(),
                _buildCompactTotal(
                  'Vencido',
                  currencyFormatter.format(vencido),
                  AppTheme.dangerColor,
                  Icons.warning_amber_rounded,
                ),
                if (intervenciones > 0) ...[
                  _buildDivider(),
                  _buildCompactTotal(
                    'Interv.',
                    intervenciones.toString(),
                    Colors.purple,
                    Icons.support_agent_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildCompactTotal(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
