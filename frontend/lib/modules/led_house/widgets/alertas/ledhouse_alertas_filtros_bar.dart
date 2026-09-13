import 'package:flutter/material.dart';
import '../../../../../core/app_theme.dart';

class LedhouseAlertasFiltrosBar extends StatelessWidget {
  final List<String> vendedores;
  final List<String> tipos;
  
  final String filtroVendedor;
  final String searchQuery;
  final String filtroTipo;
  final bool soloRepetidas;
  
  final ValueChanged<String?> onChangedVendedor;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onChangedTipo;
  final ValueChanged<bool> onChangedSoloRepetidas;

  const LedhouseAlertasFiltrosBar({
    super.key,
    required this.vendedores,
    required this.tipos,
    required this.filtroVendedor,
    required this.searchQuery,
    required this.filtroTipo,
    required this.soloRepetidas,
    required this.onChangedVendedor,
    required this.onSearchChanged,
    required this.onChangedTipo,
    required this.onChangedSoloRepetidas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.darkCardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: _buildSearchFiltro(
                  'Buscar cliente, factura...',
                  searchQuery,
                  onSearchChanged,
                ),
              ),
              SizedBox(
                width: 140,
                child: _buildDropdownFiltro(
                  vendedores,
                  filtroVendedor,
                  onChangedVendedor,
                ),
              ),
              SizedBox(
                width: 140,
                child: _buildDropdownFiltro(
                  tipos,
                  filtroTipo,
                  onChangedTipo,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Múltiples alertas",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: soloRepetidas,
                      onChanged: onChangedSoloRepetidas,
                      activeTrackColor: AppTheme.ledhouseBlue.withValues(alpha: 0.5),
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
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.darkInputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        ),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
        ),
      ),
    );
  }

  Widget _buildDropdownFiltro(
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          style: const TextStyle(fontSize: 13, color: Colors.white),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }
}
