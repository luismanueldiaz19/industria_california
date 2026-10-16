import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/cancel_button.dart';
import '../../../core/widgets/custom_button.dart';
import '../../pedido/models/pedido.dart';
import '../../pedido/models/pedido_detalle.dart';
import '../models/orden_produccion.dart';
import '../providers/orden_produccion_provider.dart';

class OrdenProduccionPedidoDialog extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onUpdated;

  const OrdenProduccionPedidoDialog({
    super.key,
    required this.pedido,
    required this.onUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required Pedido pedido,
    required VoidCallback onUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          OrdenProduccionPedidoDialog(pedido: pedido, onUpdated: onUpdated),
    );
  }

  @override
  State<OrdenProduccionPedidoDialog> createState() =>
      _OrdenProduccionPedidoDialogState();
}

class _OrdenProduccionPedidoDialogState
    extends State<OrdenProduccionPedidoDialog> {
  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  bool _isLoading = true;
  bool _isGenerating = false;
  OrdenProduccion? _orden;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarOrden();
  }

  Future<void> _cargarOrden() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<OrdenProduccionProvider>();
      final op = await provider.getOrdenByPedidoId(widget.pedido.id);
      if (mounted) {
        setState(() {
          _orden = op;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generarOrdenProduccion() async {
    setState(() => _isGenerating = true);
    try {
      final provider = context.read<OrdenProduccionProvider>();
      final ok = await provider.generarOrdenDesdePedido(widget.pedido.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden de Producción generada exitosamente'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
        await _cargarOrden();
        widget.onUpdated();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'No se pudo generar la orden de producción',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'lista':
      case 'listo':
        return Colors.green;
      case 'en_proceso':
        return Colors.orange;
      case 'pendiente':
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final faltantesDetalles = widget.pedido.detalles
        .where((d) => d.cantidadEnProduccion > 0)
        .toList();

    return Dialog(
      backgroundColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.darkBorderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkInputColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.darkBorderColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orden != null
                              ? 'Orden de Producción #OP-${_orden!.id}'
                              : 'Orden de Producción - Pedido #${widget.pedido.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pedido Asociado: #${widget.pedido.id} • ${widget.pedido.clienteNombre ?? "Sin Cliente"}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_orden != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(
                          _orden!.estado,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getEstadoColor(
                            _orden!.estado,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _orden!.estado.toUpperCase(),
                        style: TextStyle(
                          color: _getEstadoColor(_orden!.estado),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── BODY ──
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE31E24),
                        ),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildContenido(faltantesDetalles),
            ),

            // ── FOOTER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkInputColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.darkBorderColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CancelButton(
                    text: 'CERRAR',
                    onPressed: _isGenerating
                        ? null
                        : () => Navigator.pop(context),
                    isDark: true,
                    height: 32,
                    borderRadius: 6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  if (_orden == null && faltantesDetalles.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    CustomButton(
                      text: _isGenerating
                          ? 'GENERANDO...'
                          : 'GENERAR ORDEN DE PRODUCCIÓN',
                      icon: Icons.precision_manufacturing_rounded,
                      color: Colors.amber,
                      textColor: Colors.black87,
                      isLoading: _isGenerating,
                      height: 32,
                      fontSize: 11,
                      borderRadius: 6,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      onPressed: _isGenerating ? null : _generarOrdenProduccion,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(List<PedidoDetalle> faltantesDetalles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_orden == null && faltantesDetalles.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este pedido tiene faltantes de inventario pendientes de enviar a planta. Haz clic en "Generar Orden de Producción" para iniciar su fabricación.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkInputColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.darkBorderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Cliente',
                        widget.pedido.clienteNombre ?? 'N/A',
                        Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoItem(
                        'Vendedor',
                        widget.pedido.vendedorNombre ?? 'N/A',
                        Icons.badge_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Ruta',
                        widget.pedido.rutaNombre ?? 'Sin Asignar',
                        Icons.local_shipping_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoItem(
                        'F. Entrega Estimada',
                        widget.pedido.fechaEntrega != null
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(widget.pedido.fechaEntrega!)
                            : 'No definida',
                        Icons.calendar_today_rounded,
                      ),
                    ),
                  ],
                ),
                if (widget.pedido.notaProduccion != null &&
                    widget.pedido.notaProduccion!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildInfoItem(
                      'Instrucciones de Planta',
                      widget.pedido.notaProduccion!,
                      Icons.note_alt_rounded,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Título de la tabla
          Row(
            children: [
              const Icon(
                Icons.format_list_bulleted_rounded,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'ÍTEMS A FABRICAR (FALTANTES)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_orden != null)
                Text(
                  '${_orden!.detalles.length} ítem(s)',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                )
              else
                Text(
                  '${faltantesDetalles.length} ítem(s)',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Tabla de detalles
          if (_orden != null && _orden!.detalles.isNotEmpty)
            ..._orden!.detalles.map((d) => _buildOpDetalleTile(d))
          else if (faltantesDetalles.isNotEmpty)
            ...faltantesDetalles.map((f) => _buildFaltanteTile(f))
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkInputColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No hay faltantes registrados para este pedido.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpDetalleTile(OrdenProduccionDetalle detalle) {
    final isListo = detalle.estado == 'listo';
    final color = _getEstadoColor(detalle.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.producto?.nombreCompleto ??
                      detalle.producto?.descripcion ??
                      'Producto #${detalle.productoId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Faltante: ${detalle.cantidadFaltante % 1 == 0 ? detalle.cantidadFaltante.toInt() : detalle.cantidadFaltante}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Producido: ${detalle.cantidadProducida % 1 == 0 ? detalle.cantidadProducida.toInt() : detalle.cantidadProducida}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              detalle.estado.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isListo) ...[
            const SizedBox(width: 8),
            CustomButton(
              text: 'LISTO',
              icon: Icons.check,
              color: Colors.green,
              height: 28,
              fontSize: 10,
              borderRadius: 4,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onPressed: () async {
                final provider = context.read<OrdenProduccionProvider>();
                final ok = await provider.marcarDetalleListo(detalle.id);
                if (ok && mounted) {
                  _cargarOrden();
                  widget.onUpdated();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaltanteTile(PedidoDetalle det) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  det.productoNombre ?? 'Producto #${det.productoId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Faltante a Producir: ${det.cantidadEnProduccion % 1 == 0 ? det.cantidadEnProduccion.toInt() : det.cantidadEnProduccion} (${_currencyFmt.format(det.cantidadEnProduccion * det.precioUnitario)})',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'PENDIENTE',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
