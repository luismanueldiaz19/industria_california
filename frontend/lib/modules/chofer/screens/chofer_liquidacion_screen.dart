import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/compact_snack_bar.dart';
import '../../../core/widgets/general_header.dart';
import '../../camion_victual/models/camion_victual.dart';
import '../../camion_victual/providers/camion_victual_provider.dart';

class _GastoFila {
  String tipo;
  final TextEditingController conceptoCtrl;
  final TextEditingController montoCtrl;
  final TextEditingController comprobanteCtrl;

  _GastoFila({
    this.tipo = 'combustible',
    String concepto = '',
    String monto = '',
    String comprobante = '',
  })  : conceptoCtrl = TextEditingController(text: concepto),
        montoCtrl = TextEditingController(text: monto),
        comprobanteCtrl = TextEditingController(text: comprobante);

  void dispose() {
    conceptoCtrl.dispose();
    montoCtrl.dispose();
    comprobanteCtrl.dispose();
  }
}

class ChoferLiquidacionScreen extends StatefulWidget {
  final VoidCallback? onLiquidadoExitoso;

  const ChoferLiquidacionScreen({super.key, this.onLiquidadoExitoso});

  @override
  State<ChoferLiquidacionScreen> createState() => _ChoferLiquidacionScreenState();
}

class _ChoferLiquidacionScreenState extends State<ChoferLiquidacionScreen> {
  final List<_GastoFila> _gastos = [];
  final TextEditingController _nombresAyudantesCtrl = TextEditingController();
  final TextEditingController _comentariosCtrl = TextEditingController();
  int _cantAyudantes = 0;
  bool _isSaving = false;

  static const List<String> _tiposGasto = [
    'combustible',
    'peaje',
    'dieta',
    'lavado',
    'ayudante',
    'otro',
  ];

  @override
  void initState() {
    super.initState();
    // Iniciar con combustible y peaje por defecto
    _gastos.add(_GastoFila(tipo: 'combustible', concepto: 'Combustible del día'));
    _gastos.add(_GastoFila(tipo: 'peaje', concepto: 'Peajes'));
  }

  @override
  void dispose() {
    for (final g in _gastos) {
      g.dispose();
    }
    _nombresAyudantesCtrl.dispose();
    _comentariosCtrl.dispose();
    super.dispose();
  }

  void _agregarFilaGasto() {
    setState(() {
      _gastos.add(_GastoFila(tipo: 'otro', concepto: ''));
    });
  }

  void _eliminarFilaGasto(int index) {
    if (_gastos.length <= 1) return;
    setState(() {
      _gastos[index].dispose();
      _gastos.removeAt(index);
    });
  }

  double _calcularTotalGastos() {
    double total = 0;
    for (final g in _gastos) {
      final val = double.tryParse(g.montoCtrl.text.replaceAll(',', '')) ?? 0;
      total += val;
    }
    return total;
  }

