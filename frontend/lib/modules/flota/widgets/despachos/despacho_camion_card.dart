import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../camion_victual/models/camion_victual.dart';

class DespachoCamionCard extends StatelessWidget {
  final CamionVictual camion;
  final bool isSelected;
  final VoidCallback onTap;

  const DespachoCamionCard({
    super.key,
    required this.camion,
    required this.isSelected,
    required this.onTap,
  });

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'vacio':
        return const Color(0xFF64748B);
      case 'armando':
        return const Color(0xFFD97706);
      case 'listo':
        return const Color(0xFF16A34A);
      case 'en_ruta':
        return const Color(0xFF2563EB);
      case 'cerrado':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'vacio':
        return 'VACÍO';
      case 'armando':
        return 'ARMANDO';
      case 'listo':
        return 'LISTO';
      case 'en_ruta':
        return 'EN RUTA';
      case 'cerrado':
        return 'CERRADO';
      default:
        return estado.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final estadoColor = _getEstadoColor(camion.estado);
    final tieneChofer = camion.choferNombre != null && camion.choferNombre!.isNotEmpty;
    final double progreso = camion.minimoSalida > 0
        ? (camion.montoTotal / camion.minimoSalida).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE31E24)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFE31E24).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 6 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Slot, Name, Estado Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${camion.slotNumero}',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    camion.nombre,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getEstadoLabel(camion.estado),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Driver & Seller Row
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 13,
                  color: tieneChofer ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tieneChofer ? camion.choferNombre! : 'Sin Conductor asignado',
                    style: TextStyle(
                      color: tieneChofer ? const Color(0xFF334155) : const Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: tieneChofer ? FontWeight.w500 : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (camion.vendedorNombre != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Vend: ${camion.vendedorNombre}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (camion.vehiculoFicha != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      camion.vehiculoFicha!,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (camion.vehiculoPlaca != null && camion.vehiculoPlaca!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${camion.vehiculoPlaca!})',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Amount, Count & Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      '${camion.pedidos.length} pedidos',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
                Text(
                  currencyFmt.format(camion.montoTotal),
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Mini progress towards minimum
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 4,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progreso >= 1.0
                      ? const Color(0xFF16A34A)
                      : (progreso > 0.5 ? const Color(0xFFD97706) : const Color(0xFFE31E24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
