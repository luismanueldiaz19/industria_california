import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_table_scroll.dart';
import '../models/nomina.dart';
import '../providers/nomina_provider.dart';
import '../utils/nomina_report_helper.dart';
import 'nomina_detalle_modal.dart';
import 'nomina_nuevo_periodo_modal.dart';

class NominaProcesarTab extends StatefulWidget {
  const NominaProcesarTab({super.key});

  @override
  State<NominaProcesarTab> createState() => _NominaProcesarTabState();
}

class _NominaProcesarTabState extends State<NominaProcesarTab> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NominaProvider>().loadNominas();
    });
  }

  void _abrirNuevoPeriodo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => NominaNuevoPeriodoModal(
        onSave: (data) async {
          final prov = context.read<NominaProvider>();
          final nueva = await prov.createNomina(data);
          if (mounted) {
            CompactSnackBar.showSuccess(
              context,
              'Periodo ${nueva.codigo} creado con éxito',
            );
          }
        },
      ),
    );
  }

  void _verDesglose(NominaDetalle detalle) {
    showDialog(
      context: context,
      builder: (_) => NominaDetalleModal(detalle: detalle),
    );
  }

  Future<void> _ejecutarCalculo(Nomina nomina) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await context.read<NominaProvider>().calcularNomina(nomina.id);
      if (mounted) {
        CompactSnackBar.showSuccess(
          context,
          'Nómina calculada y cuadrada con éxito según escala TSS e ISR DGII.',
        );
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al calcular: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _ejecutarAprobacion(Nomina nomina) async {
    if (_isProcessing) return;

    final confirmar = await ConfirmDialog.show(
      context: context,
      title: '¿Aprobar Nómina Definitiva?',
      message:
          'Al aprobar la nómina se confirmarán los salarios y deducciones, y se registrará automáticamente el avance de cuotas en los préstamos y ahorros recurrentes.',
      confirmText: 'Sí, Aprobar Nómina',
      confirmIcon: Icons.check_circle_outline,
      type: ConfirmType.success,
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await context.read<NominaProvider>().aprobarNomina(nomina.id);
      if (mounted) {
        CompactSnackBar.showSuccess(
          context,
          'Nómina aprobada. Cuotas recurrentes actualizadas de forma segura.',
        );
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al aprobar: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _ejecutarPago(Nomina nomina) async {
    if (_isProcessing) return;

    final confirmar = await ConfirmDialog.show(
      context: context,
      title: '¿Marcar Nómina como Pagada?',
      message:
          'Esta acción certifica la liquidación efectiva y el desembolso seguro de los haberes a los colaboradores.',
      confirmText: 'Confirmar Pago',
      confirmIcon: Icons.payments_outlined,
      type: ConfirmType.info,
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await context.read<NominaProvider>().pagarNomina(nomina.id);
      if (mounted) {
        CompactSnackBar.showSuccess(context, 'Nómina marcada como PAGADA.');
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al pagar: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _ejecutarAnulacion(Nomina nomina) async {
    if (_isProcessing) return;

    final motivoCtrl = TextEditingController();
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: '¿Anular Periodo de Nómina?',
      message:
          'Esta acción anulará el periodo. Si la nómina ya había sido aprobada, el sistema revertirá atómicamente el avance de cuotas de préstamos para devolver los saldos a su estado original.',
      confirmText: 'Sí, Anular Nómina',
      confirmIcon: Icons.block,
      type: ConfirmType.danger,
      content: TextField(
        controller: motivoCtrl,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: 'Motivo de Anulación (Opcional)',
          hintText: 'Ej. Error en reporte de comisiones o rectificación',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await context.read<NominaProvider>().anularNomina(
            nomina.id,
            motivo: motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim(),
          );
      if (mounted) {
        CompactSnackBar.showSuccess(
          context,
          'Nómina anulada y cuotas revertidas exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al anular: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmarEliminarBorrador(Nomina nomina) async {
    if (_isProcessing) return;

    final confirmar = await ConfirmDialog.show(
      context: context,
      title: '¿Eliminar Periodo en Borrador?',
      message:
          '¿Seguro que deseas eliminar el periodo "${nomina.codigo} - ${nomina.titulo}"? Esta acción limpiará este borrador no procesado.',
      confirmText: 'Sí, Eliminar Borrador',
      confirmIcon: Icons.delete_outline,
      type: ConfirmType.danger,
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await context.read<NominaProvider>().deleteNomina(nomina.id);
      if (mounted) {
        CompactSnackBar.showSuccess(context, 'Periodo borrador eliminado.');
      }
    } catch (e) {
      if (mounted) CompactSnackBar.showError(context, 'Error al eliminar: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NominaProvider>();
    final nomina = prov.nominaSeleccionada;

    if (prov.isLoading && nomina == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.nominas.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Selector de Nómina y Acciones de Cabecera ───────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fila 1: Selector de Periodo y Badges
                Wrap(
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
                            Icons.receipt_long,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Periodo:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: nomina?.id,
                              isDense: true,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              items: prov.nominas.map((n) {
                                return DropdownMenuItem<int>(
                                  value: n.id,
                                  child: Text(
                                    '${n.codigo} - ${n.titulo}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id != null) prov.selectNomina(id);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (nomina != null) _buildEstadoBadge(nomina.estado),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _abrirNuevoPeriodo,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text(
                        'Nuevo Periodo',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),

                if (nomina != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  // Fila 2: Fechas del Periodo en columnas estructuradas + Barra de Acciones
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // Chips de Fecha
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.date_range_outlined, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 5),
                                Text(
                                  'Periodo: ${nomina.fechaInicioFormatted} al ${nomina.fechaFinFormatted}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.payments_outlined, size: 13, color: Color(0xFF2563EB)),
                                const SizedBox(width: 5),
                                Text(
                                  'Pago: ${nomina.fechaPagoFormatted}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Botones de Acción
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Botón Calcular Nómina
                          if (nomina.estado != 'aprobada' &&
                              nomina.estado != 'pagada' &&
                              nomina.estado != 'anulada') ...[
                            CustomButton(
                              text: 'Calcular Nómina',
                              icon: Icons.bolt,
                              isLoading: _isProcessing,
                              onPressed: () => _ejecutarCalculo(nomina),
                            ),
                          ],

                          // Botón Aprobar Nómina
                          if (nomina.estado == 'calculada') ...[
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () => _ejecutarAprobacion(nomina),
                              icon: _isProcessing
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text(
                                'Aprobar Nómina',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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

                          // Botón Pagar Nómina
                          if (nomina.estado == 'aprobada') ...[
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () => _ejecutarPago(nomina),
                              icon: _isProcessing
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.payments_outlined, size: 14),
                              label: const Text(
                                'Pagar Nómina',
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
                          ],

                          // Botón Anular Nómina
                          if (nomina.estado == 'calculada' || nomina.estado == 'aprobada') ...[
                            OutlinedButton.icon(
                              onPressed: _isProcessing ? null : () => _ejecutarAnulacion(nomina),
                              icon: const Icon(Icons.block, size: 13, color: Color(0xFFDC2626)),
                              label: const Text(
                                'Anular',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                backgroundColor: const Color(0xFFFEF2F2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],

                          // Botón Descartar Borrador (Solo si está en estado 'borrador')
                          if (nomina.estado == 'borrador') ...[
                            Tooltip(
                              message: 'Eliminar este periodo en borrador',
                              child: OutlinedButton.icon(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _confirmarEliminarBorrador(nomina),
                                icon: const Icon(Icons.delete_outline,
                                    size: 14, color: Color(0xFFDC2626)),
                                label: const Text(
                                  'Eliminar Borrador',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],

                          // ── BOTONES DE IMPRESIÓN Y EXPORTACIÓN ──
                          if (nomina.detalles.isNotEmpty) ...[
                            // Volantes de Pago
                            OutlinedButton.icon(
                              onPressed: () => NominaReportHelper.abrirTodosLosVolantes(context, nomina.id),
                              icon: const Icon(Icons.receipt_long_outlined, size: 14, color: Color(0xFF2563EB)),
                              label: const Text(
                                'Imprimir Volantes',
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
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),

                            // Reporte General de Nómina
                            OutlinedButton.icon(
                              onPressed: () => NominaReportHelper.abrirReporteGeneral(context, nomina.id),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: Color(0xFF0F172A)),
                              label: const Text(
                                'Reporte Nómina',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                backgroundColor: const Color(0xFFF8FAFC),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),

                            // Descargar Excel (.xlsx)
                            OutlinedButton.icon(
                              onPressed: () => NominaReportHelper.descargarExcelGeneral(context, nomina.id),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (nomina != null) ...[
            // ── Totales de Cuadre de Nómina ───────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFinanceCard(
                  title: 'TOTAL INGRESOS',
                  amount: nomina.totalIngresos,
                  color: const Color(0xFF16A34A),
                  icon: Icons.trending_up,
                ),
                _buildFinanceCard(
                  title: 'TOTAL DEDUCCIONES',
                  amount: nomina.totalDeducciones,
                  color: const Color(0xFFDC2626),
                  icon: Icons.trending_down,
                ),
                _buildFinanceCard(
                  title: 'CUADRE NÓMINA (NETO A PAGAR)',
                  amount: nomina.totalNeto,
                  subtitle: '${nomina.detalles.length} colaboradores procesados',
                  color: const Color(0xFF2563EB),
                  icon: Icons.account_balance,
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Tabla de Empleados en la Nómina ───────────────────
            Expanded(
              child: nomina.detalles.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              size: 36,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Esta nómina aún no ha sido calculada',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Haz clic en "Calcular Nómina" para jalar los colaboradores activos y aplicar las deducciones de ley.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              text: 'Calcular Nómina Ahora',
                              icon: Icons.bolt,
                              isLoading: _isProcessing,
                              onPressed: () => _ejecutarCalculo(nomina),
                            ),
                          ],
                        ),
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
                            dataRowMinHeight: 44,
                            dataRowMaxHeight: 50,
                            columnSpacing: 18,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF8FAFC),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'EMPLEADO / CÉDULA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'SALARIO BASE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'INGRESOS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'DEDUCCIONES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'NETO A COBRAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'DESGLOSE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                            rows: nomina.detalles.map((d) {
                              final emp = d.empleado;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          emp?.nombreCompleto ??
                                              'Empleado #${d.empleadoId}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          emp?.cedula != null
                                              ? Formatters.formatCedula(emp!.cedula)
                                              : '—',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(
                                        d.salarioPeriodo,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(
                                        d.totalIngresos,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      Formatters.formatCurrency(
                                        d.totalDeducciones,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFBBF7D0),
                                        ),
                                      ),
                                      child: Text(
                                        Formatters.formatCurrency(d.netoPagar),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 16,
                                            color: Color(0xFF2563EB),
                                          ),
                                          tooltip: 'Ver Desglose Completo (TSS, ISR, Cuotas)',
                                          onPressed: () => _verDesglose(d),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print_outlined,
                                            size: 16,
                                            color: Color(0xFF475569),
                                          ),
                                          tooltip: 'Imprimir Volante de Pago',
                                          onPressed: () => NominaReportHelper.abrirVolanteIndividual(
                                            context,
                                            nomina.id,
                                            d.id,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 36,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No hay periodos de nómina creados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Comienza creando el primer periodo quincenal o mensual para procesar los salarios de tus colaboradores.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Crear Primer Periodo',
              icon: Icons.add,
              onPressed: _abrirNuevoPeriodo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color bg;
    Color fg;
    String label = estado.toUpperCase();

    switch (estado.toLowerCase()) {
      case 'borrador':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
      case 'calculada':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'aprobada':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'pagada':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'anulada':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildFinanceCard({
    required String title,
    required double amount,
    String? subtitle,
    required Color color,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
