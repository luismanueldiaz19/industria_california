import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../logistica/models/pedido.dart';
import '../../logistica/models/pedido_detalle.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../logistica/providers/pedido_provider.dart';
import 'vendedor_pedido_flow_screen.dart';

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
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.width > 500 ? 20 : 0,
              ),
              child: Scaffold(
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
                      if (pedido.comentario != null &&
                          pedido.comentario!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildComentario(),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color estadoColor) {
    final faltante = pedido.detalles.fold(
      0.0,
      (sum, det) => sum + (det.cantidadEnProduccion * det.precioUnitario),
    );
    final disponible = pedido.total - faltante;
    final hasFaltante = faltante > 0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasFaltante) ...[
                  const Text(
                    'TOTAL DISPONIBLE',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyFmt.format(disponible),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Original: ${_currencyFmt.format(pedido.total)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Faltante: ${_currencyFmt.format(faltante)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
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
                ],
                const SizedBox(height: 6),
                Text(
                  _dateFmt.format(pedido.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
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
            if (pedido.fechaEntrega != null) ...[
              const Divider(height: 8, thickness: 0.5),
              _infoRow(
                Icons.calendar_today_outlined,
                'Fecha de Entrega',
                DateFormat('dd/MM/yyyy').format(pedido.fechaEntrega!),
              ),
            ],
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
        if (pedido.detalles.any((d) => d.cantidadEnProduccion > 0)) ...[
          const SizedBox(height: 12),
          Consumer<PedidoProvider>(
            builder: (ctx, provider, _) {
              final alreadyGenerated = provider.pedidos.any(
                (p) =>
                    p.comentario ==
                    'Pedido generado por faltantes del Pedido #${pedido.id}',
              );

              if (alreadyGenerated) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pedido por faltante ya generado',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generarPedidoFaltante,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Generar Pedido por Faltante',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _generarPedidoFaltante() {
    // Collect the missing items
    final faltantes = pedido.detalles
        .where((d) => d.cantidadEnProduccion > 0)
        .toList();
    if (faltantes.isEmpty) return;

    // Create a mock order with ONLY the missing quantities
    final mockDetalles = faltantes
        .map(
          (f) => PedidoDetalle(
            id: 0,
            productoId: f.productoId,
            cantidad: f.cantidadEnProduccion,
            cantidadEnProduccion: 0,
            precioUnitario: f.precioUnitario,
            subtotal: f.cantidadEnProduccion * f.precioUnitario,
            observacion: 'Faltante del Pedido #${pedido.id}',
            productoNombre: f.productoNombre,
            productoCodigo: f.productoCodigo,
          ),
        )
        .toList();

    final mockPedido = Pedido(
      id: 0,
      clienteId: pedido.clienteId,
      rutaId: pedido.rutaId,
      vendedorId: pedido.vendedorId,
      estado: 'borrador',
      total: mockDetalles.fold(0, (sum, item) => sum + item.subtotal),
      createdAt: DateTime.now(),
      comentario: 'Pedido generado por faltantes del Pedido #${pedido.id}',
      detalles: mockDetalles,
    );

    // Navigating back first to prevent deep stacking (optional) or just push
    Navigator.of(context).pop();

    // We need to pass a flag to VendedorPedidoFlowScreen indicating it's a template, not an edit.
    // By passing a pedido with id: 0, it acts as a template.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VendedorPedidoFlowScreen(pedidoOriginal: mockPedido),
      ),
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
                Row(
                  children: [
                    Text(
                      '${det.cantidad % 1 == 0 ? det.cantidad.toInt() : det.cantidad.toStringAsFixed(3)} × ${_currencyFmt.format(det.precioUnitario)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (det.cantidadEnProduccion > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(Faltante: ${det.cantidadEnProduccion % 1 == 0 ? det.cantidadEnProduccion.toInt() : det.cantidadEnProduccion.toStringAsFixed(3)})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],
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
    final faltante = pedido.detalles.fold(
      0.0,
      (sum, det) => sum + (det.cantidadEnProduccion * det.precioUnitario),
    );
    final disponible = pedido.total - faltante;
    final hasFaltante = faltante > 0;

    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            if (hasFaltante) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Original',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    _currencyFmt.format(pedido.total),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diferencia (Faltante)',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                  Text(
                    '- ${_currencyFmt.format(faltante)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL A DESPACHAR',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _currencyFmt.format(disponible),
                    style: const TextStyle(
                      color: _accentBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
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
            ],
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
