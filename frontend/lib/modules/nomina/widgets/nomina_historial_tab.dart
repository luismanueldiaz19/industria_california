import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../models/nomina.dart';
import '../providers/nomina_provider.dart';
import '../utils/nomina_report_helper.dart';

class NominaHistorialTab extends StatelessWidget {
  final Function(int) onSelectNomina;

  const NominaHistorialTab({super.key, required this.onSelectNomina});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NominaProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header con Filtro Estado
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
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 18, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text(
                      'Historial de Periodos de Nómina',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildFilterChip(
                      'todos',
                      'Todos',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'pagada',
                      'Pagadas',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'aprobada',
                      'Aprobadas',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'calculada',
                      'Calculadas',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'borrador',
                      'Borrador',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lista / Tabla de Nóminas
          Expanded(
            child: prov.nominas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay periodos registrados en el historial.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    itemCount: prov.nominas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final n = prov.nominas[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 780;

                            // Columna 1: Info Periodo
                            Widget buildInfoPeriodo() {
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                n.titulo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _buildEstadoBadge(n.estado),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                n.codigo,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              n.tipoPeriodo.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Columna 2: Fechas del Periodo
                            Widget buildColumnaFechas() {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.date_range_outlined,
                                        size: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Del ${n.fechaInicioFormatted} al ${n.fechaFinFormatted}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF334155),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.payments_outlined,
                                        size: 12,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pago: ${n.fechaPagoFormatted}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            // Columna 3: Totales Ingresos y Deducciones
                            Widget buildColumnaTotales() {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ingresos: ${Formatters.formatCurrency(n.totalIngresos)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Deduc.: ${Formatters.formatCurrency(n.totalDeducciones)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Columna 4: Cuadre Neto
                            Widget buildColumnaNeto() {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'CUADRE NETO',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(n.totalNeto),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Columna 5: Acciones
                            Widget buildAcciones() {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => onSelectNomina(n.id),
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                    ),
                                    label: const Text(
                                      'Ver Nómina',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      foregroundColor: const Color(0xFF1E293B),
                                      elevation: 0,
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    tooltip: 'Imprimir y Exportar',
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 16,
                                      color: Color(0xFF475569),
                                    ),
                                    padding: EdgeInsets.zero,
                                    onSelected: (val) {
                                      switch (val) {
                                        case 'volantes':
                                          NominaReportHelper.abrirTodosLosVolantes(
                                            context,
                                            n.id,
                                          );
                                          break;
                                        case 'reporte':
                                          NominaReportHelper.abrirReporteGeneral(
                                            context,
                                            n.id,
                                          );
                                          break;
                                        case 'excel':
                                          NominaReportHelper.descargarExcelGeneral(
                                            context,
                                            n.id,
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'volantes',
                                        height: 32,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              size: 14,
                                              color: Color(0xFF2563EB),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Imprimir Volantes de Pago',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'reporte',
                                        height: 32,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.picture_as_pdf_outlined,
                                              size: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Reporte General (PDF / Blade)',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'excel',
                                        height: 32,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.table_chart_outlined,
                                              size: 14,
                                              color: Color(0xFF16A34A),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Exportar a Excel (.xlsx)',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (n.estado == 'borrador') ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color: Color(0xFFDC2626),
                                      ),
                                      tooltip: 'Eliminar este borrador',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _confirmarEliminarBorrador(
                                            context,
                                            n,
                                          ),
                                    ),
                                  ],
                                ],
                              );
                            }

                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(flex: 3, child: buildInfoPeriodo()),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: buildColumnaFechas(),
                                  ),
                                  const SizedBox(width: 14),
                                  buildColumnaTotales(),
                                  const SizedBox(width: 16),
                                  buildColumnaNeto(),
                                  const SizedBox(width: 16),
                                  buildAcciones(),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: buildInfoPeriodo()),
                                      const SizedBox(width: 8),
                                      buildAcciones(),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      buildColumnaFechas(),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          buildColumnaTotales(),
                                          const SizedBox(width: 14),
                                          buildColumnaNeto(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarBorrador(
    BuildContext context,
    Nomina nomina,
  ) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: '¿Eliminar Periodo en Borrador?',
      message:
          '¿Deseas descartar el periodo borrador "${nomina.codigo} - ${nomina.titulo}"? Esta acción limpiará este registro no procesado.',
      confirmText: 'Sí, Eliminar Borrador',
      confirmIcon: Icons.delete_outline,
      type: ConfirmType.danger,
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    try {
      await context.read<NominaProvider>().deleteNomina(nomina.id);
      if (context.mounted) {
        CompactSnackBar.showSuccess(context, 'Periodo borrador eliminado.');
      }
    } catch (e) {
      if (context.mounted) {
        CompactSnackBar.showError(context, 'Error al eliminar: $e');
      }
    }
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);

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
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'pagada':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'anulada':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
