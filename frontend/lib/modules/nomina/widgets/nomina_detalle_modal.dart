import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../models/nomina.dart';
import '../utils/nomina_report_helper.dart';

class NominaDetalleModal extends StatelessWidget {
  final NominaDetalle detalle;

  const NominaDetalleModal({super.key, required this.detalle});

  @override
  Widget build(BuildContext context) {
    final emp = detalle.empleado;
    final ingresos = detalle.conceptos.where((c) => c.tipo == 'ingreso').toList();
    final deducciones = detalle.conceptos.where((c) => c.tipo == 'deduccion').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp?.nombreCompleto ?? 'Empleado Desconocido',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${emp?.ocupacion ?? 'Sin cargo'} • Cédula: ${emp?.cedula ?? '—'}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('NETO A COBRAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                        Text(
                          Formatters.formatCurrency(detalle.netoPagar),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
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
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Métricas Salario Base
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('Salario Mensual', Formatters.formatCurrency(detalle.salarioMensual)),
                    _buildMiniMetric('Salario Periodo', Formatters.formatCurrency(detalle.salarioPeriodo)),
                    _buildMiniMetric('Valor Hora', 'RD\$ ${detalle.salarioHora.toStringAsFixed(2)}/h'),
                    _buildMiniMetric('Días / Horas', '${detalle.diasTrabajados.toInt()}d (${detalle.horasTrabajadas.toInt()}h)'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('INGRESOS / HABERES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                  Text(Formatters.formatCurrency(detalle.totalIngresos), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ingresos.isEmpty
                                  ? const Center(child: Text('Sin ingresos registrados', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))))
                                  : ListView.separated(
                                      itemCount: ingresos.length,
                                      separatorBuilder: (_, _) => const Divider(height: 8, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (ctx, i) {
                                        final item = ingresos[i];
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.concepto?.nombre ?? 'Ingreso', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                                                  if (item.notas != null)
                                                    Text(item.notas!, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              Formatters.formatCurrency(item.monto),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('DEDUCCIONES / DESCUENTOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                                  Text(Formatters.formatCurrency(detalle.totalDeducciones), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: deducciones.isEmpty
                                  ? const Center(child: Text('Sin deducciones aplicadas', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))))
                                  : ListView.separated(
                                      itemCount: deducciones.length,
                                      separatorBuilder: (_, _) => const Divider(height: 8, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (ctx, i) {
                                        final item = deducciones[i];
                                        final isCuota = item.referenciaCuota != null;
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          _cleanDeduccionNombre(item.concepto?.nombre, item.concepto?.codigo),
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isCuota) ...[
                                                        const SizedBox(width: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEFF6FF),
                                                            borderRadius: BorderRadius.circular(3),
                                                          ),
                                                          child: Text(item.referenciaCuota!, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (item.notas != null && item.notas!.trim().isNotEmpty && !item.notas!.contains('%') && !item.notas!.toLowerCase().contains('ley') && !item.notas!.toLowerCase().contains('dgii'))
                                                    Text(item.notas!, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              Formatters.formatCurrency(item.monto),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
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

              const SizedBox(height: 14),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => NominaReportHelper.abrirVolanteIndividual(
                      context,
                      detalle.nominaId,
                      detalle.id,
                    ),
                    icon: const Icon(Icons.print_outlined, size: 14, color: Color(0xFF2563EB)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Cerrar', style: TextStyle(fontSize: 11)),
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
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  String _cleanDeduccionNombre(String? raw, String? codigo) {
    if (codigo == 'AFP_EMP' || (raw != null && raw.contains('AFP'))) return 'AFP';
    if (codigo == 'ARS_EMP' || (raw != null && (raw.contains('ARS') || raw.contains('SFS')))) return 'ARS';
    if (codigo == 'RET_ISR' || (raw != null && raw.contains('ISR'))) return 'ISR';
    return raw ?? 'Deducción';
  }
}
