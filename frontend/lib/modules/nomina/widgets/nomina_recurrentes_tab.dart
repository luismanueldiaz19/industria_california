import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cancel_button.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_table_scroll.dart';
import '../../empleado/providers/empleado_provider.dart';
import '../models/nomina_recurrente.dart';
import '../providers/nomina_provider.dart';
import '../utils/nomina_report_helper.dart';
import 'nomina_conceptos_catalogo_modal.dart';

class NominaRecurrentesTab extends StatefulWidget {
  const NominaRecurrentesTab({super.key});

  @override
  State<NominaRecurrentesTab> createState() => _NominaRecurrentesTabState();
}

class _NominaRecurrentesTabState extends State<NominaRecurrentesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NominaProvider>().loadRecurrentes();
      context.read<NominaProvider>().loadConceptos();
      context.read<EmpleadoProvider>().loadEmpleados();
    });
  }

  void _abrirCatalogoConceptos() {
    showDialog(
      context: context,
      builder: (_) => const NominaConceptosCatalogoModal(),
    );
  }

  void _abrirModalNuevoRecurrente() {
    final empProv = context.read<EmpleadoProvider>();
    final nomProv = context.read<NominaProvider>();
    final deducciones = nomProv.conceptos
        .where((c) =>
            c.tipo.toLowerCase() == 'deduccion' &&
            !c.esAutomatico &&
            c.categoria.toLowerCase() != 'ley' &&
            !c.codigo.toUpperCase().contains('AFP') &&
            !c.codigo.toUpperCase().contains('ARS') &&
            !c.codigo.toUpperCase().contains('ISR'))
        .toList();

    int? selectedEmpId = empProv.empleados.isNotEmpty
        ? empProv.empleados.first.id
        : null;
    int? selectedConceptoId = deducciones.isNotEmpty
        ? deducciones.first.id
        : null;
    final descCtrl = TextEditingController(text: 'Préstamo');
    final totalCtrl = TextEditingController(text: '0.00');
    final cuotaCtrl = TextEditingController(text: '0.00');
    final cuotasTotalesCtrl = TextEditingController(text: '12');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.credit_score,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Asignar Descuento / Préstamo Recurrente',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Se descontará automáticamente cada periodo avanzando cuotas',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => Navigator.pop(ctx),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),

                      // Empleado
                      DropdownButtonFormField<int>(
                        initialValue: selectedEmpId,
                        isExpanded: true,
                        decoration: _inputDeco('Empleado'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        items: empProv.empleados.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(
                              '${e.nombreCompleto} (${Formatters.formatCedula(e.cedula)})',
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setStateModal(() => selectedEmpId = v),
                      ),
                      const SizedBox(height: 10),

                      // Concepto
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tipo de Concepto / Préstamo',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _abrirCatalogoConceptos();
                            },
                            child: const Text(
                              '+ Administrar / Crear Concepto',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        initialValue: selectedConceptoId,
                        isExpanded: true,
                        decoration: _inputDeco('Seleccione un concepto'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        items: deducciones.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.nombre),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setStateModal(() => selectedConceptoId = v),
                      ),
                      const SizedBox(height: 10),

                      // Descripción
                      TextField(
                        controller: descCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDeco(
                          'Descripción / Motivo (ej. Préstamo de Emergencia, Lentes)',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Montos y Cuotas
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: totalCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(fontSize: 12),
                              decoration: _inputDeco('Monto Total (RD\$)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: cuotaCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(fontSize: 12),
                              decoration: _inputDeco(
                                'Cuota por Periodo (RD\$)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: cuotasTotalesCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: _inputDeco('Total Cuotas'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CancelButton(onPressed: () => Navigator.pop(ctx)),
                          const SizedBox(width: 8),
                          CustomButton(
                            text: 'Guardar Préstamo',
                            icon: Icons.check,
                            onPressed: () async {
                              if (selectedEmpId == null ||
                                  selectedConceptoId == null) {
                                return;
                              }
                              final total =
                                  double.tryParse(totalCtrl.text) ?? 0.0;
                              final cuota =
                                  double.tryParse(cuotaCtrl.text) ?? 0.0;
                              final numCuotas =
                                  int.tryParse(cuotasTotalesCtrl.text) ?? 1;

                              if (cuota <= 0) {
                                CompactSnackBar.showError(
                                  ctx,
                                  'La cuota debe ser mayor a 0',
                                );
                                return;
                              }

                              Navigator.pop(ctx);
                              try {
                                await nomProv.createRecurrente({
                                  'empleado_id': selectedEmpId,
                                  'concepto_id': selectedConceptoId,
                                  'descripcion': descCtrl.text.trim(),
                                  'monto_total': total,
                                  'monto_cuota': cuota,
                                  'cuotas_totales': numCuotas,
                                  'cuotas_pagadas': 0,
                                  'saldo_restante': total > 0
                                      ? total
                                      : (cuota * numCuotas),
                                });
                                if (!context.mounted) return;
                                CompactSnackBar.showSuccess(
                                  context,
                                  'Descuento recurrente asignado correctamente.',
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                CompactSnackBar.showError(context, 'Error: $e');
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  Future<void> _confirmarEliminar(NominaEmpleadoRecurrente rec) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: '¿Eliminar Descuento Recurrente?',
      message:
          '¿Seguro que deseas eliminar el descuento "${rec.descripcion}" para ${rec.empleado?.nombreCompleto}?',
      confirmText: 'Sí, Eliminar',
      confirmIcon: Icons.delete_outline,
      type: ConfirmType.danger,
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await context.read<NominaProvider>().deleteRecurrente(rec.id);
      if (mounted) {
        CompactSnackBar.showSuccess(
          context,
          'Descuento recurrente eliminado exitosamente',
        );
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NominaProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.credit_card_outlined,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Préstamos y Deducciones Recurrentes',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Seguimiento automático de cuotas y saldos de colaboradores',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => NominaReportHelper.abrirReporteRecurrentes(context),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: Color(0xFF0F172A)),
                      label: const Text(
                        'Reporte Cartera',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => NominaReportHelper.descargarExcelRecurrentes(context),
                      icon: const Icon(Icons.table_chart_outlined, size: 14, color: Color(0xFF16A34A)),
                      label: const Text(
                        'Excel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _abrirCatalogoConceptos,
                      icon: const Icon(Icons.list_alt, size: 14, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Catálogo de Conceptos',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    CustomButton(
                      text: 'Asignar Préstamo / Cuota',
                      icon: Icons.add,
                      onPressed: _abrirModalNuevoRecurrente,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabla
          Expanded(
            child: prov.recurrentes.isEmpty
                ? const Center(
                    child: Text(
                      'No hay préstamos ni deducciones recurrentes activas.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomTableScroll(
                        child: DataTable(
                          headingRowHeight: 38,
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 46,
                          columnSpacing: 18,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'EMPLEADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CONCEPTO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'DESCRIPCIÓN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'MONTO CUOTA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CUOTAS (PAG/TOT)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'SALDO RESTANTE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ESTADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ACCIONES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                          rows: prov.recurrentes.map((r) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    r.empleado?.nombreCompleto ??
                                        'Empleado #${r.empleadoId}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.concepto?.nombre ?? '—',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.descripcion,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    Formatters.formatCurrency(r.montoCuota),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.referenciaCuota,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    Formatters.formatCurrency(r.saldoRestante),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: r.activo
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.activo ? 'ACTIVO' : 'LIQUIDADO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: r.activo
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 15,
                                      color: Color(0xFFDC2626),
                                    ),
                                    tooltip: 'Eliminar Descuento',
                                    onPressed: () => _confirmarEliminar(r),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
