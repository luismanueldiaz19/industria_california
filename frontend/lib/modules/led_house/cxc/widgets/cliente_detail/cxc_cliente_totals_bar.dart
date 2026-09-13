import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_theme.dart';

class CxcClienteTotalsBar extends StatelessWidget {
  final double totalFacturado;
  final double totalPendiente;
  final double totalVencido;
  final bool isMobile;

  const CxcClienteTotalsBar({
    super.key,
    required this.totalFacturado,
    required this.totalPendiente,
    required this.totalVencido,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorderColor),
        ),
        child: Column(
          children: [
            _TotalItem(
              title: 'TOTAL FACTURADO',
              amount: totalFacturado,
              color: Colors.white70,
              icon: Icons.receipt_rounded,
              isMobile: true,
            ),
            const SizedBox(height: 12),
            _TotalItem(
              title: 'DEUDA PENDIENTE',
              amount: totalPendiente,
              color: AppTheme.accentYellow,
              icon: Icons.account_balance_wallet_rounded,
              isMobile: true,
            ),
            const SizedBox(height: 12),
            _TotalItem(
              title: 'TOTAL VENCIDO',
              amount: totalVencido,
              color: AppTheme.dangerColor,
              icon: Icons.warning_rounded,
              isMobile: true,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TotalItem(
            title: 'TOTAL FACTURADO',
            amount: totalFacturado,
            color: Colors.white70,
            icon: Icons.receipt_rounded,
          ),
          Container(width: 1, height: 32, color: AppTheme.darkBorderColor),
          _TotalItem(
            title: 'DEUDA PENDIENTE',
            amount: totalPendiente,
            color: AppTheme.accentYellow,
            icon: Icons.account_balance_wallet_rounded,
          ),
          Container(width: 1, height: 32, color: AppTheme.darkBorderColor),
          _TotalItem(
            title: 'TOTAL VENCIDO',
            amount: totalVencido,
            color: AppTheme.dangerColor,
            icon: Icons.warning_rounded,
          ),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _TotalItem({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    final child = Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currencyFormatter.format(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return isMobile ? child : Expanded(child: child);
  }
}
