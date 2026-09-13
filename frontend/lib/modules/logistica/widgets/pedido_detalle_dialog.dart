import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pedido.dart';
import '../models/pedido_detalle.dart';
import '../providers/pedido_provider.dart';

class PedidoDetalleDialog extends StatefulWidget {
  final Pedido pedido;

  const PedidoDetalleDialog({super.key, required this.pedido});

  @override
  State<PedidoDetalleDialog> createState() => _PedidoDetalleDialogState();
}

class _PedidoDetalleDialogState extends State<PedidoDetalleDialog> {
  static const _darkBg = Color(0xFF1A1C1E);
  static const _cardColor = Color(0xFF2C2F33);
  static const _accentRed = Color(0xFFE31E24);
  static const _accentBlue = Color(0xFF1A73E8);

  static final _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  static final _dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'es');

  static final Map<String, Color> _estadoColor = {
    'borrador': const Color(0xFFFF9800),
    'enviado': _accentBlue,
    'facturado': const Color(0xFF4CAF50),
    'cancelado': const Color(0xFFE31E24),
  };

  bool _isGeneratingPdf = false;

  Future<void> _generarPdf() async {
    setState(() => _isGeneratingPdf = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando Factura...')));
    try {
      final urlStr = await context.read<PedidoProvider>().getPdfUrl(
        widget.pedido.id,
      );
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final estadoColor = _estadoColor[pedido.estado] ?? Colors.grey;

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
                  Text(
                    'Pedido #${pedido.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
                          pedido.estado.toUpperCase(),
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
                            'Cliente',
                            pedido.clienteNombre ?? 'N/A',
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            'Vendedor',
                            pedido.vendedorNombre ?? 'N/A',
                            Icons.badge,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoCard(
                            'Ruta',
                            pedido.rutaNombre ?? 'Sin ruta',
                            Icons.map,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date and Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fecha: ${_dateFmt.format(pedido.createdAt)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isGeneratingPdf ? null : _generarPdf,
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf, size: 14),
                          label: const Text(
                            'Ver PDF',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Detalles Table
                    const Text(
                      'Detalles del Pedido',
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
                          ...pedido.detalles.map(
                            (det) => _buildDetalleRow(det),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _currencyFmt.format(pedido.total),
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (pedido.comentario != null &&
                        pedido.comentario!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Comentario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          pedido.comentario!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
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
          Expanded(
            flex: 3,
            child: Text(
              'PRODUCTO',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'CANT',
              textAlign: TextAlign.right,
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
              'PRECIO',
              textAlign: TextAlign.right,
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
              'SUBTOTAL',
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

  Widget _buildDetalleRow(PedidoDetalle det) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  det.productoNombre ?? 'Producto #${det.productoId}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                if (det.observacion != null && det.observacion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    det.observacion!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              det.cantidad % 1 == 0
                  ? det.cantidad.toInt().toString()
                  : det.cantidad.toStringAsFixed(3),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currencyFmt.format(det.precioUnitario),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currencyFmt.format(det.subtotal),
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
