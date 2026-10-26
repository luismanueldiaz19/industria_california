import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/zoom_dialog.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';
import '../../providers/gasto_vehiculo_provider.dart';
import '../vehiculos/tipo_gasto_manager_dialog.dart';

class DespachoLiquidacionDialog extends StatefulWidget {
  final CamionVictual camion;

  const DespachoLiquidacionDialog({super.key, required this.camion});

  @override
  State<DespachoLiquidacionDialog> createState() =>
      _DespachoLiquidacionDialogState();
}

class _GastoItemDraft {
  String tipo;
  final TextEditingController conceptoCtrl;
  final TextEditingController montoCtrl;
  final TextEditingController comprobanteCtrl;

  _GastoItemDraft({
    String tipo = 'COMBUSTIBLES',
    String concepto = '',
    String monto = '',
    String comprobante = '',
  }) : tipo = tipo.trim().isEmpty ? 'COMBUSTIBLES' : tipo.trim().toUpperCase(),
       conceptoCtrl = TextEditingController(text: concepto),
       montoCtrl = TextEditingController(text: monto),
       comprobanteCtrl = TextEditingController(text: comprobante);

  void dispose() {
    conceptoCtrl.dispose();
    montoCtrl.dispose();
    comprobanteCtrl.dispose();
  }
}

class _DespachoLiquidacionDialogState extends State<DespachoLiquidacionDialog> {
  final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  int _cantAyudantes = 0;
  final TextEditingController _nombresAyudantesCtrl = TextEditingController();
  final TextEditingController _comentariosCtrl = TextEditingController();

