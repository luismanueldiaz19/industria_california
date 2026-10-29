import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../models/empleado.dart';
import '../providers/empleado_provider.dart';
import 'empleado_form_modal.dart';
import 'empleados_table.dart';

class EmpleadosTab extends StatefulWidget {
  const EmpleadosTab({super.key});

  @override
  State<EmpleadosTab> createState() => _EmpleadosTabState();
}

class _EmpleadosTabState extends State<EmpleadosTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmpleadoProvider>().loadEmpleados();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirModalEmpleado([Empleado? empleado]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmpleadoFormModal(
        empleado: empleado,
        onSave: (data) async {
          final prov = context.read<EmpleadoProvider>();
          if (empleado == null) {
            await prov.createEmpleado(data);
            if (mounted) {
              CompactSnackBar.showSuccess(
                context,
                'Empleado creado exitosamente',
              );
            }
          } else {
            await prov.updateEmpleado(empleado.id, data);
            if (mounted) {
              CompactSnackBar.showSuccess(context, 'Empleado actualizado');
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EmpleadoProvider>();
    final resumen = prov.resumen;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Resumen Cards ───────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatCard(
                title: 'Total Empleados',
                value: '${resumen['total_empleados'] ?? 0}',
                subtitle: '${resumen['activos'] ?? 0} activos para nómina',
                icon: Icons.people_outline,
                color: const Color(0xFF2563EB),
              ),
              _buildStatCard(
                title: 'Masa Salarial Mensual',
                value: Formatters.formatCurrency(
                  resumen['masa_salarial_mensual'] ?? 0,
                ),
                subtitle: 'Presupuesto total',
                icon: Icons.monetization_on_outlined,
                color: const Color(0xFF16A34A),
              ),
              _buildStatCard(
                title: 'Masa Salarial Quincenal',
                value: Formatters.formatCurrency(
                  resumen['masa_salarial_quincenal'] ?? 0,
                ),
                subtitle: 'Cálculo por periodo',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF0284C7),
              ),
              _buildStatCard(
                title: 'Vacaciones / Licencia',
                value:
                    '${(resumen['en_vacaciones'] ?? 0) + (resumen['en_licencia'] ?? 0)}',
                subtitle: '${resumen['inactivos'] ?? 0} inactivos',
                icon: Icons.beach_access_outlined,
                color: const Color(0xFFEA580C),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Barra de Filtros y Búsqueda ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Búsqueda
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 34,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => prov.setSearchQuery(v),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, cédula o cargo...',
                        hintStyle: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  prov.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Filtro Estado
                Wrap(
                  spacing: 4,
                  children: [
                    _buildFilterChip(
                      'todos',
                      'Todos',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'activo',
                      'Activos',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'vacaciones',
                      'Vacaciones',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                    _buildFilterChip(
                      'inactivo',
                      'Inactivos',
                      prov.filtroEstado,
                      (s) => prov.setFiltroEstado(s),
                    ),
                  ],
                ),
                const Spacer(),

                // Botón Refrescar
                IconButton(
                  tooltip: 'Refrescar colaboradores',
                  icon: prov.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                  onPressed: prov.isLoading ? null : () => prov.loadEmpleados(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),

                // Botón Nuevo Empleado
                CustomButton(
                  text: 'Nuevo Empleado',
                  icon: Icons.person_add_rounded,
                  onPressed: () => _abrirModalEmpleado(),
                  height: 34,
                  fontSize: 11.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tabla de Empleados ──────────────────────────────────
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prov.empleados.isEmpty
                ? _buildEmptyState()
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: EmpleadosTable(
                        empleados: prov.empleados,
                        onEdit: _abrirModalEmpleado,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
              Icons.people_outline,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            const Text(
              'No se encontraron empleados registrados',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Haz clic en "Nuevo Empleado" para registrar al primer colaborador.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            CustomButton(
              onPressed: () => _abrirModalEmpleado(),
              icon: Icons.person_add_rounded,
              text: 'Registrar Primer Empleado',
              height: 34,
              fontSize: 11.5,
              color: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}