  Future<void> _ejecutarLiquidacion(CamionVictual camion) async {
    final pedidos = camion.pedidos;
    final int pendientes = pedidos
        .where((p) =>
            p.estadoEntrega.toLowerCase() == 'en_curso' ||
            p.estadoEntrega.toLowerCase() == 'pendiente')
        .length;

    bool marcarRestantesEntregados = false;

    if (pendientes > 0) {
      final decision = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Pedidos en Curso',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Aún quedan $pendientes pedido(s) sin marcar en este camión.\n\n¿Desea marcarlos automáticamente como "Entregados" al liquidar, o conservarlos como "Fallidos" para liberarlos a otra ruta?',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF64748B))),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFD97706)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => Navigator.pop(ctx, 'fallidos'),
              child: const Text('DEJAR FALLIDOS (LIBERAR)'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => Navigator.pop(ctx, 'entregados'),
              child: const Text('AUTO-MARCAR ENTREGADOS'),
            ),
          ],
        ),
      );

      if (decision == null) return;
      marcarRestantesEntregados = decision == 'entregados';
    }

    setState(() => _isSaving = true);

    final List<Map<String, dynamic>> gastosData = [];
    for (final g in _gastos) {
      final monto = double.tryParse(g.montoCtrl.text.replaceAll(',', '')) ?? 0;
      if (monto > 0 || g.conceptoCtrl.text.trim().isNotEmpty) {
        final comp = g.comprobanteCtrl.text.trim();
        gastosData.add({
          'tipo_gasto': g.tipo,
          'concepto': g.conceptoCtrl.text.trim().isEmpty
              ? 'Gasto de viaje'
              : g.conceptoCtrl.text.trim(),
          'monto_total': monto,
          'comprobante': comp.isNotEmpty ? comp : null,
          'comprobantes': comp.isNotEmpty ? [comp] : null,
        });
      }
    }

    final payload = {
      'cant_ayudantes': _cantAyudantes,
      'nombres_ayudantes': _nombresAyudantesCtrl.text.trim().isEmpty
          ? null
          : _nombresAyudantesCtrl.text.trim(),
      'comentarios': _comentariosCtrl.text.trim().isEmpty
          ? null
          : _comentariosCtrl.text.trim(),
      'marcar_restantes_entregados': marcarRestantesEntregados,
      'gastos': gastosData,
    };

    if (!mounted) return;
    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.cerrarConLiquidacion(camion.id, payload);

    setState(() => _isSaving = false);

    if (mounted) {
      if (ok) {
        CompactSnackBar.showSuccess(context, '¡Viaje liquidado y cerrado con éxito!');
        if (widget.onLiquidadoExitoso != null) {
          widget.onLiquidadoExitoso!();
        }
      } else {
        CompactSnackBar.showError(
          context,
          provider.error ?? 'Error al liquidar el viaje',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          GeneralHeader(
            title: 'Liquidación de Despacho',
            subtitle: 'Cierre y balances de ruta',
            icon: Icons.payments,
            iconColor: Colors.amber.shade300,
            gradientColors: const [AppTheme.primaryBlue, AppTheme.secondaryBlue],
          ),
          Expanded(
            child: Consumer<CamionVictualProvider>(
              builder: (context, provider, _) {
                final camiones = provider.camiones;
                CamionVictual? camion;
                try {
                  camion = camiones.firstWhere((c) => c.estado == 'en_ruta');
                } catch (_) {
                  if (camiones.isNotEmpty) camion = camiones.first;
                }

                if (camion == null || camion.pedidos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 48),
                          SizedBox(height: 14),
                          Text(
                            'No hay despacho pendiente por liquidar',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tus viajes anteriores ya han sido liquidados o aún no se ha despachado un nuevo camión a ruta.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

          final pedidos = camion.pedidos;
          final double totalFacturado = camion.montoTotal;
          final double totalEntregado = pedidos
              .where((p) => p.estadoEntrega.toLowerCase() == 'entregado')
              .fold(0.0, (sum, p) => sum + p.total);
          final double totalFallido = pedidos
              .where((p) => p.estadoEntrega.toLowerCase() == 'fallido')
              .fold(0.0, (sum, p) => sum + p.total);
          final double totalGastos = _calcularTotalGastos();
          final double totalALiquidar = totalEntregado - totalGastos;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. RESUMEN DE LA CARGA ENTREGADA
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${camion.nombre} · ${camion.vehiculoFicha ?? 'S/F'}',
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${pedidos.length} pedidos',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _kpiMini('Facturado', totalFacturado, const Color(0xFF1E293B)),
                          _kpiMini('Entregado', totalEntregado, const Color(0xFF15803D)),
                          _kpiMini('Fallido', totalFallido, const Color(0xFFDC2626)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. GASTOS DEL VIAJE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gastos del Viaje',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _agregarFilaGasto,
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFFE31E24)),
                      label: const Text(
                        'Agregar Gasto',
                        style: TextStyle(color: Color(0xFFE31E24), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                ...List.generate(_gastos.length, (idx) {
                  final g = _gastos[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Selector de tipo de gasto
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _tiposGasto.contains(g.tipo)
                                        ? g.tipo
                                        : _tiposGasto.first,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                                    items: _tiposGasto.map((t) {
                                      return DropdownMenuItem(
                                        value: t,
                                        child: Text(t.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => g.tipo = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Monto
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: g.montoCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Monto \$',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    filled: true,
                                    fillColor: Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Botón eliminar gasto
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: const Color(0xFFDC2626),
                              onPressed: () => _eliminarFilaGasto(idx),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Concepto
                            Expanded(
                              flex: 5,
                              child: SizedBox(
                                height: 34,
                                child: TextField(
                                  controller: g.conceptoCtrl,
                                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                                  decoration: const InputDecoration(
                                    hintText: 'Concepto (Ej. Gasoil bomba Shell)',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                    filled: true,
                                    fillColor: Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Comprobante / NCF
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 34,
                                child: TextField(
                                  controller: g.comprobanteCtrl,
                                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                                  decoration: const InputDecoration(
                                    hintText: 'NCF / Comp. (Opc.)',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                    filled: true,
                                    fillColor: Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(6)),
                                      borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // 3. AYUDANTES Y OBSERVACIONES
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ayudantes y Tripulación',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Cantidad de ayudantes:', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18),
                                color: const Color(0xFF64748B),
                                onPressed: _cantAyudantes > 0
                                    ? () => setState(() => _cantAyudantes--)
                                    : null,
                              ),
                              Text(
                                '$_cantAyudantes',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                color: const Color(0xFF1976D2),
                                onPressed: () => setState(() => _cantAyudantes++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_cantAyudantes > 0) ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nombresAyudantesCtrl,
                          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                          decoration: const InputDecoration(
                            hintText: 'Nombres de los ayudantes (Ej. Juan Pérez, Ramón)',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            filled: true,
                            fillColor: Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        'Observaciones del viaje (Opcional):',
                        style: TextStyle(color: Color(0xFF475569), fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _comentariosCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                        decoration: const InputDecoration(
                          hintText: 'Novedades mecánicas, demoras en clientes, etc.',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          contentPadding: EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. RESUMEN FINAL DE LIQUIDACIÓN
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF047857),
                        Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Entregado:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(Formatters.formatCurrency(totalEntregado), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Gastos de Ruta:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('- ${Formatters.formatCurrency(totalGastos)}', style: const TextStyle(color: Color(0xFFFED7AA), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NETO A ENTREGAR:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(totalALiquidar),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. BOTÓN LIQUIDAR Y CERRAR
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSaving ? null : () => _ejecutarLiquidacion(camion!),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'LIQUIDAR Y CERRAR DESPACHO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    ),
  ],
),
);
}

  Widget _kpiMini(String label, double valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        Text(
          Formatters.formatCurrency(valor),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
