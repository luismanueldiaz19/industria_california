import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../vendedor/widgets/vendedor_mobile_wrapper.dart';
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

  // MobileWrapper
  void _abrirAgregarPedido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 450),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CamionVictualProvider>(),
        child: AgregarPedidoSheet(camionId: widget.camionId, camion: _camion),
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
      CompactSnackBar.showError(
        context,
        'No se pudo cargar el detalle del pedido',
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
        CompactSnackBar.showError(context, 'Error al generar PDF: $e');
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
    if (confirmar != true || !mounted) return;

    final prov = context.read<CamionVictualProvider>();
    final ok = await prov.quitarPedido(widget.camionId, pedido.id);
    if (!mounted) return;
    if (ok) {
      _sincronizarLocal();
      CompactSnackBar.showSuccess(context, 'Pedido quitado del camión');
    } else {
      CompactSnackBar.showError(context, prov.error ?? 'Error');
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
      CompactSnackBar.showSuccess(context, 'Orden guardado correctamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CamionVictualProvider>(
      builder: (context, provider, child) {
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

        return MobileWrapper(
          child: Scaffold(
            body: Column(
              children: [
                // ── Encabezado general del camión ───────────────────
                GeneralHeader(
                  title: camion.nombre,
                  icon: Icons.local_shipping_outlined,
                  onBackPressed: () => Navigator.pop(context),
                  gradientColors: [
                    AppTheme.primaryBlue,
                    AppTheme.secondaryBlue,
                  ],
                  actions: [
                    HeaderButton(
                      icon: Icons.print,
                      tooltip: 'Imprimir Conduce',
                      onTap: _imprimirConduce,
                    ),
                    if (puedeEditar && _pedidosLocales.isNotEmpty)
                      HeaderButton(
                        icon: _modoReorden
                            ? Icons.save_outlined
                            : Icons.reorder,
                        tooltip: _modoReorden ? 'Guardar' : 'Ordenar',
                        color: _modoReorden
                            ? const Color(0xFF4CAF50)
                            : Colors.white70,
                        onTap: () {
                          if (_modoReorden) {
                            _guardarReorden();
                          } else {
                            setState(() => _modoReorden = true);
                          }
                        },
                      ),
                    HeaderButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Actualizar',
                      onTap: _refrescar,
                    ),
                  ],
                ),

                // ── Strip de Conductor ────────────────────────────
                _buildConductorStrip(camion),

                // ── Strip de Vehículo Físico ──────────────────────
                _buildVehiculoFisicoStrip(camion),

                // ── Panel Financiero y Progreso (Summary Card) ────
                _buildInfoPanel(camion, provider.montoMinimo, progreso),

                // ── Banner de Viaje en Ruta (cuando en_ruta o cerrado)
                if (camion.estado == 'en_ruta' || camion.estado == 'cerrado')
                  _buildViajeEnRutaBanner(camion),

                // ── Encabezado de la Sección de Pedidos ────────────
                _buildSeccionPedidosHeader(camion),

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
        );
      },
    );
  }

  Widget _buildConductorStrip(CamionVictual camion) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculoFisicoStrip(CamionVictual camion) {
    final bool tieneVehiculo =
        camion.vehiculoFicha != null || camion.vehiculoPlaca != null;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tieneVehiculo ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tieneVehiculo
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping,
            color: tieneVehiculo
                ? const Color(0xFF2563EB)
                : const Color(0xFF94A3B8),
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
          if (tieneVehiculo) ...[
            if (camion.vehiculoFicha != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
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
            ],
            Expanded(
              child: Text(
                '${camion.vehiculoMarca ?? ''} ${camion.vehiculoModelo ?? ''} ${camion.vehiculoPlaca != null ? '(${camion.vehiculoPlaca})' : ''}'
                    .trim(),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Sin asignar por Despacho',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(
    CamionVictual camion,
    double montoMinimo,
    double progreso,
  ) {
    final falta = (montoMinimo - camion.montoTotal).clamp(0, double.infinity);
    final colorEstado = _colorEstado(camion.estado);
    final pedidosEntregados = camion.pedidos
        .where((p) => p.estadoEntrega.toLowerCase() == 'entregado')
        .length;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila 1: Monto Total + Contador (Pedidos / Entregados)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Facturado Cargado',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                    ),
                  ),
                  Text(
                    '\$${_fmt.format(camion.montoTotal)}',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Contador de Pedidos y Entregados
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const SizedBox(height: 8),

          // Fila 2: Mínimo y Estado de Mínimo / Botón Marcar Listo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Mínimo: \$${_fmt.format(montoMinimo)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (falta > 0)
                Text(
                  'Falta \$${_fmt.format(falta)}',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  '✓ Mínimo Alcanzado',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),

          // Barra de Progreso
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
          const SizedBox(height: 8),

          // Fila 3: Slot, Vendedor y Estado Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _statChip(
                    'Slot',
                    '#${camion.slotNumero}',
                    Icons.inventory_2_outlined,
                  ),
                  if (camion.vendedorNombre != null) ...[
                    const SizedBox(width: 10),
                    _statChip('Vend', camion.vendedorNombre!, Icons.storefront),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorEstado.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _labelEstado(camion.estado),
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViajeEnRutaBanner(CamionVictual camion) {
    final pedidosEntregados = camion.pedidos
        .where((p) => p.estadoEntrega.toLowerCase() == 'entregado')
        .length;
    final bool todosEntregados =
        pedidosEntregados == camion.pedidos.length && camion.pedidos.isNotEmpty;
    final bool esCerrado = camion.estado == 'cerrado';

    final Color bgColor = esCerrado
        ? const Color(0xFFFEF2F2)
        : (todosEntregados
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF7ED));

    final Color borderColor = esCerrado
        ? const Color(0xFFFECACA)
        : (todosEntregados
            ? const Color(0xFF86EFAC)
            : const Color(0xFFFDBA74));

    final Color iconColor = esCerrado
        ? const Color(0xFFDC2626)
        : (todosEntregados
            ? const Color(0xFF16A34A)
            : const Color(0xFFEA580C));

    final Color titleColor = esCerrado
        ? const Color(0xFFB91C1C)
        : (todosEntregados
            ? const Color(0xFF15803D)
            : const Color(0xFF9A3412));

    final Color subColor = esCerrado
        ? const Color(0xFF991B1B)
        : (todosEntregados
            ? const Color(0xFF166534)
            : const Color(0xFF7C2D12));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            esCerrado
                ? Icons.assignment_late_outlined
                : (todosEntregados
                    ? Icons.check_circle_outline
                    : Icons.local_shipping_outlined),
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esCerrado
                      ? 'Camión cerrado (${camion.pedidos.length} pedidos)'
                      : (todosEntregados
                          ? '¡Todos los pedidos han sido entregados!'
                          : 'Viaje en ruta ($pedidosEntregados/${camion.pedidos.length} entregados)'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  esCerrado
                      ? 'El viaje ha finalizado y cerrado por despacho.'
                      : 'Seguimiento de entregas en tiempo real.',
                  style: TextStyle(
                    fontSize: 10,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPedidosHeader(CamionVictual camion) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
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
              'PEDIDOS ASIGNADOS A ESTE CAMIÓN (${camion.pedidos.length})',
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
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black38, size: 13),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black45, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 11,
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
            const Icon(Icons.inbox_outlined, color: Colors.black12, size: 54),
            const SizedBox(height: 10),
            const Text(
              'El camión está vacío',
              style: TextStyle(
                color: Colors.black38,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              puedeEditar
                  ? 'Toca el botón + para agregar pedidos facturados'
                  : 'No hay pedidos asignados a este camión',
              style: const TextStyle(color: Colors.black38, fontSize: 11.5),
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
              padding: const EdgeInsets.only(top: 6, bottom: 24),
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
                  pedido: p.copyWith(ordenViaje: i + 1),
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
      padding: const EdgeInsets.only(top: 6, bottom: 100),
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
