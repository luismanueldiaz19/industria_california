import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_theme.dart';

class LedhouseAlertasTotalsBar extends StatelessWidget {
  final double totalInformado;
  final double totalPendiente;
  final double montoReal;

  const LedhouseAlertasTotalsBar({
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        border: Border(top: BorderSide(color: AppTheme.darkBorderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem('Monto Informado', totalInformado, Colors.blueAccent),
          Container(width: 1, height: 30, color: AppTheme.darkBorderColor),
          _buildTotalItem(
            'Monto Pendiente',
            totalPendiente,
            AppTheme.accentYellow,
          ),
          Container(width: 1, height: 30, color: AppTheme.darkBorderColor),
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
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
