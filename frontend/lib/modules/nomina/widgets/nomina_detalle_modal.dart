import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../models/nomina.dart';
import '../models/nomina_concepto.dart';
import '../providers/nomina_provider.dart';
import '../utils/nomina_report_helper.dart';

class NominaDetalleModal extends StatefulWidget {
  final NominaDetalle detalle;

  const NominaDetalleModal({super.key, required this.detalle});

  @override
  State<NominaDetalleModal> createState() => _NominaDetalleModalState();
}

class _NominaDetalleModalState extends State<NominaDetalleModal> {
  late NominaDetalle _detalle;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _detalle = widget.detalle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<NominaProvider>();
      if (prov.conceptos.isEmpty) {
        prov.loadConceptos();
      }
    });
  }

  void _abrirModalAgregarNovedad() {
    final prov = context.read<NominaProvider>();
    final conceptos = prov.conceptos.where((c) => c.activo).toList();

    if (conceptos.isEmpty) {
      CompactSnackBar.showError(
        context,
        'No hay conceptos de nómina configurados.',
      );
      return;
    }

    NominaConcepto conceptoSeleccionado = conceptos.firstWhere(
      (c) => c.codigo == 'HORAS_EXTRAS_100',
      orElse: () => conceptos.firstWhere(
        (c) => c.codigo == 'HORAS_EXTRAS_35',
        orElse: () => conceptos.first,
      ),
    );

    final cantidadCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    void recalcularSegunCantidad(String val) {
      final cant = double.tryParse(val) ?? 0;
      if (cant <= 0) return;

      final valorHora = _detalle.salarioHora;
      final salarioDiario = _detalle.salarioMensual / 23.83;

      if (conceptoSeleccionado.codigo == 'HORAS_EXTRAS_100') {
        montoCtrl.text = (cant * valorHora * 2.0).toStringAsFixed(2);
      } else if (conceptoSeleccionado.codigo == 'HORAS_EXTRAS_35') {
        montoCtrl.text = (cant * valorHora * 1.35).toStringAsFixed(2);
      } else if (conceptoSeleccionado.codigo == 'HORAS_EXTRAS_NOCTURNAS') {
        montoCtrl.text = (cant * valorHora * 1.15 * 1.35).toStringAsFixed(2);
      } else if (conceptoSeleccionado.codigo == 'JORNADA_NOCTURNA_15') {
        montoCtrl.text = (cant * valorHora * 0.15).toStringAsFixed(2);
      } else if (conceptoSeleccionado.codigo == 'DIAS_FERIADOS') {
        montoCtrl.text = (cant * salarioDiario).toStringAsFixed(2);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final esHoras = conceptoSeleccionado.codigo.contains('HORA');
          final esFeriado = conceptoSeleccionado.codigo.contains('FERIADO');

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Agregar Novedad / Horas Extras',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de Concepto
                  const Text(
                    'Concepto:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<NominaConcepto>(
                        value: conceptoSeleccionado,
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0F172A),
                        ),
                        items: conceptos.map((c) {
                          final tag = c.tipo == 'ingreso' ? '[+]' : '[-]';
                          return DropdownMenuItem<NominaConcepto>(
                            value: c,
                            child: Text(
                              '$tag ${c.nombre}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (sel) {
                          if (sel != null) {
                            setDialogState(() {
                              conceptoSeleccionado = sel;
                              recalcularSegunCantidad(cantidadCtrl.text);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cantidad (Horas o Días)
                  if (esHoras || esFeriado) ...[
                    Text(
                      esHoras
                          ? 'Cantidad de Horas Extras:'
                          : 'Cantidad de Días Feriados:',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: cantidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        hintText: esHoras ? 'Ej. 5 horas' : 'Ej. 1 día',
                        hintStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixText: esHoras ? 'horas' : 'días',
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          recalcularSegunCantidad(val);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Monto a Pagar / Descontar
                  const Text(
                    'Monto (RD\$):',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      prefixText: 'RD\$ ',
                      hintText: '0.00',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notas u Observación
                  const Text(
                    'Observación / Nota:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: notasCtrl,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      hintText: 'Ej. 5 horas dobles del sábado trabajado',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final monto = double.tryParse(montoCtrl.text) ?? 0;
                  if (monto <= 0) {
                    CompactSnackBar.showError(
                      context,
                      'Ingrese un monto válido mayor a 0',
                    );
                    return;
                  }

                  final cant = double.tryParse(cantidadCtrl.text);
                  Navigator.pop(dialogCtx);

                  setState(() => _isSaving = true);
                  try {
                    final res = await prov.agregarConceptoDetalle(
                      _detalle.nominaId,
                      _detalle.id,
                      {
                        'concepto_id': conceptoSeleccionado.id,
                        'monto': monto,
                        if (cant != null && cant > 0) 'cantidad': cant,
                        if (notasCtrl.text.trim().isNotEmpty)
                          'notas': notasCtrl.text.trim(),
                      },
                    );
                    if (res != null && mounted) {
                      setState(() => _detalle = res);
                      CompactSnackBar.showSuccess(
                        context,
                        'Novedad agregada exitosamente.',
                      );
                    }
                  } catch (e) {
                    if (mounted)
                      CompactSnackBar.showError(
                        context,
                        'Error al guardar novedad: $e',
                      );
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                icon: const Icon(Icons.check, size: 14),
                label: const Text(
                  'Guardar Novedad',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _eliminarConcepto(NominaDetalleConcepto item) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: '¿Eliminar Concepto?',
      message:
          '¿Está seguro de eliminar ${item.concepto?.nombre ?? 'este concepto'} (${Formatters.formatCurrency(item.monto)}) de la nómina de este colaborador?',
      confirmText: 'Sí, Eliminar',
      type: ConfirmType.danger,
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    try {
      final prov = context.read<NominaProvider>();
      final res = await prov.eliminarConceptoDetalle(
        _detalle.nominaId,
        _detalle.id,
        item.id,
      );
      if (res != null && mounted) {
        setState(() => _detalle = res);
        CompactSnackBar.showSuccess(
          context,
          'Concepto eliminado correctamente.',
        );
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al eliminar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = _detalle.empleado;
    final ingresos = _detalle.conceptos
        .where((c) => c.tipo == 'ingreso')
        .toList();
    final deducciones = _detalle.conceptos
        .where((c) => c.tipo == 'deduccion')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera Empleado
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      emp?.nombres.isNotEmpty == true ? emp!.nombres[0] : 'E',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp?.nombreCompleto ?? 'Empleado Desconocido',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${emp?.ocupacion ?? 'Sin cargo'} • Cédula: ${emp?.cedula != null ? Formatters.formatCedula(emp!.cedula) : '—'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'NETO A COBRAR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(_detalle.netoPagar),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),

              // Métricas Salario Base
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric(
                      'Salario Mensual',
                      Formatters.formatCurrency(_detalle.salarioMensual),
                    ),
                    _buildMiniMetric(
                      'Salario Periodo',
                      Formatters.formatCurrency(_detalle.salarioPeriodo),
                    ),
                    _buildMiniMetric(
                      'Valor Hora',
                      'RD\$ ${_detalle.salarioHora.toStringAsFixed(2)}/h',
                    ),
                    _buildMiniMetric(
                      'Horas Extras',
                      '${_detalle.horasExtras.toStringAsFixed(1)}h',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Columnas: Ingresos vs Deducciones
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna 1: Ingresos
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'INGRESOS / HABERES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(
                                      _detalle.totalIngresos,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ingresos.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Sin ingresos registrados',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: ingresos.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        height: 6,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      itemBuilder: (ctx, i) {
                                        final item = ingresos[i];
                                        final esSalarioBase =
                                            item.concepto?.codigo ==
                                            'SALARIO_ORDINARIO';

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.concepto?.nombre ??
                                                        'Ingreso',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  if (item.notas != null &&
                                                      item.notas!.isNotEmpty)
                                                    Text(
                                                      item.notas!,
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  Formatters.formatCurrency(
                                                    item.monto,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF16A34A),
                                                  ),
                                                ),
                                                if (!esSalarioBase) ...[
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 14,
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    tooltip:
                                                        'Eliminar concepto',
                                                    onPressed: _isSaving
                                                        ? null
                                                        : () =>
                                                              _eliminarConcepto(
                                                                item,
                                                              ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Columna 2: Deducciones
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'DEDUCCIONES / DESCUENTOS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(
                                      _detalle.totalDeducciones,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: deducciones.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Sin deducciones aplicadas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: deducciones.length,
                                      separatorBuilder: (_, _) => const Divider(
                                        height: 6,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      itemBuilder: (ctx, i) {
                                        final item = deducciones[i];
                                        final isCuota =
                                            item.referenciaCuota != null;
                                        final esLey = [
                                          'AFP_EMP',
                                          'ARS_EMP',
                                          'RET_ISR',
                                        ].contains(item.concepto?.codigo);

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          _cleanDeduccionNombre(
                                                            item
                                                                .concepto
                                                                ?.nombre,
                                                            item
                                                                .concepto
                                                                ?.codigo,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                  0xFF0F172A,
                                                                ),
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (isCuota) ...[
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                                vertical: 1,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFEFF6FF,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  3,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            item.referenciaCuota!,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 8.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xFF2563EB,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (item.notas != null &&
                                                      item.notas!
                                                          .trim()
                                                          .isNotEmpty &&
                                                      !item.notas!.contains(
                                                        '%',
                                                      ) &&
                                                      !item.notas!
                                                          .toLowerCase()
                                                          .contains('ley') &&
                                                      !item.notas!
                                                          .toLowerCase()
                                                          .contains('dgii'))
                                                    Text(
                                                      item.notas!,
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  Formatters.formatCurrency(
                                                    item.monto,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFDC2626),
                                                  ),
                                                ),
                                                if (!esLey) ...[
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 14,
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    tooltip:
                                                        'Eliminar concepto',
                                                    onPressed: _isSaving
                                                        ? null
                                                        : () =>
                                                              _eliminarConcepto(
                                                                item,
                                                              ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Footer con Acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Agregar Novedad / Horas Extras
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _abrirModalAgregarNovedad,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Agregar Novedad / Horas Extras',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Imprimir Volante
                      OutlinedButton.icon(
                        onPressed: () =>
                            NominaReportHelper.abrirVolanteIndividual(
                              context,
                              _detalle.nominaId,
                              _detalle.id,
                            ),
                        icon: const Icon(
                          Icons.print_outlined,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        label: const Text(
                          'Imprimir Volante',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF1E293B),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _cleanDeduccionNombre(String? raw, String? codigo) {
    if (codigo == 'AFP_EMP' || (raw != null && raw.contains('AFP')))
      return 'AFP';
    if (codigo == 'ARS_EMP' ||
        (raw != null && (raw.contains('ARS') || raw.contains('SFS'))))
      return 'ARS';
    if (codigo == 'RET_ISR' || (raw != null && raw.contains('ISR')))
      return 'ISR';
    return raw ?? 'Deducción';
  }
}
