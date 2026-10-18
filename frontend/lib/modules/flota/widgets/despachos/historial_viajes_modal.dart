import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../camion_victual/models/camion_viaje.dart';
import '../../../camion_victual/services/camion_victual_service.dart';
import '../../providers/chofer_provider.dart';

class HistorialViajesModal extends StatefulWidget {
  const HistorialViajesModal({super.key});

  @override
  State<HistorialViajesModal> createState() => _HistorialViajesModalState();
}

class _HistorialViajesModalState extends State<HistorialViajesModal> {
  final CamionVictualService _service = CamionVictualService();
  final NumberFormat _currencyFmt =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy hh:mm a');

  List<CamionViaje> _viajes = [];
  bool _isLoading = true;
  String? _error;

  int? _filtroChoferId;
  String _filtroEstado = '';
  CamionViaje? _viajeSeleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoferProvider>().fetchChoferes();
      _cargarViajes();
    });
  }

  Future<void> _cargarViajes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _service.getHistorialViajes(
        choferId: _filtroChoferId,
        estado: _filtroEstado.isEmpty ? null : _filtroEstado,
        perPage: 50,
      );
      final List rawList = res['data'] is List ? res['data'] : [];
      final list = rawList.map((e) => CamionViaje.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _viajes = list;
          _isLoading = false;
          if (_viajeSeleccionado != null) {
            _viajeSeleccionado = list.firstWhere(
              (v) => v.id == _viajeSeleccionado!.id,
              orElse: () => list.isNotEmpty ? list.first : _viajeSeleccionado!,
            );
          }
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

  double get _totalFacturadoGlobal =>
      _viajes.fold(0, (sum, v) => sum + v.totalFacturado);
  double get _totalGastosGlobal =>
      _viajes.fold(0, (sum, v) => sum + v.totalGastos);
  double get _margenNetoGlobal =>
      _totalFacturadoGlobal - _totalGastosGlobal;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final choferes = context.watch<ChoferProvider>().choferes;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_outlined,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Historial de Viajes y Liquidaciones',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Registro de despachos ejecutados, facturación, gastos y margen neto',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'Recargar',
                    onPressed: _cargarViajes,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Metrics Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  _MetricBadge(
                    label: 'Viajes Archivados',
                    value: '${_viajes.length}',
                    color: const Color(0xFF0F172A),
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(width: 16),
                  _MetricBadge(
                    label: 'Facturado Total',
                    value: _currencyFmt.format(_totalFacturadoGlobal),
                    color: const Color(0xFF0284C7),
                    icon: Icons.receipt_outlined,
                  ),
                  const SizedBox(width: 16),
                  _MetricBadge(
                    label: 'Gastos Operativos',
                    value: _currencyFmt.format(_totalGastosGlobal),
                    color: const Color(0xFFDC2626),
                    icon: Icons.money_off_csred_outlined,
                  ),
                  const SizedBox(width: 16),
                  _MetricBadge(
                    label: 'Margen Neto Global',
                    value: _currencyFmt.format(_margenNetoGlobal),
                    color: const Color(0xFF16A34A),
                    icon: Icons.trending_up,
                  ),
                ],
              ),
            ),

            // Filters Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Filtro Chofer
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<int?>(
                      value: _filtroChoferId,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Filtrar por Chofer',
                        labelStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos los choferes'),
                        ),
                        ...choferes.map(
                          (ch) => DropdownMenuItem(
                            value: ch.id,
                            child: Text(
                              ch.name ?? 'Chofer #${ch.id}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _filtroChoferId = val);
                        _cargarViajes();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filtro Estado
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _filtroEstado,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Estado de Viaje',
                        labelStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Todos')),
                        DropdownMenuItem(
                            value: 'completado', child: Text('Completados')),
                        DropdownMenuItem(
                            value: 'en_ruta', child: Text('En Ruta')),
                        DropdownMenuItem(
                            value: 'cancelado', child: Text('Cancelados')),
                      ],
                      onChanged: (val) {
                        setState(() => _filtroEstado = val ?? '');
                        _cargarViajes();
                      },
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Mostrando ${_viajes.length} registros',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Content Area (List + Detail side-by-side or stacked)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(
                                color: Color(0xFFDC2626), fontSize: 12),
                          ),
                        )
                      : _viajes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.inbox_outlined,
                                      size: 36, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 8),
                                  Text(
                                    'No hay viajes registrados en el historial.',
                                    style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : isDesktop
                              ? Row(
                                  children: [
                                    // Lista de Viajes (Izquierda)
                                    Expanded(
                                      flex: 3,
                                      child: _buildViajesList(),
                                    ),
                                    const VerticalDivider(
                                        width: 1, color: Color(0xFFE2E8F0)),
                                    // Detalle del Viaje Seleccionado (Derecha)
                                    Expanded(
                                      flex: 2,
                                      child: _viajeSeleccionado == null
                                          ? const Center(
                                              child: Text(
                                                'Seleccione un viaje para ver su desglose',
                                                style: TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                          : _buildDetalleViaje(
                                              _viajeSeleccionado!),
                                    ),
                                  ],
                                )
                              : _buildViajesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViajesList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _viajes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final v = _viajes[index];
        final isSelected = _viajeSeleccionado?.id == v.id;

        return InkWell(
          onTap: () {
            setState(() {
              _viajeSeleccionado = v;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Código, Estado, Fechas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            v.codigo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          v.choferNombre ?? 'Sin chofer',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    _buildEstadoChip(v.estado),
                  ],
                ),
                const SizedBox(height: 6),

                // Info row: Fechas & Personal
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      v.fechaCierre != null
                          ? _dateFmt.format(v.fechaCierre!)
                          : (v.fechaSalida != null
                              ? 'Salida: ${_dateFmt.format(v.fechaSalida!)}'
                              : 'Sin fecha'),
                      style: const TextStyle(
                          fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    if (v.cantAyudantes > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.people_alt_outlined,
                          size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${v.cantAyudantes} ayudante${v.cantAyudantes > 1 ? "s" : ""}',
                        style: const TextStyle(
                            fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom row: Facturado, Gastos, Margen
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Facturado',
                            style: TextStyle(
                                fontSize: 9.5, color: Color(0xFF64748B)),
                          ),
                          Text(
                            _currencyFmt.format(v.totalFacturado),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gastos',
                            style: TextStyle(
                                fontSize: 9.5, color: Color(0xFFDC2626)),
                          ),
                          Text(
                            _currencyFmt.format(v.totalGastos),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Margen Neto',
                            style: TextStyle(
                                fontSize: 9.5, color: Color(0xFF16A34A)),
                          ),
                          Text(
                            _currencyFmt.format(v.margenNeto),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleViaje(CamionViaje viaje) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del viaje
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalle: ${viaje.codigo}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              _buildEstadoChip(viaje.estado),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chofer: ${viaje.choferNombre ?? "Sin asignar"}${viaje.cerradoPorNombre != null ? ' · Cerrado por: ${viaje.cerradoPorNombre}' : ''}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          if (viaje.nombresAyudantes != null &&
              viaje.nombresAyudantes!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Ayudantes (${viaje.cantAyudantes}): ${viaje.nombresAyudantes}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ],
          if (viaje.comentarios != null && viaje.comentarios!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Nota: ${viaje.comentarios}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Desglose de Gastos
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 4),
              Text(
                'Gastos Operativos (${viaje.gastos.length})',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (viaje.gastos.isEmpty)
            const Text(
              'Sin gastos registrados en este viaje.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            )
          else
            ...viaje.gastos.map((g) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${g.tipoGasto.toUpperCase()} · ${g.concepto}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9F1239),
                              ),
                            ),
                            if (g.comprobante != null)
                              Text(
                                'NCF: ${g.comprobante}',
                                style: const TextStyle(
                                    fontSize: 9.5, color: Color(0xFFBE123C)),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFmt.format(g.montoTotal),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 12),

          // Desglose de Pedidos Entregados
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Text(
                'Facturas y Entregas (${viaje.pedidos.length})',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (viaje.pedidos.isEmpty)
            const Text(
              'No se encontraron pedidos archivados para este viaje.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            )
          else
            ...viaje.pedidos.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '#${p.ordenViaje}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.clienteNombre ?? 'Cliente',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.numFactura != null)
                              Text(
                                'Fact: ${p.numFactura}',
                                style: const TextStyle(
                                    fontSize: 9.5, color: Color(0xFF64748B)),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFmt.format(p.totalPedido),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildEntregaStatusBadge(p.estadoEntrega),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color bg;
    Color fg;
    String label;

    switch (estado) {
      case 'completado':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Completado';
        break;
      case 'en_ruta':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'En Ruta';
        break;
      case 'cancelado':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Cancelado';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEntregaStatusBadge(String estado) {
    Color color;
    IconData icon;

    switch (estado) {
      case 'entregado':
        color = const Color(0xFF16A34A);
        icon = Icons.check_circle;
        break;
      case 'fallido':
        color = const Color(0xFFDC2626);
        icon = Icons.cancel;
        break;
      case 'en_curso':
        color = const Color(0xFF2563EB);
        icon = Icons.local_shipping;
        break;
      default:
        color = const Color(0xFF94A3B8);
        icon = Icons.schedule;
    }

    return Icon(icon, size: 14, color: color);
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 9.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
