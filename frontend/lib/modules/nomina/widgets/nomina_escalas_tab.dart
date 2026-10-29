import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_table_scroll.dart';
import '../providers/nomina_provider.dart';

class NominaEscalasTab extends StatelessWidget {
  const NominaEscalasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NominaProvider>();
    final tramos = prov.escalasIsr;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner Explicativo / Cabecera de Modo Seguro ─────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parámetros Fiscales y Escala de Retención DGII (República Dominicana)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Datos leídos directamente de la tabla "nomina_escalas_isr". Modo protegido de solo consulta para evitar eliminaciones accidentales que alteren históricos.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 13, color: Color(0xFF166534)),
                      SizedBox(width: 5),
                      Text(
                        'Protegido / Inmutable',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tarjetas Resumen de Tasas Oficiales ─────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildParamCard(
                title: 'AFP',
                value: '${(prov.tasaAfp * 100).toStringAsFixed(2)}%',
                subtitle: 'Fondo de Pensiones',
                icon: Icons.savings_outlined,
                color: const Color(0xFF2563EB),
              ),
              _buildParamCard(
                title: 'ARS',
                value: '${(prov.tasaArs * 100).toStringAsFixed(2)}%',
                subtitle: 'Seguro Familiar de Salud',
                icon: Icons.health_and_safety_outlined,
                color: const Color(0xFF0284C7),
              ),
              _buildParamCard(
                title: 'TOTAL TSS DEDUCIBLE',
                value: '${(prov.tasaTss * 100).toStringAsFixed(2)}%',
                subtitle: 'Deducción previa a DGII',
                icon: Icons.shield_outlined,
                color: const Color(0xFFD97706),
              ),
              _buildParamCard(
                title: 'MÍNIMO MENSUAL EXENTO',
                value: 'RD\$ 34,685.00',
                subtitle: 'Hasta RD\$ 416,220 anual',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tabla de Tramos Dinámicos DGII ──────────────────────
          Expanded(
            child: Container(
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
                    dataRowMaxHeight: 48,
                    columnSpacing: 18,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'AÑO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'DESCRIPCIÓN DEL TRAMO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'RENTA NETA MENSUAL (DESDE - HASTA)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'TASA (%)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'IMPUESTO BASE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'EXCEDENTE SOBRE',
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
                    ],
                    rows: tramos.isEmpty
                        ? [
                            const DataRow(cells: [
                              DataCell(Text('2026', style: TextStyle(fontSize: 11))),
                              DataCell(Text('Cargando escalas oficiales...', style: TextStyle(fontSize: 11))),
                              DataCell(Text('—', style: TextStyle(fontSize: 11))),
                              DataCell(Text('—', style: TextStyle(fontSize: 11))),
                              DataCell(Text('—', style: TextStyle(fontSize: 11))),
                              DataCell(Text('—', style: TextStyle(fontSize: 11))),
                              DataCell(Text('—', style: TextStyle(fontSize: 11))),
                            ])
                          ]
                        : tramos.map((t) {
                            final rangoMensual = t.hastaMensual != null
                                ? '${Formatters.formatCurrency(t.desdeMensual)} a ${Formatters.formatCurrency(t.hastaMensual)}'
                                : 'Más de ${Formatters.formatCurrency(t.desdeMensual)}';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    t.anio.toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    t.descripcion ?? 'Tramo DGII',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    rangoMensual,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Color(0xFF334155),
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
                                      color: t.tasaPorcentaje == 0
                                          ? const Color(0xFFF1F5F9)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${t.tasaPorcentaje.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: t.tasaPorcentaje == 0
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    Formatters.formatCurrency(
                                      t.impuestoBaseMensual,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    t.excedenteDesdeMensual > 0
                                        ? Formatters.formatCurrency(
                                            t.excedenteDesdeMensual,
                                          )
                                        : '—',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
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
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VIGENTE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
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

  Widget _buildParamCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

