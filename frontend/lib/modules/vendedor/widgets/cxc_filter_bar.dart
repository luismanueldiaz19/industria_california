import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

/// Barra de filtros compacta, moderna e interactiva para Cuentas por Cobrar.
/// Diseñada con estética industrial limpia, alto contraste y usabilidad intuitiva
/// para usuarios principiantes. Cumple con la directriz de Clean Reusable UI.
class CxcFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final bool soloVencidos;
  final ValueChanged<bool> onToggleVencidos;
  final bool conAlerta;
  final ValueChanged<bool> onToggleConAlerta;
  final String? ordenMonto;
  final ValueChanged<String?> onOrdenChanged;
  final VoidCallback onResetFilters;

  const CxcFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.soloVencidos,
    required this.onToggleVencidos,
    required this.conAlerta,
    required this.onToggleConAlerta,
    required this.ordenMonto,
    required this.onOrdenChanged,
    required this.onResetFilters,
  });

  bool get _hasActiveFilters =>
      soloVencidos ||
      conAlerta ||
      ordenMonto != null ||
      searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila 1: Buscador compacto con icono y botón de limpiar
          SizedBox(
            height: 36,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Buscar por factura, NCF o nombre de cliente...',
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: onClearSearch,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Fila 2: Chips interactivos de filtro rápido y ordenamiento
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Chip 1: Solo Vencidos
                _buildFilterChip(
                  label: 'Solo Vencidos',
                  icon: Icons.local_fire_department_rounded,
                  isActive: soloVencidos,
                  activeColor: const Color(0xFFEA4335), // Rojo industrial
                  onTap: () => onToggleVencidos(!soloVencidos),
                ),
                const SizedBox(width: 6),

                // Chip 2: Con Alerta
                _buildFilterChip(
                  label: 'Con Alerta',
                  icon: Icons.notifications_active_rounded,
                  isActive: conAlerta,
                  activeColor: const Color(0xFFF59E0B), // Ámbar/Naranja
                  onTap: () => onToggleConAlerta(!conAlerta),
                ),
                const SizedBox(width: 6),

                // Chip 3: Selector de Ordenamiento por Monto
                _buildSortDropdown(),

                // Chip 4: Botón Restablecer Filtros (si hay alguno activo)
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onResetFilters,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 13,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Limpiar',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle_rounded : icon,
              size: 13,
              color: isActive ? Colors.white : activeColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    final isSorted = ordenMonto != null;

    String sortLabel = 'Ordenar Fecha';
    if (ordenMonto == 'asc') sortLabel = 'Monto: Menor ↑';
    if (ordenMonto == 'desc') sortLabel = 'Monto: Mayor ↓';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isSorted ? AppTheme.primaryBlue : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSorted ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: ordenMonto,
          isDense: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            Icons.swap_vert_rounded,
            size: 14,
            color: isSorted ? Colors.white : const Color(0xFF64748B),
          ),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sortLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSorted ? FontWeight.bold : FontWeight.w600,
                  color: isSorted ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Por defecto (Fecha)',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
              ),
            ),
            DropdownMenuItem(
              value: 'asc',
              child: Text(
                'Monto: Menor a Mayor (ASC)',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
              ),
            ),
            DropdownMenuItem(
              value: 'desc',
              child: Text(
                'Monto: Mayor a Menor (DESC)',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
              ),
            ),
          ],
          onChanged: onOrdenChanged,
        ),
      ),
    );
  }
}
