import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';

class AlertasFiltrosBar extends StatelessWidget {
  final List<String> vendedores;
  final List<String> tipos;

  final String filtroVendedor;
  final String filtroTipo;
  final String filtroEstado;
  final bool soloRepetidas;

  final TextEditingController searchController;

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;

  final ValueChanged<String?> onChangedVendedor;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onChangedTipo;
  final ValueChanged<String?> onChangedEstado;
  final ValueChanged<bool> onChangedSoloRepetidas;

  const AlertasFiltrosBar({
    super.key,
    required this.vendedores,
    required this.tipos,
    required this.filtroVendedor,
    required this.filtroTipo,
    required this.filtroEstado,
    required this.soloRepetidas,
    required this.searchController,
    required this.startDate,
    required this.endDate,
    required this.onPickDateRange,
    required this.onClearDateRange,
    required this.onChangedVendedor,
    required this.onSearchChanged,
    required this.onChangedTipo,
    required this.onChangedEstado,
    required this.onChangedSoloRepetidas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.darkCardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Buscador
              SizedBox(
                width: 220,
                child: _buildSearchFiltro(
                  'Buscar cliente, factura...',
                  searchController,
                  onSearchChanged,
                ),
              ),

              // 2. Estado (Pendiente, Procesada, Todas)
              SizedBox(
                width: 140,
                child: _buildDropdownEstado(
                  filtroEstado,
                  onChangedEstado,
                ),
              ),

              // 3. Concepto / Tipo
              SizedBox(
                width: 170,
                child: _buildDropdownFiltro(
                  tipos,
                  filtroTipo,
                  onChangedTipo,
                ),
              ),

              // 4. Vendedor
              SizedBox(
                width: 140,
                child: _buildDropdownFiltro(
                  vendedores,
                  filtroVendedor,
                  onChangedVendedor,
                ),
              ),

              // 5. Selector de Rango de Fechas
              _buildDateRangeButton(
                startDate: startDate,
                endDate: endDate,
                onTap: onPickDateRange,
                onClear: onClearDateRange,
              ),

              // 6. Switch Múltiples Alertas
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Múltiples alertas",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: soloRepetidas,
                      onChanged: onChangedSoloRepetidas,
                      activeTrackColor: AppTheme.ledhouseBlue.withValues(
                        alpha: 0.5,
                      ),
                      activeThumbColor: AppTheme.ledhouseBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFiltro(
    String hint,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 11, color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, size: 15, color: Colors.grey.shade500),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownEstado(
    String value,
    ValueChanged<String?> onChanged,
  ) {
    const items = [
      {'value': 'pendiente', 'label': '🕒 Pendientes'},
      {'value': 'procesada', 'label': '✅ Procesadas'},
      {'value': 'todos', 'label': '📋 Todas'},
    ];

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
            size: 16,
          ),
          dropdownColor: AppTheme.darkCardColor,
          style: const TextStyle(fontSize: 11, color: Colors.white),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(
                item['label']!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownFiltro(
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: validValue,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
            size: 16,
          ),
          dropdownColor: AppTheme.darkCardColor,
          style: const TextStyle(fontSize: 11, color: Colors.white),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangeButton({
    required DateTime? startDate,
    required DateTime? endDate,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasDates = startDate != null && endDate != null;
    final format = DateFormat('dd-MM-yyyy');
    final dateText = hasDates
        ? '${format.format(startDate)}  →  ${format.format(endDate)}'
        : 'Rango de fechas';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDates
              ? Colors.blueAccent.withValues(alpha: 0.6)
              : AppTheme.darkBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: hasDates ? Colors.blueAccent : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasDates ? Colors.white : Colors.grey.shade400,
                    fontWeight: hasDates ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (hasDates) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
