import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';
import '../../models/chofer.dart';
import '../../models/vehiculo.dart';
import '../../providers/chofer_provider.dart';
import '../../providers/gasto_vehiculo_provider.dart';
import '../../providers/vehiculo_provider.dart';
import '../vehiculos/tipo_gasto_manager_dialog.dart';

class DespachoEnRutaDialog extends StatefulWidget {
  final CamionVictual camion;

  const DespachoEnRutaDialog({super.key, required this.camion});

  @override
  State<DespachoEnRutaDialog> createState() => _DespachoEnRutaDialogState();
}

class _GastoDespachoItemDraft {
  String tipo;
  final TextEditingController conceptoCtrl;
  final TextEditingController montoCtrl;
  final TextEditingController comprobanteCtrl;

  _GastoDespachoItemDraft({
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

class _DespachoEnRutaDialogState extends State<DespachoEnRutaDialog> {
  int? _selectedVehiculoId;
  int? _selectedChoferId;
  bool _isSubmitting = false;
  bool _isSavingListo = false;

  int _cantAyudantes = 0;
  final TextEditingController _nombresAyudantesCtrl = TextEditingController();
  final TextEditingController _comentariosCtrl = TextEditingController();
  final List<_GastoDespachoItemDraft> _gastos = [];

  @override
  void initState() {
    super.initState();

    // 1. Inicializar vehículo y chofer desde el camión o el viaje activo
    _selectedVehiculoId =
        widget.camion.vehiculoId ?? widget.camion.viajeActivo?.vehiculoId;
    _selectedChoferId = widget.camion.choferID;

    // 2. Pre-cargar ayudantes, notas y gastos previos si existen en el viaje
    final v = widget.camion.viajeActivo;
    if (v != null) {
      if (v.vehiculoId != null && v.vehiculoId! > 0) {
        _selectedVehiculoId = v.vehiculoId;
      }
      if (v.choferId != null && v.choferId! > 0) {
        _selectedChoferId = v.choferId;
      }
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
            _GastoDespachoItemDraft(
              tipo: g.tipoGasto.trim().toUpperCase(),
              concepto: g.concepto,
              monto: montoStr,
              comprobante: g.comprobante ?? '',
            ),
          );
        }
      }
    }

    // 3. Cargar catálogos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VehiculoProvider>().loadVehiculos();
        context.read<ChoferProvider>().fetchChoferes();
        context.read<GastoVehiculoProvider>().loadTiposGasto();
      }
    });
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

  bool _esChoferVirtual(Chofer c) {
    final lic = (c.numeroLicencia ?? '').toLowerCase();
    final name = (c.name ?? '').toLowerCase();
    final username = (c.username ?? '').toLowerCase();
    return lic.contains('victual') ||
        name.contains('victual') ||
        username.contains('victual');
  }

  void _agregarGasto([String? defaultTipo]) {
    setState(() {
      _gastos.add(
        _GastoDespachoItemDraft(
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

  /// Opción 1: Guardar todos los datos sin salir a ruta, dejando el camión en LISTO.
  Future<void> _guardarYDejarListo() async {
    if (!mounted) return;
    setState(() => _isSavingListo = true);

    final payload = {
      if (_selectedVehiculoId != null && _selectedVehiculoId! > 0)
        'vehiculo_id': _selectedVehiculoId,
      if (_selectedChoferId != null && _selectedChoferId! > 0)
        'chofer_id': _selectedChoferId,
      'cant_ayudantes': _cantAyudantes,
      'nombres_ayudantes': _nombresAyudantesCtrl.text.trim().isEmpty
          ? null
          : _nombresAyudantesCtrl.text.trim(),
      'comentarios': _comentariosCtrl.text.trim().isEmpty
          ? null
          : _comentariosCtrl.text.trim(),
      'gastos': _collectGastosData(),
      'dejar_listo': true,
    };

    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.guardarDatosViaje(widget.camion.id, payload);

    if (!mounted) return;
    setState(() => _isSavingListo = false);

    if (ok) {
      CompactSnackBar.showSuccess(
        context,
        '¡Datos guardados con éxito! El camión queda preparado y en estado LISTO.',
      );
      Navigator.of(context).pop(true);
    } else {
      CompactSnackBar.showError(
        context,
        provider.error ?? 'Error al guardar los datos del despacho.',
      );
    }
  }

  /// Opción 2: Confirmar y poner el camión en ruta logística.
  Future<void> _confirmarDespacho() async {
    if (_selectedVehiculoId == null || _selectedVehiculoId! <= 0) {
      CompactSnackBar.showError(
        context,
        'Debe seleccionar un vehículo físico de la flota para despachar.',
      );
      return;
    }

    if (_selectedChoferId == null || _selectedChoferId! <= 0) {
      CompactSnackBar.showError(
        context,
        'Debe seleccionar un conductor real para realizar la entrega.',
      );
      return;
    }

    if (widget.camion.montoTotal < widget.camion.minimoSalida) {
      final falta = widget.camion.minimoSalida - widget.camion.montoTotal;
      CompactSnackBar.showError(
        context,
        'No alcanza el mínimo de salida (${Formatters.formatCurrency(widget.camion.minimoSalida)}). Faltan ${Formatters.formatCurrency(falta)}.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<CamionVictualProvider>();

    try {
      final ok = await provider.ponerEnRuta(
        widget.camion.id,
        vehiculoId: _selectedVehiculoId!,
        choferId: _selectedChoferId!,
        cantAyudantes: _cantAyudantes > 0 ? _cantAyudantes : null,
        nombresAyudantes: _nombresAyudantesCtrl.text.trim().isNotEmpty
            ? _nombresAyudantesCtrl.text.trim()
            : null,
        comentarios: _comentariosCtrl.text.trim().isNotEmpty
            ? _comentariosCtrl.text.trim()
            : null,
        gastos: _collectGastosData(),
      );

      if (!mounted) return;

      if (ok) {
        CompactSnackBar.showSuccess(
          context,
          '¡Camión despachado en ruta con éxito!',
        );
        Navigator.of(context).pop(true);
      } else {
        CompactSnackBar.showError(
          context,
          provider.error ?? 'Error al despachar el camión.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final choferProvider = context.watch<ChoferProvider>();

    // Deduplicar y filtrar vehículos disponibles o el asignado
    final Map<int, Vehiculo> vehiculosMap = {};
    for (final v in vehiculoProvider.vehiculos) {
      if (v.estado.toLowerCase() == 'disponible' ||
          v.id == _selectedVehiculoId) {
        vehiculosMap[v.id] = v;
      }
    }
    final vehiculosDisponibles = vehiculosMap.values.toList();
    final int? vehiculoValido =
        (_selectedVehiculoId != null &&
            vehiculosDisponibles.any((v) => v.id == _selectedVehiculoId))
        ? _selectedVehiculoId
        : null;

    // Deduplicar y filtrar choferes: NO virtuales y activos
    final Map<int, Chofer> choferesMap = {};
    for (final c in choferProvider.choferes) {
      final isVirtual = _esChoferVirtual(c);
      final isActivo = c.estado.toLowerCase() == 'activo';
      if (!isVirtual && (isActivo || c.id == _selectedChoferId)) {
        choferesMap[c.id] = c;
      }
    }
    final choferesReales = choferesMap.values.toList();
    final int? choferValido =
        (_selectedChoferId != null &&
            choferesReales.any((c) => c.id == _selectedChoferId))
        ? _selectedChoferId
        : null;

    final bool isLoadingData =
        vehiculoProvider.isLoading || choferProvider.isLoading;

    final bool cumpleMinimo =
        widget.camion.montoTotal >= widget.camion.minimoSalida;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
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
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.departure_board,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preparar Viaje',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.camion.nombre} · ${widget.camion.pedidos.length} Pedidos · Estado actual: ${widget.camion.estado.toUpperCase()}',
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

            // ── Body ─────────────────────────────────────────────
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
                                  Formatters.formatCurrency(widget.camion.montoTotal),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  cumpleMinimo
                                      ? '✓ Mínimo alcanzado (${Formatters.formatCurrency(widget.camion.minimoSalida)})'
                                      : 'Falta para mínimo (${Formatters.formatCurrency(widget.camion.minimoSalida)})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cumpleMinimo
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w500,
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
                                  'Total Gastos Salida',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatCurrency(_totalGastos),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                Text(
                                  '${_gastos.length} gastos presupuestados',
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
                                  'Margen Estimado',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatCurrency(_margenNeto),
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
                    const SizedBox(height: 14),

                    if (isLoadingData) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ] else ...[
                      // ── Sección 1: Vehículo y Chofer ──────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehículo Físico Real
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Vehículo Físico Real *',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (vehiculosDisponibles.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: const Text(
                                      'No hay vehículos disponibles',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<int>(
                                    initialValue: vehiculoValido,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 11,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                    hint: const Text(
                                      'Seleccione vehículo...',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    items: vehiculosDisponibles.map((v) {
                                      final desc =
                                          '${v.marca ?? ''} ${v.modelo ?? ''}'
                                              .trim();
                                      final placa =
                                          v.placa != null && v.placa!.isNotEmpty
                                          ? ' • ${v.placa}'
                                          : '';
                                      return DropdownMenuItem<int>(
                                        value: v.id,
                                        child: Text(
                                          '${v.ficha} $desc$placa',
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(
                                      () => _selectedVehiculoId = val,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Chofer Real Asignado
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Color(0xFFE31E24),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Conductor Real *',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (choferesReales.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: const Text(
                                      'No hay conductores activos',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<int>(
                                    initialValue: choferValido,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 11,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                    hint: const Text(
                                      'Seleccione chofer real...',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    items: choferesReales.map((c) {
                                      final nombre =
                                          c.name ??
                                          c.username ??
                                          'Conductor #${c.id}';
                                      return DropdownMenuItem<int>(
                                        value: c.id,
                                        child: Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) =>
                                        setState(() => _selectedChoferId = val),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Sección 2: Personal / Ayudantes ───────────
                      const Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 15,
                            color: Color(0xFF0F172A),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Personal de Viaje / Ayudantes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Selector Cantidad
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
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
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '$_cantAyudantes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                          const SizedBox(width: 8),
                          // Nombres Ayudantes
                          Expanded(
                            child: TextField(
                              controller: _nombresAyudantesCtrl,
                              style: const TextStyle(fontSize: 11),
                              decoration: InputDecoration(
                                hintText: 'Nombres de ayudantes...',
                                hintStyle: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF94A3B8),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
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
                      const SizedBox(height: 14),

                      // ── Sección 3: Gastos del Viaje / Despacho ────
                      Builder(
                        builder: (context) {
                          final gastoVehiculoProvider = context
                              .watch<GastoVehiculoProvider>();
                          final List<String> catalogTipos =
                              gastoVehiculoProvider.tiposGasto
                                  .map((t) => t.nombre.trim().toUpperCase())
                                  .where((n) => n.isNotEmpty)
                                  .toSet()
                                  .toList();

                          if (catalogTipos.isEmpty) {
                            catalogTipos.addAll([
                              'COMBUSTIBLES',
                              'DIETA',
                              'PEAJE',
                              'MANTENIMIENTO Y REPARACIONES',
                              'MATERIALES Y SUMINISTROS',
                              'OTROS',
                            ]);
                          }
                          final String defaultTipo = catalogTipos.first;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_gas_station_outlined,
                                        size: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Gastos de Salida / Presupuesto',
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                              size: 14,
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
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'No hay gastos registrados para este viaje.\nHaga clic en "+ Agregar Gasto" si desea registrar combustible o viáticos iniciales.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
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
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final g = _gastos[index];

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
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Tipo Dropdown
                                          SizedBox(
                                            width: 130,
                                            child: DropdownButtonFormField<String>(
                                              initialValue: valorSeleccionado,
                                              isExpanded: true,
                                              menuMaxHeight: 260,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 6,
                                                    ),
                                                border: OutlineInputBorder(
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
                                                      fontSize: 10.5,
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
                                          const SizedBox(width: 6),

                                          // Concepto
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: g.conceptoCtrl,
                                              style: const TextStyle(
                                                fontSize: 10.5,
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
                                                      horizontal: 6,
                                                      vertical: 6,
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
                                          const SizedBox(width: 6),

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
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFDC2626),
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Monto \$',
                                                hintStyle: const TextStyle(
                                                  fontSize: 9.5,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                prefixText: '\$ ',
                                                prefixStyle: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF64748B),
                                                ),
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 6,
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
                                          const SizedBox(width: 6),

                                          // Comprobante
                                          Expanded(
                                            flex: 1,
                                            child: TextField(
                                              controller: g.comprobanteCtrl,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'NIF / Fact.',
                                                hintStyle: const TextStyle(
                                                  fontSize: 9.5,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 6,
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
                                          const SizedBox(width: 4),

                                          // Delete
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 15,
                                              color: Color(0xFFEF4444),
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
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
                      const SizedBox(height: 14),

                      // ── Sección 4: Observaciones ──────────────────
                      const Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 15,
                            color: Color(0xFF0F172A),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Observaciones o Notas de Salida',
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
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Observaciones o notas del viaje...',
                          hintStyle: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer con Botones de Acción ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: (_isSubmitting || _isSavingListo)
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),

                  // Opción 2: CONFIRMAR Y PONER EN RUTA (Acción principal para salir a ruta)
                  ElevatedButton.icon(
                    onPressed:
                        (_isSubmitting ||
                            _isSavingListo ||
                            _selectedVehiculoId == null ||
                            _selectedChoferId == null)
                        ? null
                        : _confirmarDespacho,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.departure_board, size: 15),
                    label: Text(
                      _isSubmitting
                          ? 'Despachando...'
                          : 'Confirmar y Poner en Ruta',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      disabledForegroundColor: Colors.white,
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
                  const SizedBox(width: 8),
                  // Opción 1: GUARDAR Y DEJAR LISTO (Sin cerrar ni enviar a ruta)
                  OutlinedButton.icon(
                    onPressed: (_isSubmitting || _isSavingListo)
                        ? null
                        : _guardarYDejarListo,
                    icon: _isSavingListo
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF059669),
                            ),
                          )
                        : const Icon(Icons.done_all_rounded, size: 15),
                    label: Text(
                      _isSavingListo ? 'Guardando...' : 'Guardar y Dejar Listo',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF6EE7B7)),
                      backgroundColor: const Color(0xFFECFDF5),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
