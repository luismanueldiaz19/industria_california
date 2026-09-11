import 'package:flutter/material.dart';
import '../models/inventario_producto.dart';

class StockBadgeWidget extends StatelessWidget {
  final EstadoStock estado;
  final double? stock;
  final bool compact;

  const StockBadgeWidget({
    super.key,
    required this.estado,
    this.stock,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(estado);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: config.dot.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            compact
                ? config.label
                : (stock != null ? '${stock!.toStringAsFixed(0)} ${config.label}' : config.label),
            style: TextStyle(
              color: config.text,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(EstadoStock estado) {
    switch (estado) {
      case EstadoStock.ok:
        return _BadgeConfig(
          bg: const Color(0xFF1e8e3e).withValues(alpha: 0.15),
          border: const Color(0xFF1e8e3e).withValues(alpha: 0.4),
          dot: const Color(0xFF34A853),
          text: const Color(0xFF34A853),
          label: 'OK',
        );
      case EstadoStock.alerta:
        return _BadgeConfig(
          bg: const Color(0xFFf9a825).withValues(alpha: 0.12),
          border: const Color(0xFFf9a825).withValues(alpha: 0.4),
          dot: const Color(0xFFFBBC05),
          text: const Color(0xFFF9A825),
          label: 'ALERTA',
        );
      case EstadoStock.critico:
        return _BadgeConfig(
          bg: const Color(0xFFea4335).withValues(alpha: 0.12),
          border: const Color(0xFFea4335).withValues(alpha: 0.4),
          dot: const Color(0xFFEA4335),
          text: const Color(0xFFEA4335),
          label: 'AGOTADO',
        );
      case EstadoStock.negativo:
        return _BadgeConfig(
          bg: const Color(0xFF1A1C1E),
          border: const Color(0xFFE31E24).withValues(alpha: 0.6),
          dot: const Color(0xFFE31E24),
          text: Colors.white,
          label: 'NEGATIVO',
        );
    }
  }
}

class _BadgeConfig {
  final Color bg, border, dot, text;
  final String label;
  const _BadgeConfig({
    required this.bg,
    required this.border,
    required this.dot,
    required this.text,
    required this.label,
  });
}
