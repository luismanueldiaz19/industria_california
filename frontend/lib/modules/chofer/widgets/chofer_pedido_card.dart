import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../camion_victual/models/camion_victual.dart';
import '../../pedido/providers/pedido_provider.dart';
import '../../pedido/widgets/pedido_detalle_dialog.dart';
import 'package:provider/provider.dart';
import 'marcar_fallido_dialog.dart';

class ChoferPedidoCard extends StatelessWidget {
  final CamionPedido pedido;
  final int camionId;
  final Function(String estado, String? comentario) onCambiarEstado;

  const ChoferPedidoCard({
    super.key,
    required this.pedido,
    required this.camionId,
    required this.onCambiarEstado,
  });

  Future<void> _llamarCliente(BuildContext context, String telefono) async {
    final cleanPhone = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _verDetallePedido(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE31E24)),
      ),
    );

    try {
      final pedidoReal = await context.read<PedidoProvider>().getPedidoById(pedido.id);
      if (!context.mounted) return;
      Navigator.pop(context); // cerrar loading

      if (pedidoReal != null) {
        showDialog(
          context: context,
          builder: (_) => PedidoDetalleDialog(pedido: pedidoReal),
        );
      }
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Color _getEstadoColor() {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return const Color(0xFF15803D);
      case 'fallido':
        return const Color(0xFFDC2626);
      case 'en_curso':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFFB45309);
    }
  }

  Color _getEstadoBgColor() {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return const Color(0xFFDCFCE7);
      case 'fallido':
        return const Color(0xFFFEE2E2);
      case 'en_curso':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  String _getEstadoTexto() {
    switch (pedido.estadoEntrega.toLowerCase()) {
      case 'entregado':
        return 'ENTREGADO';
      case 'fallido':
        return 'FALLIDO';
      case 'en_curso':
        return 'EN CURSO';
      default:
        return 'PENDIENTE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEntregado = pedido.estadoEntrega.toLowerCase() == 'entregado';
    final bool isFallido = pedido.estadoEntrega.toLowerCase() == 'fallido';
    final estadoColor = _getEstadoColor();
    final estadoBgColor = _getEstadoBgColor();

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isEntregado
              ? const Color(0xFFBBF7D0)
              : (isFallido
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Secuencia, ID Pedido y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '#${pedido.ordenViaje}',
                        style: const TextStyle(
                          color: Color(0xFFE31E24),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pedido #${pedido.id}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: estadoColor.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _getEstadoTexto(),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Nombre del Cliente
            Text(
              pedido.clienteNombre ?? 'Cliente sin nombre',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Dirección
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF64748B),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pedido.clienteDireccion != null &&
                            pedido.clienteDireccion!.isNotEmpty
                        ? pedido.clienteDireccion!
                        : 'Sin dirección registrada',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Teléfono y Monto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pedido.clienteTelefono != null &&
                    pedido.clienteTelefono!.isNotEmpty)
                  InkWell(
                    onTap: () => _llamarCliente(context, pedido.clienteTelefono!),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, color: Color(0xFF2563EB), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            pedido.clienteTelefono!,
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  Formatters.formatCurrency(pedido.total),
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Comentario si es fallido o tiene observaciones
            if (pedido.comentarioEntrega != null &&
                pedido.comentarioEntrega!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFallido
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFallido
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  pedido.comentarioEntrega!,
                  style: TextStyle(
                    color: isFallido ? const Color(0xFFB91C1C) : const Color(0xFF475569),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const Divider(color: Color(0xFFF1F5F9), height: 16),

            // Botones de acción del Chofer
            Row(
              children: [
                // Ver productos del pedido
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('Items', style: TextStyle(fontSize: 11)),
                  onPressed: () => _verDetallePedido(context),
                ),
                const Spacer(),

                // Marcar Fallido
                if (!isFallido) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 15),
                    label: const Text(
                      'Fallido',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final motivo = await showDialog<String>(
                        context: context,
                        builder: (_) => MarcarFallidoDialog(
                          pedidoId: pedido.id,
                          clienteNombre: pedido.clienteNombre ?? 'Cliente sin nombre',
                        ),
                      );
                      if (motivo != null) {
                        onCambiarEstado('fallido', motivo);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Marcar Entregado
                if (!isEntregado)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Entregar',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => onCambiarEstado('entregado', null),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFF15803D), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Completado',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
