import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_table_scroll.dart';
import '../models/empleado.dart';

/// Tabla responsiva de empleados envuelta en [CustomTableScroll] con soporte
/// para ancho completo responsivo y scroll horizontal/vertical fluido.
class EmpleadosTable extends StatelessWidget {
  final List<Empleado> empleados;
  final ValueChanged<Empleado> onEdit;

  const EmpleadosTable({
    super.key,
    required this.empleados,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTableScroll(
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 52,
        columnSpacing: 18,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
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
              'CARGO / DEPTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'SALARIO MENSUAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'QUINCENAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'VALOR HORA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'LEYES (TSS/ISR)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'FECHAS (ING / SAL)',
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
        rows: empleados.map((emp) {
          return DataRow(
            cells: [
              // 1. Columna combinada: Nombre Completo y Cédula abajo
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        emp.nombres.isNotEmpty ? emp.nombres[0] : 'E',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatCedula(emp.cedula),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Cargo / Departamento
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.ocupacion ?? '—',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (emp.departamento != null &&
                        emp.departamento!.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        emp.departamento!,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Salario Mensual
              DataCell(
                Text(
                  Formatters.formatCurrency(emp.salarioMensual),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),

              // 4. Salario Quincenal
              DataCell(
                Text(
                  Formatters.formatCurrency(emp.salarioQuincenal),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),

              // 5. Salario Hora
              DataCell(
                Text(
                  'RD\$ ${emp.salarioHora.toStringAsFixed(2)}/h',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),

              // 6. Leyes (AFP / ARS / ISR)
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPill('AFP', emp.aplicaAfp),
                    const SizedBox(width: 3),
                    _buildPill('ARS', emp.aplicaArs),
                    const SizedBox(width: 3),
                    _buildPill('ISR', emp.aplicaIsr),
                  ],
                ),
              ),

              // 7. Fechas (Ingreso / Salida)
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          size: 12,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatDateStr(emp.fechaIngreso),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    if (emp.fechaSalida != null &&
                        emp.fechaSalida!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            size: 12,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatDateStr(emp.fechaSalida),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 8. Estado
              DataCell(_buildEstadoBadge(emp.estado)),

              // 9. Acciones
              DataCell(
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: Color(0xFF2563EB),
                  ),
                  tooltip: 'Editar / Cambiar Estado',
                  onPressed: () => onEdit(emp),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: active ? const Color(0xFF166534) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color bg;
    Color fg;
    String label;

    switch (estado.toLowerCase()) {
      case 'activo':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Activo';
        break;
      case 'inactivo':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'Inactivo';
        break;
      case 'vacaciones':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Vacaciones';
        break;
      case 'licencia':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        label = 'Licencia';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = estado.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
