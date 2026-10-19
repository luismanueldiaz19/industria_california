import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';
import '../../../pedido/providers/pedido_provider.dart';
import '../../../pedido/widgets/pedido_detalle_dialog.dart';
import '../camiones/camion_victual_form_modal.dart';
import 'despacho_agregar_pedidos_modal.dart';
import 'despacho_cambiar_chofer_dialog.dart';
import 'despacho_en_ruta_dialog.dart';
import 'despacho_liquidacion_dialog.dart';

class DespachoCamionDetallePanel extends StatefulWidget {
  final CamionVictual camion;
  final VoidCallback onCamionUpdated;

  const DespachoCamionDetallePanel({
    super.key,
    required this.camion,
    required this.onCamionUpdated,
  });

  @override
  State<DespachoCamionDetallePanel> createState() =>
      _DespachoCamionDetallePanelState();
}

class _DespachoCamionDetallePanelState
    extends State<DespachoCamionDetallePanel> {
  final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  bool _isReordering = false;
  List<CamionPedido> _pedidosLocales = [];

  @override
  void initState() {
    super.initState();
    _sincronizarPedidos();
  }

  @override
  void didUpdateWidget(covariant DespachoCamionDetallePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camion.id != widget.camion.id ||
        oldWidget.camion.estado != widget.camion.estado ||
        oldWidget.camion.pedidos != widget.camion.pedidos) {
      _sincronizarPedidos();
    }
  }

  void _sincronizarPedidos() {
    _pedidosLocales = List.from(widget.camion.pedidos)
      ..sort((a, b) => a.ordenViaje.compareTo(b.ordenViaje));
  }

  Future<void> _imprimirConduce() async {
    try {
      final provider = context.read<CamionVictualProvider>();
      final urlStr = await provider.getConducePdfUrl(widget.camion.id);
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace del Conduce');
      }
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showError(context, 'Error al abrir Conduce: $e');
    }
  }

  Future<void> _marcarListo() async {
    if (widget.camion.montoTotal < widget.camion.minimoSalida) {
      final falta = widget.camion.minimoSalida - widget.camion.montoTotal;
      CompactSnackBar.showError(
        context,
        'No alcanza el mínimo de salida. Faltan ${_currencyFmt.format(falta)}',
      );
      return;
    }

    final provider = context.read<CamionVictualProvider>();
    try {
      await provider.update(widget.camion.id, {'estado': 'listo'});
      if (!mounted) return;
      CompactSnackBar.showSuccess(context, 'Camión marcado como LISTO');
      widget.onCamionUpdated();
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showError(context, 'Error: $e');
    }
  }

  Future<void> _ponerEnRuta() async {
    if (widget.camion.pedidos.isEmpty || widget.camion.montoTotal <= 0) {
      CompactSnackBar.showError(
        context,
        'No se puede despachar un camión sin pedidos asignados.',
      );
      return;
    }

    if (widget.camion.montoTotal < widget.camion.minimoSalida) {
      final falta = widget.camion.minimoSalida - widget.camion.montoTotal;
      CompactSnackBar.showError(
        context,
        'No alcanza el mínimo de salida (${_currencyFmt.format(widget.camion.minimoSalida)}). Faltan ${_currencyFmt.format(falta)}.',
      );
      return;
    }

    final despachado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DespachoEnRutaDialog(camion: widget.camion),
    );

    if (despachado == true && mounted) {
      widget.onCamionUpdated();
    }
  }

  Future<void> _cerrarCamion() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => DespachoLiquidacionDialog(camion: widget.camion),
    );
    if (ok == true && mounted) {
      widget.onCamionUpdated();
    }
  }

  Future<void> _vaciarCamion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Vaciar Camión',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: const Text(
          '¿Está seguro de remover todos los pedidos asignados a este camión virtual?',
          style: TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Vaciar Todo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.vaciarCamion(widget.camion.id);
    if (!mounted) return;
    if (ok) {
      CompactSnackBar.showSuccess(context, 'Camión vaciado');
      widget.onCamionUpdated();
    } else {
      CompactSnackBar.showError(context, provider.error ?? 'Error');
    }
  }

  Future<void> _quitarPedido(CamionPedido p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Quitar Pedido',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          '¿Remover el pedido #${p.id} (${p.clienteNombre ?? "Cliente"}) de este camión?',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.quitarPedido(widget.camion.id, p.id);
    if (!mounted) return;
    if (ok) {
      CompactSnackBar.showSuccess(context, 'Pedido removido del camión');
      widget.onCamionUpdated();
    } else {
      CompactSnackBar.showError(context, provider.error ?? 'Error');
    }
  }

  Future<void> _guardarReorden() async {
    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.reordenar(widget.camion.id, _pedidosLocales);
    if (!mounted) return;
    setState(() => _isReordering = false);
    if (ok) {
      CompactSnackBar.showSuccess(context, 'Orden de viaje actualizado');
      widget.onCamionUpdated();
    } else {
      CompactSnackBar.showError(
        context,
        provider.error ?? 'Error al reordenar',
      );
    }
  }

  Future<void> _cambiarEstadoEntrega(
    CamionPedido pedido,
    String nuevoEstado,
  ) async {
    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.actualizarEntrega(
      widget.camion.id,
      pedido.id,
      nuevoEstado,
    );
    if (!mounted) return;
    if (ok) {
      CompactSnackBar.showSuccess(
        context,
        'Entrega actualizada: ${nuevoEstado.toUpperCase()}',
      );
      widget.onCamionUpdated();
    } else {
      CompactSnackBar.showError(context, provider.error ?? 'Error');
    }
  }

  Future<void> _verDetallePedido(CamionPedido p) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE31E24)),
      ),
    );
    final pedidoReal = await context.read<PedidoProvider>().getPedidoById(p.id);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (pedidoReal != null) {
      showDialog(
        context: context,
        builder: (_) => PedidoDetalleDialog(pedido: pedidoReal),
      );
    } else {
      CompactSnackBar.showError(
        context,
        'No se pudo cargar el detalle del pedido',
      );
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'vacio':
        return const Color(0xFF64748B);
      case 'armando':
        return const Color(0xFFD97706);
      case 'listo':
        return const Color(0xFF16A34A);
      case 'en_ruta':
        return const Color(0xFF2563EB);
      case 'cerrado':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _colorEntrega(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFD97706);
      case 'en_curso':
        return const Color(0xFF2563EB);
      case 'entregado':
        return const Color(0xFF16A34A);
      case 'fallido':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildHeaderActionButtons(CamionVictual camion) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Imprimir Conduce
        ElevatedButton.icon(
          onPressed: _imprimirConduce,
          icon: const Icon(Icons.picture_as_pdf, size: 14),
          label: const Text('Conduce PDF', style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: const Color(0xFF334155),
            elevation: 0,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),

        // Workflow buttons based on state
        if (camion.estado == 'armando') ...[
          () {
            final bool cumpleMinimo =
                camion.pedidos.isNotEmpty &&
                camion.montoTotal >= camion.minimoSalida;
            final double falta = (camion.minimoSalida - camion.montoTotal)
                .clamp(0.0, double.infinity);

            return Tooltip(
              message: cumpleMinimo
                  ? 'Marcar como listo para salir'
                  : 'Faltan ${_currencyFmt.format(falta)} para alcanzar el mínimo de salida',
              child: ElevatedButton.icon(
                onPressed: _marcarListo,
                icon: const Icon(Icons.check_circle, size: 14),
                label: const Text(
                  'Marcar Listo',
                  style: TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cumpleMinimo
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          }(),
        ],

        if (camion.estado == 'listo' || camion.estado == 'armando') ...[
          () {
            final bool puedeDespachar =
                camion.pedidos.isNotEmpty &&
                camion.montoTotal >= camion.minimoSalida;
            final double falta = (camion.minimoSalida - camion.montoTotal)
                .clamp(0.0, double.infinity);

            return Tooltip(
              message: puedeDespachar
                  ? 'Despachar camión a ruta logística'
                  : 'Faltan ${_currencyFmt.format(falta)} para alcanzar el mínimo de salida',
              child: ElevatedButton.icon(
                onPressed: _ponerEnRuta,
                icon: const Icon(Icons.departure_board, size: 14),
                label: const Text(
                  'Despachar / En Ruta',
                  style: TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: puedeDespachar
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          }(),
        ],

        if (camion.estado == 'en_ruta' ||
            camion.estado == 'listo' ||
            (camion.estado == 'cerrado' && camion.pedidos.isNotEmpty))
          ElevatedButton.icon(
            onPressed: _cerrarCamion,
            icon: const Icon(Icons.receipt_long, size: 14),
            label: const Text(
              'Liquidar Viaje',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderPopupMenu(CamionVictual camion) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 18),
      color: Colors.white,
      onSelected: (val) {
        if (val == 'liquidar') _cerrarCamion();
        if (val == 'vaciar') _vaciarCamion();
        if (val == 'editar') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CamionVictualFormModal(camion: camion),
          ).then((_) => widget.onCamionUpdated());
        }
      },
      itemBuilder: (_) => [
        if (camion.pedidos.isNotEmpty)
          const PopupMenuItem(
            value: 'liquidar',
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFFEA580C), size: 16),
                SizedBox(width: 8),
                Text(
                  'Liquidar Viaje',
                  style: TextStyle(color: Color(0xFFEA580C), fontSize: 12),
                ),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF475569), size: 16),
              SizedBox(width: 8),
              Text(
                'Editar Datos',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'vaciar',
          child: Row(
            children: [
              Icon(Icons.delete_sweep, color: Color(0xFFDC2626), size: 16),
              SizedBox(width: 8),
              Text(
                'Vaciar Camión',
                style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final camion = widget.camion;
    final estadoColor = _colorEstado(camion.estado);
    final double progreso = camion.minimoSalida > 0
        ? (camion.montoTotal / camion.minimoSalida).clamp(0.0, 1.0)
        : 0.0;
    final double falta = (camion.minimoSalida - camion.montoTotal).clamp(
      0.0,
      double.infinity,
    );

    final pedidosEntregados = camion.pedidos
        .where((p) => p.estadoEntrega == 'entregado')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        return Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              // ── Header Superior del Camión ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: estadoColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            color: estadoColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    camion.nombre.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: estadoColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: estadoColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      camion.estado.toUpperCase(),
                                      style: TextStyle(
                                        color: estadoColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge,
                                    size: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Slot #${camion.slotNumero}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (camion.vendedorNombre != null) ...[
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.storefront,
                                      size: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vend: ${camion.vendedorNombre}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (!isCompact) ...[
                          const SizedBox(width: 8),
                          _buildHeaderActionButtons(camion),
                          const SizedBox(width: 4),
                          _buildHeaderPopupMenu(camion),
                        ] else
                          _buildHeaderPopupMenu(camion),
                      ],
                    ),

                    if (isCompact) ...[
                      const SizedBox(height: 8),
                      _buildHeaderActionButtons(camion),
                    ],
                    const SizedBox(height: 10),

                    // Driver Strip with Quick Assignment Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFFE31E24),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Conductor:',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              camion.choferNombre ?? 'SIN ASIGNAR',
                              style: TextStyle(
                                color: camion.choferNombre != null
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    DespachoCambiarChoferDialog(camion: camion),
                              ).then((val) {
                                if (val == true) widget.onCamionUpdated();
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE31E24,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.swap_horiz,
                                    color: Color(0xFFE31E24),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    constraints.maxWidth < 460
                                        ? 'Cambiar'
                                        : 'Asignar / Cambiar Chofer',
                                    style: const TextStyle(
                                      color: Color(0xFFE31E24),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (camion.vehiculoFicha != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_shipping,
                              color: Color(0xFF2563EB),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Vehículo Físico:',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                camion.vehiculoFicha!,
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${camion.vehiculoMarca ?? ''} ${camion.vehiculoModelo ?? ''} ${camion.vehiculoPlaca != null ? '(${camion.vehiculoPlaca})' : ''}'.trim(),
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Panel Financiero y Progreso ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: constraints.maxWidth < 620
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Facturado Cargado',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    _currencyFmt.format(camion.montoTotal),
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '${camion.pedidos.length}',
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Text(
                                          'Pedidos',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                        Text(
                                          '$pedidosEntregados',
                                          style: const TextStyle(
                                            color: Color(0xFF16A34A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Text(
                                          'Entregados',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Mínimo: ${_currencyFmt.format(camion.minimoSalida)}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                falta > 0
                                    ? 'Faltan ${_currencyFmt.format(falta)}'
                                    : '✓ Mínimo Alcanzado',
                                style: TextStyle(
                                  color: falta > 0
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF16A34A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progreso,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progreso >= 1.0
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Total Facturado Cargado
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Facturado Cargado',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _currencyFmt.format(camion.montoTotal),
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Barra de Progreso
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Mínimo: ${_currencyFmt.format(camion.minimoSalida)}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      falta > 0
                                          ? 'Faltan ${_currencyFmt.format(falta)}'
                                          : '✓ Mínimo Alcanzado',
                                      style: TextStyle(
                                        color: falta > 0
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF16A34A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progreso,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progreso >= 1.0
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Contador
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '${camion.pedidos.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      'Pedidos',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  children: [
                                    Text(
                                      '$pedidosEntregados',
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      'Entregados',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              // ── Acciones de Pedidos en Camión ─────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.list_alt,
                      color: Color(0xFF475569),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        constraints.maxWidth < 480
                            ? 'PEDIDOS (${camion.pedidos.length})'
                            : 'PEDIDOS ASIGNADOS A ESTE CAMIÓN',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cargar Pedidos Facturados (solo si el camión está armando o listo)
                    if (camion.estado != 'cerrado' &&
                        camion.estado != 'en_ruta')
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                DespachoAgregarPedidosModal(camion: camion),
                          ).then((_) => widget.onCamionUpdated());
                        },
                        icon: const Icon(Icons.playlist_add, size: 14),
                        label: Text(
                          constraints.maxWidth < 420
                              ? 'Cargar'
                              : 'Cargar Facturados',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    if (camion.estado != 'cerrado' &&
                        camion.estado != 'en_ruta')
                      const SizedBox(width: 8),

                    // Reordenar Ruta Button
                    if (camion.pedidos.length > 1 &&
                        camion.estado != 'cerrado' &&
                        camion.estado != 'en_ruta')
                      OutlinedButton.icon(
                        onPressed: () {
                          if (_isReordering) {
                            _guardarReorden();
                          } else {
                            setState(() => _isReordering = true);
                          }
                        },
                        icon: Icon(
                          _isReordering ? Icons.save : Icons.swap_vert,
                          size: 14,
                          color: _isReordering
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF475569),
                        ),
                        label: Text(
                          constraints.maxWidth < 450
                              ? (_isReordering ? 'Guardar' : 'Ruta')
                              : (_isReordering ? 'Guardar Orden' : 'Reordenar'),
                          style: TextStyle(
                            fontSize: 11,
                            color: _isReordering
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF475569),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: _isReordering
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Banner Informativo de Liquidación (cuando está en ruta o cerrado con pedidos) ──
              if ((camion.estado == 'en_ruta' || camion.estado == 'cerrado') &&
                  camion.pedidos.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: camion.estado == 'cerrado'
                        ? const Color(0xFFFEF2F2)
                        : (pedidosEntregados == camion.pedidos.length &&
                                  camion.pedidos.isNotEmpty
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFFF7ED)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: camion.estado == 'cerrado'
                          ? const Color(0xFFFECACA)
                          : (pedidosEntregados == camion.pedidos.length &&
                                    camion.pedidos.isNotEmpty
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDBA74)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        camion.estado == 'cerrado'
                            ? Icons.assignment_late_outlined
                            : (pedidosEntregados == camion.pedidos.length &&
                                      camion.pedidos.isNotEmpty
                                  ? Icons.check_circle_outline
                                  : Icons.local_shipping_outlined),
                        color: camion.estado == 'cerrado'
                            ? const Color(0xFFDC2626)
                            : (pedidosEntregados == camion.pedidos.length &&
                                      camion.pedidos.isNotEmpty
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEA580C)),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              camion.estado == 'cerrado'
                                  ? 'Camión cerrado pendiente de liquidar (${camion.pedidos.length} pedidos)'
                                  : (pedidosEntregados ==
                                                camion.pedidos.length &&
                                            camion.pedidos.isNotEmpty
                                        ? '¡Todos los pedidos han sido entregados!'
                                        : 'Viaje en ruta ($pedidosEntregados/${camion.pedidos.length} entregados)'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: camion.estado == 'cerrado'
                                    ? const Color(0xFFB91C1C)
                                    : (pedidosEntregados ==
                                                  camion.pedidos.length &&
                                              camion.pedidos.isNotEmpty
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF9A3412)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              camion.estado == 'cerrado'
                                  ? 'Haz clic en "Liquidar Viaje" para asentar los gastos y liberar el camión a VACÍO.'
                                  : 'Haz clic en "Liquidar Viaje" para registrar los gastos (combustible, viáticos), ayudantes y liberar el camión.',
                              style: TextStyle(
                                fontSize: 10,
                                color: camion.estado == 'cerrado'
                                    ? const Color(0xFF991B1B)
                                    : (pedidosEntregados ==
                                                  camion.pedidos.length &&
                                              camion.pedidos.isNotEmpty
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF7C2D12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _cerrarCamion,
                        icon: const Icon(Icons.receipt_long, size: 14),
                        label: const Text(
                          'Liquidar Viaje',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Lista / Tabla Interactiva de Pedidos ─────────────────────
              Expanded(
                child: _pedidosLocales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No hay pedidos cargados en este camión virtual',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DespachoAgregarPedidosModal(
                                    camion: camion,
                                  ),
                                ).then((_) => widget.onCamionUpdated());
                              },
                              icon: const Icon(
                                Icons.playlist_add,
                                size: 14,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Cargar Pedidos Facturados',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _isReordering
                    ? ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pedidosLocales.length,
                        onReorderItem: (oldIdx, newIdx) {
                          setState(() {
                            final item = _pedidosLocales.removeAt(oldIdx);
                            _pedidosLocales.insert(newIdx, item);
                          });
                        },
                        itemBuilder: (context, idx) {
                          final p = _pedidosLocales[idx];
                          return Container(
                            key: ValueKey(p.id),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.drag_indicator,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Parada #${idx + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.clienteNombre ??
                                            'Cliente #${p.clienteId}',
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (p.clienteDireccion != null)
                                        Text(
                                          p.clienteDireccion!,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _currencyFmt.format(p.total),
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pedidosLocales.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, idx) {
                          final p = _pedidosLocales[idx];
                          final entregaColor = _colorEntrega(p.estadoEntrega);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fila 1: Parada # + Cliente + Factura + Total Facturado
                                Row(
                                  children: [
                                    // Trip stop number
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF334155),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Cliente y Factura
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              p.clienteNombre ??
                                                  'Cliente #${p.clienteId}',
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (p.numFactura != null &&
                                              p.numFactura!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFBFDBFE,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                'Fac: ${p.numFactura}',
                                                style: const TextStyle(
                                                  color: Color(0xFF1D4ED8),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Monto Total
                                    Text(
                                      _currencyFmt.format(p.total),
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Fila 2: Subtítulo (Pedido # y dirección) + Estado de Entrega + Acciones
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 30,
                                    ), // Alineación con texto de Fila 1 (22 + 8)
                                    // Pedido # y Dirección
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            'Pedido #${p.id}',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (p.clienteDireccion != null &&
                                              p
                                                  .clienteDireccion!
                                                  .isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.place,
                                              size: 11,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                p.clienteDireccion!,
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Interactive Delivery Status Dropdown
                                    PopupMenuButton<String>(
                                      tooltip: 'Cambiar Estado de Entrega',
                                      color: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      onSelected: (val) =>
                                          _cambiarEstadoEntrega(p, val),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: entregaColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: entregaColor.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              p.estadoEntrega == 'entregado'
                                                  ? Icons.check_circle
                                                  : (p.estadoEntrega ==
                                                            'fallido'
                                                        ? Icons.cancel
                                                        : (p.estadoEntrega ==
                                                                  'en_curso'
                                                              ? Icons
                                                                    .local_shipping
                                                              : Icons
                                                                    .access_time)),
                                              color: entregaColor,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              p.estadoEntrega
                                                  .toUpperCase()
                                                  .replaceAll('_', ' '),
                                              style: TextStyle(
                                                color: entregaColor,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 1),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: entregaColor,
                                              size: 13,
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'pendiente',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color: Color(0xFFD97706),
                                                size: 14,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Pendiente',
                                                style: TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'en_curso',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.local_shipping,
                                                color: Color(0xFF2563EB),
                                                size: 14,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'En Curso',
                                                style: TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'entregado',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF16A34A),
                                                size: 14,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Entregado',
                                                style: TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'fallido',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.cancel,
                                                color: Color(0xFFDC2626),
                                                size: 14,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Fallido',
                                                style: TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),

                                    // Botón Ver Detalle
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 15,
                                        color: Color(0xFF64748B),
                                      ),
                                      tooltip: 'Ver Detalle del Pedido',
                                      onPressed: () => _verDetallePedido(p),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 2),

                                    // Botón Quitar del Camión
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 15,
                                        color: Color(0xFFDC2626),
                                      ),
                                      tooltip: 'Quitar del Camión',
                                      onPressed: () => _quitarPedido(p),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
