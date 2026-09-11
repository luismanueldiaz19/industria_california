import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../logistica/models/pedido.dart';
import '../../logistica/models/pedido_detalle.dart';

/// Pantalla de detalle de un pedido existente.
/// Solo muestra — no edita directamente (navega a Form para eso).
class VendedorPedidoDetalleScreen extends StatelessWidget {
  final Pedido pedido;

  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);
  static final _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  static final _dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'es');

  static final Map<String, Color> _estadoColor = {
    'borrador': const Color(0xFFFF9800),
    'enviado': const Color(0xFF2196F3),
    'facturado': const Color(0xFF4CAF50),
    'cancelado': const Color(0xFFE53935),
  };

  const VendedorPedidoDetalleScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor[pedido.estado] ?? Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Pedido #${pedido.id}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(estadoColor),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildDetallesSection(),
            const SizedBox(height: 16),
            _buildTotalRow(),
            if (pedido.comentario != null && pedido.comentario!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildComentario(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color estadoColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL DEL PEDIDO',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFmt.format(pedido.total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _dateFmt.format(pedido.createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pedido.estado.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        children: [
          _infoRow(
            Icons.person_outline,
            'Cliente',
            pedido.clienteNombre ?? '—',
          ),
          const Divider(height: 24),
          _infoRow(Icons.map_outlined, 'Ruta', pedido.rutaNombre ?? 'Sin ruta'),
          const Divider(height: 24),
          _infoRow(
            Icons.person_pin_outlined,
            'Vendedor',
            pedido.vendedorNombre ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos',
          style: TextStyle(
            color: _primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        _card(
          child: Column(
            children: pedido.detalles.asMap().entries.map((e) {
              return Column(
                children: [
                  if (e.key > 0) const Divider(height: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    fontSize: 13,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${det.cantidad % 1 == 0 ? det.cantidad.toInt() : det.cantidad.toStringAsFixed(3)} × ${_currencyFmt.format(det.precioUnitario)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (det.observacion != null && det.observacion!.isNotEmpty)
                  Text(
                    det.observacion!,
                    style: TextStyle(
                      fontSize: 11,
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
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              _currencyFmt.format(pedido.total),
              style: const TextStyle(
                color: _accentBlue,
                fontSize: 20,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Comentario',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(pedido.comentario!, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accentBlue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
