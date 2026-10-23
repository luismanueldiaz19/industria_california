import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../pedido/utils/pedido_utils.dart';
import '../models/camion_victual.dart';

/// Tile de un pedido dentro del camión en modo Light y amigable.
/// Muestra: orden, cliente, pedido, número de factura, dirección, monto, estado de pedido y estado de entrega.
class PedidoEnCamionTile extends StatelessWidget {
  final CamionPedido pedido;
  final bool showDragHandle;
  final VoidCallback? onQuitar;
  final VoidCallback? onTap;
  final int? index;
  final Key? tileKey;

  const PedidoEnCamionTile({
    super.key,
    required this.pedido,
    this.showDragHandle = false,
    this.onQuitar,
    this.onTap,
    this.index,
    this.tileKey,
  });

  Color get _entregaColor {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return const Color(0xFF059669);
      case 'en_curso':
        return const Color(0xFF2563EB);
      case 'fallido':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get _entregaBgColor {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return const Color(0xFFECFDF5);
      case 'en_curso':
        return const Color(0xFFEFF6FF);
      case 'fallido':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  String get _entregaLabel {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return 'Entregado';
      case 'en_curso':
        return 'En curso';
      case 'fallido':
        return 'Fallido';
      default:
        return 'Pendiente';
    }
  }

  IconData get _entregaIcon {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return Icons.check_circle_outline_rounded;
      case 'en_curso':
        return Icons.local_shipping_outlined;
      case 'fallido':
        return Icons.error_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Widget _buildEntregaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: _entregaBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _entregaColor.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_entregaIcon, size: 11, color: _entregaColor),
          const SizedBox(width: 3),
          Text(
            _entregaLabel,
            style: TextStyle(
              color: _entregaColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final hasFactura =
        pedido.numFactura != null && pedido.numFactura!.trim().isNotEmpty;
    final estadoPedidoColor = PedidoUtils.getColorForEstado(
      pedido.estadoPedido,
    );

    return Container(
      key: tileKey,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── 1. Círculo con Orden de Entrega ──
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${pedido.ordenViaje}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ── 2. Información Central ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre del Cliente y Monto Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pedido.clienteNombre ??
                                  'Cliente #${pedido.clienteId}',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fmt.format(pedido.total),
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Fila de Badges: Pedido #, No. Factura, Estado Pedido
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Pedido #
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_rounded,
                                  size: 10,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Pedido #${pedido.id}',
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // No. Factura
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: hasFactura
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: hasFactura
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 10,
                                  color: hasFactura
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  hasFactura
                                      ? 'Factura: ${pedido.numFactura}'
                                      : 'Sin Factura',
                                  style: TextStyle(
                                    color: hasFactura
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: hasFactura
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Estado del Pedido (ej. FACTURADO)
                          if (pedido.estadoPedido.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: estadoPedidoColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: estadoPedidoColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                pedido.estadoPedido.toUpperCase(),
                                style: TextStyle(
                                  color: estadoPedidoColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Dirección del Cliente y Estado de Entrega
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              (pedido.clienteDireccion != null &&
                                      pedido.clienteDireccion!
                                          .trim()
                                          .isNotEmpty)
                                  ? pedido.clienteDireccion!
                                  : 'Sin dirección registrada',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Badge Estado Entrega (Pendiente, En curso, etc.)
                          _buildEntregaBadge(),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 3. Acciones (Ver detalle / Quitar / Drag handle) ──
                if (onTap != null && !showDragHandle) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    tooltip: 'Ver Detalle del Pedido',
                    onPressed: onTap,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
                if (onQuitar != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    tooltip: 'Quitar del Camión',
                    onPressed: onQuitar,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
                if (showDragHandle && index != null) ...[
                  const SizedBox(width: 6),
                  ReorderableDragStartListener(
                    index: index!,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
