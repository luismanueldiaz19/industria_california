import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../camion_victual/models/camion_victual.dart';

class CamionVictualPedidosModal extends StatelessWidget {
  final CamionVictual camion;

  const CamionVictualPedidosModal({super.key, required this.camion});

  static const _darkBg = Color(0xFF1A1C1E);
  static const _cardColor = Color(0xFF2C2F33);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final pedidos = List<CamionPedido>.from(camion.pedidos)
      ..sort((a, b) => a.ordenViaje.compareTo(b.ordenViaje));

    Color estadoColor = Colors.grey;
    if (camion.estado == 'vacio') estadoColor = Colors.blueGrey;
    if (camion.estado == 'armando') estadoColor = Colors.blue;
    if (camion.estado == 'listo') estadoColor = Colors.green;
    if (camion.estado == 'en_ruta') estadoColor = Colors.orange;
    if (camion.estado == 'cerrado') estadoColor = Colors.red;

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
                      'Camión: ${camion.nombre.toUpperCase()}',
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: estadoColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          camion.estado.toUpperCase(),
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
                        child: const Icon(Icons.close, color: Colors.white54, size: 18),
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
                            camion.choferNombre ?? 'Sin asignar',
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            'Vendedor',
                            camion.vendedorNombre ?? 'Sin asignar',
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
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            )
                          else
                            ...pedidos.map((det) => _buildDetalleRow(det, formatCurrency)),
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
                            formatCurrency.format(camion.montoTotal),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
          SizedBox(width: 24, child: Text('#', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold))),
          Expanded(
            flex: 3,
            child: Text(
              'CLIENTE',
              style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ESTADO',
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'MONTO',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(CamionPedido det, NumberFormat formatCurrency) {
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
              style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
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
                if (det.clienteDireccion != null && det.clienteDireccion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    det.clienteDireccion!,
                    style: const TextStyle(color: Colors.white54, fontSize: 9, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              det.estadoEntrega.toUpperCase(),
              style: TextStyle(color: estadoColor, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency.format(det.total),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
