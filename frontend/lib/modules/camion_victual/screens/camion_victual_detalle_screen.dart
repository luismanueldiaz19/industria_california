import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/camion_victual.dart';
import '../providers/camion_victual_provider.dart';
import '../widgets/pedido_en_camion_tile.dart';
import '../widgets/agregar_pedido_sheet.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import '../../pedido/providers/pedido_provider.dart';
import '../../pedido/widgets/pedido_detalle_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de detalle de un camión victual.
/// El vendedor puede:
///   - Ver todos los pedidos cargados ordenados por orden_viaje
///   - Agregar pedidos facturados (si el camión está en 'armando')
///   - Quitar pedidos (si el camión está en 'armando')
///   - Reordenar los pedidos con drag-and-drop (si el camión está en 'armando')
class CamionVictualDetalleScreen extends StatefulWidget {
  final int camionId;
  const CamionVictualDetalleScreen({super.key, required this.camionId});

  @override
  State<CamionVictualDetalleScreen> createState() =>
      _CamionVictualDetalleScreenState();
}

class _CamionVictualDetalleScreenState
    extends State<CamionVictualDetalleScreen> {
  static const _bgPrimary = AppTheme.bgColor;
  static const _azul = Color(0xFF1976D2);
  final _fmt = NumberFormat('#,##0.00', 'es');

  // Lista local para drag-and-drop (copia mutable de los pedidos del camión)
  List<CamionPedido> _pedidosLocales = [];
  bool _modoReorden = false;

  CamionVictual? get _camion {
    try {
      return context.read<CamionVictualProvider>().camiones.firstWhere(
        (c) => c.id == widget.camionId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarLocal();
    });
  }

  void _sincronizarLocal() {
    final camion = _camion;
    if (camion != null) {
      setState(() {
        _pedidosLocales = List.from(camion.pedidos);
      });
    }
  }

  Future<void> _refrescar() async {
    await context.read<CamionVictualProvider>().refreshCamion(widget.camionId);
    _sincronizarLocal();
  }

  void _abrirAgregarPedido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CamionVictualProvider>(),
        child: AgregarPedidoSheet(camionId: widget.camionId),
      ),
    ).then((_) {
      _refrescar();
    });
  }

  Future<void> _mostrarDetalle(CamionPedido p) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final pedidoReal = await context.read<PedidoProvider>().getPedidoById(p.id);
    if (!mounted) return;
    Navigator.pop(context); // cerrar loading
    if (pedidoReal != null) {
      showDialog(
        context: context,
        builder: (_) => PedidoDetalleDialog(pedido: pedidoReal),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el detalle del pedido'),
        ),
      );
    }
  }

  Future<void> _imprimirConduce() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final url = await context.read<CamionVictualProvider>().getConducePdfUrl(
        widget.camionId,
      );
      if (mounted) Navigator.pop(context);
      if (!await launchUrl(Uri.parse(url))) {
        throw 'No se pudo abrir el enlace';
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    }
  }

  Future<void> _quitarPedido(CamionPedido pedido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE53935),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quitar pedido',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Estás seguro de quitar el pedido #${pedido.id} de ${pedido.clienteNombre ?? 'este cliente'} del camión?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Quitar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmar != true) return;

    final ok = await context.read<CamionVictualProvider>().quitarPedido(
      widget.camionId,
      pedido.id,
    );
    if (!mounted) return;
    if (ok) {
      _sincronizarLocal();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido quitado del camión'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<CamionVictualProvider>().error ?? 'Error'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _guardarReorden() async {
    final ok = await context.read<CamionVictualProvider>().reordenar(
      widget.camionId,
      _pedidosLocales,
    );
    if (!mounted) return;
    setState(() => _modoReorden = false);
    if (ok && mounted) {
      _sincronizarLocal();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden guardado correctamente'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CamionVictualProvider>(
      builder: (_, provider, __) {
        final camion = provider.camiones.firstWhere(
          (c) => c.id == widget.camionId,
          orElse: () => CamionVictual(
            id: widget.camionId,
            choferID: 0,
            vendedorId: 0,
            nombre: 'Cargando...',
            slotNumero: 0,
            estado: 'armando',
            montoTotal: 0,
            minimoSalida: 0.0,
          ),
        );

        final puedeEditar = camion.puedeModificar;
        final progreso = provider.montoMinimo > 0
            ? (camion.montoTotal / provider.montoMinimo).clamp(0.0, 1.0)
            : 0.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Scaffold(
              backgroundColor: _bgPrimary,
              appBar: AppBar(
                backgroundColor: AppTheme.primaryBlue,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camion.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (camion.choferNombre != null)
                      Text(
                        'Chofer: ${camion.choferNombre}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.white),
                    tooltip: 'Imprimir Conduce',
                    onPressed: _imprimirConduce,
                  ),
                  // Botón de reordenar (solo en modo armando)
                  if (puedeEditar && _pedidosLocales.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        if (_modoReorden) {
                          _guardarReorden();
                        } else {
                          setState(() => _modoReorden = true);
                        }
                      },
                      icon: Icon(
                        _modoReorden ? Icons.save_outlined : Icons.reorder,
                        color: _modoReorden
                            ? const Color(0xFF4CAF50)
                            : Colors.white70,
                        size: 18,
                      ),
                      label: Text(
                        _modoReorden ? 'Guardar' : 'Ordenar',
                        style: TextStyle(
                          color: _modoReorden
                              ? const Color(0xFF4CAF50)
                              : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Center(
                      child: HeaderButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Actualizar',
                        onTap: _refrescar,
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // ── Panel de estado del camión ───────────────────
                  _buildInfoPanel(camion, provider.montoMinimo, progreso),

                  // ── Lista de pedidos ──────────────────────────────
                  Expanded(
                    child: provider.isActualizando
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: _azul),
                                SizedBox(height: 12),
                                Text(
                                  'Actualizando...',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          )
                        : _buildPedidosList(camion, puedeEditar),
                  ),
                ],
              ),
              // FAB: Agregar pedido (solo cuando el camión está en 'armando')
              floatingActionButton: puedeEditar && !_modoReorden
                  ? FloatingActionButton.extended(
                      onPressed: _abrirAgregarPedido,
                      backgroundColor: _azul,
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Agregar Pedido',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoPanel(
    CamionVictual camion,
    double montoMinimo,
    double progreso,
  ) {
    final falta = (montoMinimo - camion.montoTotal).clamp(0, double.infinity);
    final colorEstado = _colorEstado(camion.estado);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorEstado.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Monto total
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total cargado',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                  Text(
                    '\$${_fmt.format(camion.montoTotal)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Estado badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorEstado),
                ),
                child: Text(
                  _labelEstado(camion.estado),
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mín: \$${_fmt.format(montoMinimo)}',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
              if (falta > 0)
                Text(
                  'Falta \$${_fmt.format(falta)}',
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (camion.estado == 'armando')
                ElevatedButton.icon(
                  onPressed: () async {
                    final prov = context.read<CamionVictualProvider>();
                    try {
                      await prov.update(camion.id, {'estado': 'listo'});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Camión marcado como Listo'),
                          ),
                        );
                        _refrescar();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Marcar Listo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(110, 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                )
              else
                const Text(
                  '✓ Listo para salir',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progreso >= 1.0
                    ? const Color(0xFF4CAF50)
                    : progreso > 0.6
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFFE53935),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Resumen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip(
                'Pedidos',
                '${camion.pedidos.length}',
                Icons.receipt_long,
              ),
              _statChip(
                'Slot',
                '#${camion.slotNumero}',
                Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black38, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black38, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPedidosList(CamionVictual camion, bool puedeEditar) {
    if (_pedidosLocales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, color: Colors.black12, size: 64),
            const SizedBox(height: 12),
            const Text(
              'El camión está vacío',
              style: TextStyle(
                color: Colors.black38,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              puedeEditar
                  ? 'Toca el botón + para agregar pedidos facturados'
                  : 'No hay pedidos asignados a este camión',
              style: const TextStyle(color: Colors.black38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_modoReorden && puedeEditar) {
      // Modo drag-and-drop
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1976D2).withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.drag_handle, color: Color(0xFF1976D2), size: 16),
                SizedBox(width: 8),
                Text(
                  'Arrastra para cambiar el orden de entrega',
                  style: TextStyle(color: Color(0xFF1976D2), fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _pedidosLocales.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _pedidosLocales.removeAt(oldIndex);
                  _pedidosLocales.insert(newIndex, item);
                });
              },
              itemBuilder: (_, i) {
                final p = _pedidosLocales[i];
                return PedidoEnCamionTile(
                  key: ValueKey(p.id),
                  pedido: CamionPedido(
                    id: p.id,
                    clienteId: p.clienteId,
                    total: p.total,
                    estadoPedido: p.estadoPedido,
                    clienteNombre: p.clienteNombre,
                    clienteDireccion: p.clienteDireccion,
                    ordenViaje: i + 1, // mostrar el orden temporal
                    estadoEntrega: p.estadoEntrega,
                  ),
                  showDragHandle: true,
                  index: i,
                  onTap: () => _mostrarDetalle(p),
                );
              },
            ),
          ),
        ],
      );
    }

    // Vista normal
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _pedidosLocales.length,
      itemBuilder: (_, i) {
        final p = _pedidosLocales[i];
        return PedidoEnCamionTile(
          key: ValueKey(p.id),
          pedido: p,
          showDragHandle: false,
          onQuitar: puedeEditar ? () => _quitarPedido(p) : null,
          onTap: () => _mostrarDetalle(p),
        );
      },
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'armando':
        return const Color(0xFFFF9800);
      case 'listo':
        return const Color(0xFF4CAF50);
      case 'en_ruta':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'armando':
        return 'Armando';
      case 'listo':
        return '✓ Listo';
      case 'en_ruta':
        return '🚛 En Ruta';
      case 'cerrado':
        return 'Cerrado';
      default:
        return estado;
    }
  }
}
