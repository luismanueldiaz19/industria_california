import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/camion_victual.dart';

/// Tarjeta visual compacta y detallada de un camión victual — Estilo combinado Despacho/Vendedor.
/// Muestra:
/// - Slot (#1), Nombre del camión (rojo oscuro), Badge de estado
/// - Conductor asignado y Vendedor
/// - Ficha de vehículo y placa
/// - Cantidad de pedidos, faltante de meta (si aplica) y monto total cargado
/// - Barra de progreso visual hacia el mínimo de salida
class CamionVictualCard extends StatelessWidget {
  final CamionVictual camion;
  final double montoMinimo;
  final VoidCallback onTap;

  const CamionVictualCard({
    super.key,
    required this.camion,
    required this.montoMinimo,
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
    final tieneChofer =
        camion.choferNombre != null && camion.choferNombre!.trim().isNotEmpty;

    final actualMinimo = (camion.minimoSalida > 5000)
        ? camion.minimoSalida
        : (montoMinimo > 0 ? montoMinimo : 500000.0);
    final double progreso = actualMinimo > 0
        ? (camion.montoTotal / actualMinimo).clamp(0.0, 1.0)
        : 1.0;
    final falta = (actualMinimo - camion.montoTotal).clamp(0.0, double.infinity);
    final isCompletado = falta <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila 1: Slot (#), Nombre y Badge de Estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: estadoColor.withValues(alpha: 0.3),
                        ),
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
                const SizedBox(height: 6),

                // Fila 2: Conductor & Vendedor
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 13,
                      color: tieneChofer
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tieneChofer
                            ? camion.choferNombre!
                            : 'Sin conductor asignado',
                        style: TextStyle(
                          color: tieneChofer
                              ? const Color(0xFF334155)
                              : const Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: tieneChofer
                              ? FontWeight.w500
                              : FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (camion.vendedorNombre != null &&
                        camion.vendedorNombre!.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Vend: ${camion.vendedorNombre}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),

                // Fila 3: Vehículo (Ficha y Placa)
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 12,
                      color: camion.vehiculoFicha != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    if (camion.vehiculoFicha != null &&
                        camion.vehiculoFicha!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
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
                      if (camion.vehiculoPlaca != null &&
                          camion.vehiculoPlaca!.trim().isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${camion.vehiculoPlaca!})',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'Sin vehículo asignado',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),

                // Fila 4: Cantidad de Pedidos y Monto Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${camion.pedidos.length} ${camion.pedidos.length == 1 ? 'pedido' : 'pedidos'}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                        if (!isCompletado && actualMinimo > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• Falta ${currencyFmt.format(falta)}',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      currencyFmt.format(camion.montoTotal),
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fila 5: Barra de Progreso hacia mínimo
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progreso >= 1.0
                          ? const Color(0xFF16A34A)
                          : (progreso > 0.5
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