  final List<_GastoItemDraft> _gastos = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GastoVehiculoProvider>().loadTiposGasto();
      }
    });

    final v = widget.camion.viajeActivo;
    if (v != null) {
      _cantAyudantes = v.cantAyudantes;
      if (v.nombresAyudantes != null && v.nombresAyudantes!.isNotEmpty) {
        _nombresAyudantesCtrl.text = v.nombresAyudantes!;
      }
      if (v.comentarios != null && v.comentarios!.isNotEmpty) {
        _comentariosCtrl.text = v.comentarios!;
      }
      if (v.gastos.isNotEmpty) {
        for (final g in v.gastos) {
          final montoStr = g.montoTotal > 0
              ? (g.montoTotal % 1 == 0
                    ? g.montoTotal.toInt().toString()
                    : g.montoTotal.toStringAsFixed(2))
              : '';
          _gastos.add(
            _GastoItemDraft(
              tipo: g.tipoGasto.trim().toUpperCase(),
              concepto: g.concepto,
              monto: montoStr,
              comprobante: g.comprobante ?? '',
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nombresAyudantesCtrl.dispose();
    _comentariosCtrl.dispose();
    for (final g in _gastos) {
      g.dispose();
    }
    super.dispose();
  }

  void _agregarGasto([String? defaultTipo]) {
    setState(() {
      _gastos.add(
        _GastoItemDraft(
          tipo: defaultTipo ?? 'COMBUSTIBLES',
          concepto: '',
          monto: '',
        ),
      );
    });
  }

  void _eliminarGasto(int index) {
    setState(() {
      _gastos[index].dispose();
      _gastos.removeAt(index);
    });
  }

  double get _totalGastos {
    double total = 0;
    for (final g in _gastos) {
      final m = double.tryParse(g.montoCtrl.text.replaceAll(',', '')) ?? 0;
      total += m;
    }
    return total;
  }

  double get _margenNeto => widget.camion.montoTotal - _totalGastos;

  List<Map<String, dynamic>> _collectGastosData() {
    final List<Map<String, dynamic>> gastosData = [];
    for (final g in _gastos) {
      final monto = double.tryParse(g.montoCtrl.text.replaceAll(',', '')) ?? 0;
      if (monto > 0 || g.conceptoCtrl.text.trim().isNotEmpty) {
        final tipoUpper = g.tipo.trim().toUpperCase();
        gastosData.add({
          'tipo_gasto': tipoUpper.isEmpty ? 'OTROS' : tipoUpper,
          'concepto': g.conceptoCtrl.text.trim().isEmpty
              ? (tipoUpper.isEmpty ? 'Gasto de viaje' : tipoUpper)
              : g.conceptoCtrl.text.trim().toUpperCase(),
          'monto_total': monto,
          'comprobante': g.comprobanteCtrl.text.trim().isEmpty
              ? null
              : g.comprobanteCtrl.text.trim().toUpperCase(),
        });
      }
    }
    return gastosData;
  }

  /// Guarda los datos del viaje (gastos, ayudantes, notas) manteniendo el camión EN RUTA.
  Future<void> _guardarSinCerrar() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    final payload = {
      'cant_ayudantes': _cantAyudantes,
      'nombres_ayudantes': _nombresAyudantesCtrl.text.trim().isEmpty
          ? null
          : _nombresAyudantesCtrl.text.trim(),
      'comentarios': _comentariosCtrl.text.trim().isEmpty
          ? null
          : _comentariosCtrl.text.trim(),
      'gastos': _collectGastosData(),
    };

    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.guardarDatosViaje(widget.camion.id, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      CompactSnackBar.showSuccess(
        context,
        '¡Datos del viaje guardados! El camión continúa en ruta.',
      );
      Navigator.of(context).pop(true);
    } else {
      CompactSnackBar.showError(
        context,
        provider.error ?? 'Error al guardar los datos del viaje.',
      );
    }
  }

  Future<void> _finalizarLiquidacion() async {
    final pedidos = widget.camion.pedidos;
    final int pendientesEnCurso = pedidos
        .where(
          (p) =>
              p.estadoEntrega == 'en_curso' || p.estadoEntrega == 'pendiente',
        )
        .length;
    final int fallidos = pedidos
        .where((p) => p.estadoEntrega == 'fallido')
        .length;
    final int yaEntregados = pedidos
        .where((p) => p.estadoEntrega == 'entregado')
        .length;

    bool marcarRestantesEntregados = false;

    if (pendientesEnCurso > 0) {
      final respuesta = await ZoomDialog.confirm(
        context: context,
        title: '¿Marcar pedidos como Entregados?',
        content:
            'Hay $pendientesEnCurso pedido(s) que aún figuran en curso.\n\n'
            '¿Desea marcarlos automáticamente como "Entregados" al liquidar el viaje?\n\n'
            '• Se guardarán como entregados: ${yaEntregados + pendientesEnCurso} pedido(s)\n'
            '${fallidos > 0 ? "• Se liberarán: $fallidos pedido(s) fallidos para despachar en otra ocasión\n" : ""}',
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF16A34A),
        confirmText: 'Entregar y Liquidar',
        confirmIcon: Icons.check_circle_rounded,
        cancelText: 'Cancelar',
      );

      if (respuesta != true) return;
      marcarRestantesEntregados = true;
    } else {
      final respuesta = await ZoomDialog.confirm(
        context: context,
        title: 'Finalizar y Liquidar Viaje',
        content:
            '¿Desea cerrar definitivamente este viaje?\n\n'
            '• $yaEntregados pedido(s) entregados\n'
            '${fallidos > 0 ? "• $fallidos pedido(s) fallidos (serán liberados para reprogramar)\n" : ""}'
            '• El camión quedará libre para nuevos viajes.',
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFFEA580C),
        confirmText: 'Confirmar y Liquidar',
        confirmIcon: Icons.check_circle_rounded,
        cancelText: 'Cancelar',
      );

      if (respuesta != true) return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final payload = {
      'cant_ayudantes': _cantAyudantes,
      'nombres_ayudantes': _nombresAyudantesCtrl.text.trim().isEmpty
          ? null
          : _nombresAyudantesCtrl.text.trim(),
      'comentarios': _comentariosCtrl.text.trim().isEmpty
          ? null
          : _comentariosCtrl.text.trim(),
      'marcar_restantes_entregados': marcarRestantesEntregados,
      'gastos': _collectGastosData(),
    };

    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.cerrarConLiquidacion(widget.camion.id, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      CompactSnackBar.showSuccess(
        context,
        '¡Viaje liquidado y archivado! El camión ha quedado LIBRE para nuevos despachos.',
      );
      Navigator.of(context).pop(true);
    } else {
      CompactSnackBar.showError(
        context,
        provider.error ?? 'Error al procesar liquidación',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // Header
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
                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Liquidación y Cierre de Viaje',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.camion.nombre}${widget.camion.viajeActivo != null ? " · Viaje #${widget.camion.viajeActivo!.codigo}" : ""} · Chofer: ${widget.camion.choferNombre ?? "Sin chofer"}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta Resumen Financiero Rápido
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Facturado',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFmt.format(widget.camion.montoTotal),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                () {
                                  final int ent = widget.camion.pedidos
                                      .where(
                                        (p) => p.estadoEntrega == 'entregado',
                                      )
                                      .length;
                                  final int enc = widget.camion.pedidos
                                      .where(
                                        (p) =>
                                            p.estadoEntrega == 'en_curso' ||
                                            p.estadoEntrega == 'pendiente',
                                      )
                                      .length;
                                  final int fal = widget.camion.pedidos
                                      .where(
                                        (p) => p.estadoEntrega == 'fallido',
                                      )
                                      .length;
                                  return Text(
                                    '$ent entregados · $enc en curso${fal > 0 ? " · $fal fallidos" : ""}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }(),
                              ],
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Gastos',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFmt.format(_totalGastos),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                Text(
                                  '${_gastos.length} gastos registrados',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Margen Neto',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFmt.format(_margenNeto),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                Text(
                                  widget.camion.montoTotal > 0
                                      ? '${((_margenNeto / widget.camion.montoTotal) * 100).toStringAsFixed(1)}% rendimiento'
                                      : '0%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avisos sobre pedidos en curso o fallidos
                    () {
                      final int enc = widget.camion.pedidos
                          .where(
                            (p) =>
                                p.estadoEntrega == 'en_curso' ||
                                p.estadoEntrega == 'pendiente',
                          )
                          .length;
                      final int fal = widget.camion.pedidos
                          .where((p) => p.estadoEntrega == 'fallido')
                          .length;

                      if (enc == 0 && fal == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            if (enc > 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$enc pedido(s) aún en curso. Al liquidar se preguntará si desea auto-marcarlos como entregados.',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (fal > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.replay_outlined,
                                      size: 14,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$fal pedido(s) marcado(s) como fallido(s) quedarán liberados para entregarse en otro viaje.',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }(),
                    const SizedBox(height: 16),

                    // Sección 1: Personal y Ayudantes
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 16,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Personal de Viaje / Ayudantes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cantidad de Ayudantes Selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: _cantAyudantes > 0
                                    ? () => setState(() => _cantAyudantes--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '$_cantAyudantes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: () =>
                                    setState(() => _cantAyudantes++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nombres de Ayudantes
                        Expanded(
                          child: TextField(
                            controller: _nombresAyudantesCtrl,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Nombres de ayudantes (opcional)',
                              hintStyle: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sección 2: Gastos del Viaje
                    Builder(
                      builder: (context) {
                        final gastoVehiculoProvider = context
                            .watch<GastoVehiculoProvider>();
                        final List<String> catalogTipos = gastoVehiculoProvider
                            .tiposGasto
                            .map((t) => t.nombre.trim().toUpperCase())
                            .where((n) => n.isNotEmpty)
                            .toSet()
                            .toList();

                        if (catalogTipos.isEmpty) {
                          catalogTipos.addAll([
                            'COMBUSTIBLES',
                            'DIETA',
                            'PEAJE',
                            'HERRAMIENTAS Y EQUIPOS',
                            'LIMPIEZA Y ASEO',
                            'MANTENIMIENTO Y REPARACIONES',
                            'MATERIALES Y SUMINISTROS',
                            'SERVICIOS Y UTILIDADES',
                            'OTROS',
                          ]);
                        }
                        final String defaultTipo = catalogTipos.first;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_gas_station_outlined,
                                      size: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Gastos Operativos (Opcional)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: 'Gestionar tipos de gasto',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) =>
                                                const TipoGastoManagerDialog(),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.settings_outlined,
                                            size: 15,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _agregarGasto(defaultTipo),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text(
                                    'Agregar Gasto',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            if (_gastos.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No hay gastos registrados para este viaje.\nHaga clic en "+ Agregar Gasto" si desea registrar combustible, viáticos, etc.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _gastos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final g = _gastos[index];

                                  // Opciones dinámicas asegurando inclusión del valor actual
                                  final List<String> opcionesGasto =
                                      List<String>.from(catalogTipos);
                                  final String cleanTipo = g.tipo
                                      .trim()
                                      .toUpperCase();
                                  if (cleanTipo.isNotEmpty &&
                                      !opcionesGasto.contains(cleanTipo)) {
                                    opcionesGasto.insert(0, cleanTipo);
                                  }
                                  final String valorSeleccionado =
                                      opcionesGasto.contains(cleanTipo)
                                      ? cleanTipo
                                      : opcionesGasto.first;

                                  if (g.tipo != valorSeleccionado) {
                                    g.tipo = valorSeleccionado;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Tipo Dropdown Dinámico
                                        SizedBox(
                                          width: 140,
                                          // ignore: deprecated_member_use
                                          child: DropdownButtonFormField<String>(
                                            initialValue: valorSeleccionado,
                                            isExpanded: true,
                                            menuMaxHeight: 300,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                            ),
                                            items: opcionesGasto.map((t) {
                                              return DropdownMenuItem<String>(
                                                value: t,
                                                child: Text(
                                                  t,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => g.tipo = val);
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Concepto
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: g.conceptoCtrl,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Detalle / Estación',
                                              hintStyle: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF94A3B8),
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Monto
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller: g.montoCtrl,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFDC2626),
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Monto \$',
                                              hintStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.normal,
                                                color: Color(0xFF94A3B8),
                                              ),
                                              prefixText: '\$ ',
                                              prefixStyle: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Delete
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Color(0xFFEF4444),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 26,
                                            minHeight: 26,
                                          ),
                                          onPressed: () =>
                                              _eliminarGasto(index),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sección 3: Observaciones
                    Row(
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          size: 16,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Observaciones del Viaje',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _comentariosCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText:
                            'Incidencias, novedades en ruta o comentarios generales...',
                        hintStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nota informativa sobre las opciones
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '• "Guardar sin Cerrar": Asienta ayudantes y gastos manteniendo el viaje en ruta sin liberarlo.\n• "Finalizar y Liquidar": Cierra definitivamente el viaje y libera el camión a VACÍO (\$0.00).',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF1E40AF),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  // Botón FINALIZAR Y LIQUIDAR (Secundario / Outline para prevenir clics accidentales)
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _finalizarLiquidacion,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFFEA580C),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 15),
                    label: Text(
                      _isSaving
                          ? 'Liquidando...'
                          : 'Finalizar y Liquidar Viaje',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC2410C),
                      side: const BorderSide(color: Color(0xFFFDBA74)),
                      backgroundColor: const Color(0xFFFFF7ED),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón GUARDAR SIN CERRAR (Acción principal destacada en ROJO)
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardarSinCerrar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: const Text(
                      'Guardar sin Cerrar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
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
          ],
        ),
      ),
    );
  }
}
