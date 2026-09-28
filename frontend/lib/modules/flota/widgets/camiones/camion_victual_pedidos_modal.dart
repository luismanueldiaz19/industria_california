import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';

class CamionVictualPedidosModal extends StatelessWidget {
  final CamionVictual camion;

  const CamionVictualPedidosModal({super.key, required this.camion});

  static const _darkBg = Color(0xFF1A1C1E);
  static const _cardColor = Color(0xFF2C2F33);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final provider = context.watch<CamionVictualProvider>();
    final currentCamion = provider.camiones.firstWhere(
      (c) => c.id == camion.id,
      orElse: () => camion,
    );
    final pedidos =
        List<CamionPedido>.from(
            currentCamion.pedidos,
          ).where((p) => p.estadoEntrega != 'entregado').toList()
          ..sort((a, b) => a.ordenViaje.compareTo(b.ordenViaje));

    Color estadoColor = Colors.grey;
    if (currentCamion.estado == 'vacio') estadoColor = Colors.blueGrey;
    if (currentCamion.estado == 'armando') estadoColor = Colors.blue;
    if (currentCamion.estado == 'listo') estadoColor = Colors.green;
    if (currentCamion.estado == 'en_ruta') estadoColor = Colors.orange;
    if (currentCamion.estado == 'cerrado') estadoColor = Colors.red;

    return Dialog(
      backgroundColor: _darkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Camión: ${currentCamion.nombre.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: estadoColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          currentCamion.estado.toUpperCase(),
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Chofer',
                            currentCamion.choferNombre ?? 'Sin asignar',
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            'Vendedor',
                            currentCamion.vendedorNombre ?? 'Sin asignar',
                            Icons.badge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pedidos Table
                    const Text(
                      'Detalles de Pedidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          _buildDetallesHeader(),
                          const Divider(height: 1, color: Colors.white10),
                          if (pedidos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No hay pedidos en este camión',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else
                            ...pedidos.map(
                              (det) => _buildDetalleRow(
                                context,
                                currentCamion,
                                det,
                                formatCurrency,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Totals
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL DEL CAMIÓN:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatCurrency.format(currentCamion.montoTotal),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (currentCamion.estado != 'vacio')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: _cardColor,
                                title: const Text(
                                  'Vaciar Camión',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  '¿Estás seguro de vaciar este camión? Se removerán todos los pedidos.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text(
                                      'Vaciar',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              if (context.mounted) {
                                final provider = context
                                    .read<CamionVictualProvider>();
                                final exito = await provider.vaciarCamion(
                                  currentCamion.id,
                                );
                                if (exito) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    const CustomSnackBar.success(
                                      message: 'Camión vaciado',
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(
                                      message:
                                          provider.error ?? 'Error al vaciar',
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Vaciar Camión',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'CLIENTE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ESTADO',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'MONTO',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(
    BuildContext context,
    CamionVictual currentCamion,
    CamionPedido det,
    NumberFormat formatCurrency,
  ) {
    Color estadoColor = Colors.orangeAccent;
    if (det.estadoEntrega == 'entregado') estadoColor = Colors.greenAccent;
    if (det.estadoEntrega == 'fallido') estadoColor = Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${det.ordenViaje}',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  det.clienteNombre ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (det.clienteDireccion != null &&
                    det.clienteDireccion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    det.clienteDireccion!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final nuevoEstado = det.estadoEntrega == 'entregado'
                    ? 'pendiente'
                    : 'entregado';
                final provider = context.read<CamionVictualProvider>();
                final exito = await provider.actualizarEntrega(
                  currentCamion.id,
                  det.id,
                  nuevoEstado,
                );
                if (exito) {
                  showTopSnackBar(
                    Overlay.of(context),
                    const CustomSnackBar.success(
                      message: 'Estado de entrega actualizado',
                    ),
                  );
                } else {
                  showTopSnackBar(
                    Overlay.of(context),
                    CustomSnackBar.error(message: provider.error ?? 'Error'),
                  );
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    det.estadoEntrega == 'entregado'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: estadoColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    det.estadoEntrega.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency.format(det.total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
