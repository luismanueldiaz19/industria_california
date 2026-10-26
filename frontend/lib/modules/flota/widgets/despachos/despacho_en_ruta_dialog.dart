import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../camion_victual/models/camion_victual.dart';
import '../../../camion_victual/providers/camion_victual_provider.dart';
import '../../models/chofer.dart';
import '../../providers/chofer_provider.dart';
import '../../providers/vehiculo_provider.dart';

class DespachoEnRutaDialog extends StatefulWidget {
  final CamionVictual camion;

  const DespachoEnRutaDialog({super.key, required this.camion});

  @override
  State<DespachoEnRutaDialog> createState() => _DespachoEnRutaDialogState();
}

class _DespachoEnRutaDialogState extends State<DespachoEnRutaDialog> {
  int? _selectedVehiculoId;
  int? _selectedChoferId;
  bool _isSubmitting = false;

  int _cantAyudantes = 0;
  final TextEditingController _nombresAyudantesCtrl = TextEditingController();
  final TextEditingController _comentariosCtrl = TextEditingController();
  bool _mostrarDetallesViaje = false;

  final NumberFormat _currencyFmt = NumberFormat.currency(
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _selectedVehiculoId = widget.camion.vehiculoId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().loadVehiculos();
      context.read<ChoferProvider>().fetchChoferes();
    });
  }

  @override
  void dispose() {
    _nombresAyudantesCtrl.dispose();
    _comentariosCtrl.dispose();
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

  Future<void> _confirmarDespacho() async {
    if (_selectedVehiculoId == null || _selectedVehiculoId! <= 0) {
      CompactSnackBar.showError(
        context,
        'Debe seleccionar un vehículo físico de la flota.',
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
      );

      if (!mounted) return;

      if (ok) {
        CompactSnackBar.showSuccess(
          context,
          '¡Camión despachado en ruta con éxito!',
        );
        Navigator.of(context).pop(true);
      } else {
        // print('provider Error: ${provider.error}');
        CompactSnackBar.showError(
          context,
          provider.error ?? 'Error al despachar el camión.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      // print('Error: $e');
      CompactSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoProvider = context.watch<VehiculoProvider>();
    final choferProvider = context.watch<ChoferProvider>();

    // Filtrar vehículos: disponibles o el que ya tenga asignado
    final vehiculosDisponibles = vehiculoProvider.vehiculos.where((v) {
      return v.estado.toLowerCase() == 'disponible' ||
          v.id == _selectedVehiculoId;
    }).toList();

    // Filtrar choferes: NO virtuales y activos
    final choferesReales = choferProvider.choferes.where((c) {
      final isVirtual = _esChoferVirtual(c);
      final isActivo = c.estado.toLowerCase() == 'activo';
      return !isVirtual && isActivo;
    }).toList();

    // Si el chofer actual del camión no es virtual y está en la lista, inicializarlo
    if (_selectedChoferId == null && choferesReales.isNotEmpty) {
      final choferActual = choferesReales.where(
        (c) => c.id == widget.camion.choferID,
      );
      if (choferActual.isNotEmpty) {
        _selectedChoferId = widget.camion.choferID;
      }
    }

    final bool isLoadingData =
        vehiculoProvider.isLoading || choferProvider.isLoading;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                            'Despachar a Ruta Logística',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.camion.nombre,
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
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Resumen de Carga del Camión ───────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.camion.pedidos.length} Pedidos',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_outlined,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currencyFmt.format(widget.camion.montoTotal),
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                  // ── Campo 1: Vehículo Real de Flota ─────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Vehículo Físico Real',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (vehiculosDisponibles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Color(0xFFDC2626),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'No hay vehículos físicos disponibles en flota. Agregue o libere un vehículo primero.',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _selectedVehiculoId,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      hint: const Text(
                        'Seleccione el vehículo físico a despachar...',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      items: vehiculosDisponibles.map((v) {
                        final desc = '${v.marca ?? ''} ${v.modelo ?? ''}'
                            .trim();
                        final placa = v.placa != null && v.placa!.isNotEmpty
                            ? ' • Placa: ${v.placa}'
                            : '';
                        return DropdownMenuItem<int>(
                          value: v.id,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v.ficha,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$desc$placa',
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedVehiculoId = val),
                    ),
                  const SizedBox(height: 14),

                  // ── Campo 2: Chofer Real Asignado ───────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: Color(0xFFE31E24),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Conductor / Chofer Real',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (choferesReales.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Color(0xFFDC2626),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'No hay conductores reales activos registrados en el sistema.',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _selectedChoferId,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE31E24),
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      hint: const Text(
                        'Seleccione el chofer real que conducirá...',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      items: choferesReales.map((c) {
                        final nombre =
                            c.name ?? c.username ?? 'Conductor #${c.id}';
                        final lic =
                            c.numeroLicencia != null &&
                                c.numeroLicencia!.isNotEmpty
                            ? 'Lic: ${c.numeroLicencia}'
                            : 'Sin Licencia';
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 11,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '  ($lic)',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedChoferId = val),
                    ),
                  const SizedBox(height: 14),

                  // ── Sección opcional: Datos preliminares del viaje (ayudantes y notas) ─
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() =>
                              _mostrarDetallesViaje = !_mostrarDetallesViaje),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _mostrarDetallesViaje
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                  size: 18,
                                  color: const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Datos de Salida / Ayudantes (Opcional)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Spacer(),
                                if (_cantAyudantes > 0 ||
                                    _nombresAyudantesCtrl.text.isNotEmpty ||
                                    _comentariosCtrl.text.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _cantAyudantes > 0
                                          ? '$_cantAyudantes ayudante(s)'
                                          : 'Con notas',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_mostrarDetallesViaje) ...[
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Cant. Ayudantes:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: _cantAyudantes > 0
                                                ? () => setState(
                                                    () => _cantAyudantes--)
                                                : null,
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 14,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$_cantAyudantes',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => setState(
                                                () => _cantAyudantes++),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 14,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
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
                                          filled: true,
                                          fillColor: Colors.white,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _comentariosCtrl,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 11),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Observaciones o notas iniciales del despacho...',
                                    hintStyle: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
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
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Nota informativa del flujo de despacho ────────────
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF2563EB),
                          size: 15,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Al despachar, los pedidos pasarán a "En curso" y se abrirá el registro del viaje. Al finalizar y liquidar el viaje, el camión liberará el vehículo físico y volverá automáticamente al chofer virtual.',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // ── Botones de Acción ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed:
                          (_isSubmitting ||
                              _selectedVehiculoId == null ||
                              _selectedChoferId == null)
                          ? null
                          : _confirmarDespacho,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.departure_board, size: 14),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
