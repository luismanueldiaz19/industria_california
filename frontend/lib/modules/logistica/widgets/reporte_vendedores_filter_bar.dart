import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reporte_vendedores_constants.dart';

/// Barra de filtros del reporte: búsqueda de vendedor y rango de fechas.
/// Llama [onApply] con los valores actuales y [onClear] para resetear.
class ReporteVendedoresFilterBar extends StatefulWidget {
  final void Function({String? search, DateTime? startDate, DateTime? endDate})
      onApply;
  final VoidCallback onClear;

  const ReporteVendedoresFilterBar({
    super.key,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<ReporteVendedoresFilterBar> createState() =>
      _ReporteVendedoresFilterBarState();
}

class _ReporteVendedoresFilterBarState
    extends State<ReporteVendedoresFilterBar> {
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _searchCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _fechaLabel {
    if (_startDate != null && _endDate != null) {
      return '${_dateFmt.format(_startDate!)} — ${_dateFmt.format(_endDate!)}';
    }
    if (_startDate != null) return 'Desde: ${_dateFmt.format(_startDate!)}';
    if (_endDate != null) return 'Hasta: ${_dateFmt.format(_endDate!)}';
    return 'Fechas: Todas';
  }

  Future<void> _abrirDatePicker() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kColorAccent,
            onPrimary: Colors.white,
            surface: kColorBg,
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: kColorBg),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child!,
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  void _clear() {
    _searchCtrl.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: kColorBg,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _SearchField(controller: _searchCtrl),
          _DateRangeButton(label: _fechaLabel, onTap: _abrirDatePicker),
          _FilterButton(
            icon: Icons.filter_list,
            label: 'Aplicar',
            color: kColorAccent,
            onTap: () => widget.onApply(
              search: _searchCtrl.text.trim().isNotEmpty
                  ? _searchCtrl.text.trim()
                  : null,
              startDate: _startDate,
              endDate: _endDate,
            ),
          ),
          _FilterButton(
            icon: Icons.clear,
            label: 'Limpiar',
            color: Colors.white38,
            onTap: _clear,
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets internos (privados al archivo) ────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kColorSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Buscar vendedor...',
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIconConstraints:
              const BoxConstraints(maxHeight: 20, maxWidth: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, __) => val.text.isNotEmpty
                ? InkWell(
                    onTap: controller.clear,
                    child: const Icon(Icons.clear,
                        color: Colors.white54, size: 14),
                  )
                : const Icon(Icons.search, color: Colors.white38, size: 14),
          ),
        ),
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateRangeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: kColorSurface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white54, size: 14),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
