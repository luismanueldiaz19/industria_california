import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/camion_victual.dart';

/// Tile de un pedido dentro del camión.
/// Muestra número de orden, cliente, monto y estado de entrega.
/// Si [editable] es true muestra el handle de drag y el botón de quitar.
class PedidoEnCamionTile extends StatelessWidget {
  final CamionPedido pedido;
  final bool showDragHandle;
  final VoidCallback? onQuitar;
  final VoidCallback? onTap;
  final int? index;
  // Para drag-and-drop
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
    switch (pedido.estadoEntrega) {
      case 'entregado':
        return const Color(0xFF4CAF50);
      case 'en_curso':
        return const Color(0xFF2196F3);
      case 'fallido':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String get _entregaLabel {
    switch (pedido.estadoEntrega) {
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

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'es');

    return Container(
      key: tileKey,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF243552),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Número de orden
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.6),
                ),
              ),
              child: Center(
                child: Text(
                  '${pedido.ordenViaje}',
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          pedido.clienteNombre ?? 'Cliente #${pedido.clienteId}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${pedido.id}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            if (pedido.clienteDireccion != null)
              Text(
                pedido.clienteDireccion!,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${fmt.format(pedido.total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _entregaColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _entregaLabel,
                    style: TextStyle(
                      color: _entregaColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (onQuitar != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onQuitar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                ),
              ),
            ],
            if (showDragHandle && index != null) ...[
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: index!,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
