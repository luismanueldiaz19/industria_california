import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';

class AlertasTotalsBar extends StatelessWidget {
  final double totalInformado;
  final double totalPendiente;
  final double montoReal;

  const AlertasTotalsBar({
    super.key,
    required this.totalInformado,
    required this.totalPendiente,
    required this.montoReal,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        border: Border(top: BorderSide(color: AppTheme.darkBorderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem('Monto Informado', totalInformado, Colors.blueAccent),
          Container(width: 1, height: 26, color: AppTheme.darkBorderColor),
          _buildTotalItem(
            'Monto Pendiente',
            totalPendiente,
            AppTheme.accentYellow,
          ),
          Container(width: 1, height: 26, color: AppTheme.darkBorderColor),
          _buildTotalItem('Monto Real', montoReal, AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, double amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
