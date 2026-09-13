import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../logistica/models/pedido.dart';
import '../../logistica/models/pedido_detalle.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../logistica/providers/pedido_provider.dart';

/// Pantalla de detalle de un pedido existente.
/// Solo muestra — no edita directamente (navega a Form para eso).
class VendedorPedidoDetalleScreen extends StatefulWidget {
  final Pedido pedido;

  const VendedorPedidoDetalleScreen({super.key, required this.pedido});

  @override
  State<VendedorPedidoDetalleScreen> createState() =>
      _VendedorPedidoDetalleScreenState();
}

class _VendedorPedidoDetalleScreenState
    extends State<VendedorPedidoDetalleScreen> {
  static const _primaryBlue = AppTheme.primaryBlue;
  static const _accentBlue = AppTheme.secondaryBlue;
  static final _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  static final _dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'es');

  static final Map<String, Color> _estadoColor = {
    'borrador': const Color(0xFFFF9800),
    'enviado': AppTheme.primaryBlue,
    'facturado': const Color(0xFF4CAF50),
    'cancelado': const Color(0xFFE53935),
  };

  Pedido get pedido => widget.pedido;

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
    final estadoColor = _estadoColor[pedido.estado] ?? Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 20),
        title: Text(
          'Pedido #${pedido.id}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                  ),
            tooltip: 'Ver Factura',
            onPressed: _isGeneratingPdf ? null : _generarPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(estadoColor),
            const SizedBox(height: 8),
            _buildInfoCard(),
            const SizedBox(height: 8),
            _buildDetallesSection(),
            const SizedBox(height: 8),
            _buildTotalRow(),
            if (pedido.comentario != null && pedido.comentario!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildComentario(),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color estadoColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, _accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL DEL PEDIDO',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                _currencyFmt.format(pedido.total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateFmt.format(pedido.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pedido.estado.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _infoRow(
              Icons.person_outline,
              'Cliente',
              pedido.clienteNombre ?? '—',
            ),
            const Divider(height: 8, thickness: 0.5),
            _infoRow(
              Icons.map_outlined,
              'Ruta',
              pedido.rutaNombre ?? 'Sin ruta',
            ),
            const Divider(height: 8, thickness: 0.5),
            _infoRow(
              Icons.person_pin_outlined,
              'Vendedor',
              pedido.vendedorNombre ?? '—',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'Productos',
            style: TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        _card(
          child: Column(
            children: pedido.detalles.asMap().entries.map((e) {
              return Column(
                children: [
                  if (e.key > 0) const Divider(height: 1, thickness: 0.5),
                  _buildDetalleTile(e.value),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleTile(PedidoDetalle det) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  det.productoNombre ?? 'Producto #${det.productoId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${det.cantidad % 1 == 0 ? det.cantidad.toInt() : det.cantidad.toStringAsFixed(3)} × ${_currencyFmt.format(det.precioUnitario)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (det.observacion != null && det.observacion!.isNotEmpty)
                  Text(
                    det.observacion!,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _currencyFmt.format(det.subtotal),
            style: const TextStyle(
              color: _accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              _currencyFmt.format(pedido.total),
              style: const TextStyle(
                color: _accentBlue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComentario() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comentario',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(pedido.comentario!, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _accentBlue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
