import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_date_picker_dark.dart';
import '../../../core/widgets/quick_date_filter.dart';
import '../../users/providers/users_provider.dart';
import '../providers/cheque_admin_provider.dart';
import '../utils/cheque_admin_utils.dart';

/// Barra de filtros del panel admin de cheques.
/// Mismo diseño que [PedidosFilterBar]: chips oscuros + Aplicar / Limpiar.
class ChequesAdminFilterBar extends StatefulWidget {
  const ChequesAdminFilterBar({super.key});

  @override
  State<ChequesAdminFilterBar> createState() => _ChequesAdminFilterBarState();
}

class _ChequesAdminFilterBarState extends State<ChequesAdminFilterBar> {
  final DateFormat _dateFmt = DateFormat('dd/MM/yy');
  final TextEditingController _searchCtrl = TextEditingController();

  int? _vendedorFiltro;
  String _estadoFiltro = 'todos';
  String _tipoFecha = 'creacion';
  DateTime? _startDate;
  DateTime? _endDate;
  DateFilterOption _selectedQuickDate = DateFilterOption.todos;
  bool _soloAtrasados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchUsers();
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<ChequeAdminProvider>().aplicarFiltros(
          buscar: _searchCtrl.text,
          estado: _estadoFiltro == 'todos' ? null : _estadoFiltro,
          idVendedor: _vendedorFiltro,
          fechaInicio: _startDate,
          fechaFin: _endDate,
          soloAtrasados: _soloAtrasados,
          tipoFecha: _tipoFecha,
        );
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _vendedorFiltro = null;
      _estadoFiltro = 'todos';
      _tipoFecha = 'creacion';
      _startDate = null;
      _endDate = null;
      _selectedQuickDate = DateFilterOption.todos;
      _soloAtrasados = false;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<UsersProvider>().users;
    final vendedores = usuarios.where((u) {
      final roles = u['roles'] as List<dynamic>? ?? [];
      return roles.any((r) => r['name'] == 'vendedor');
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ChequeAdminColors.bar,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildSearch(),
          _buildDropdown<int?>(
            value: _vendedorFiltro,
            hint: 'Vendedor',
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los vendedores'),
              ),
              ...vendedores.map(
                (v) => DropdownMenuItem<int?>(
                  value: v['id'],
                  child: Text(v['name'] ?? ''),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _vendedorFiltro = v),
          ),
          _buildDropdown<String>(
            value: _estadoFiltro,
            hint: 'Estado',
            items: [
              const DropdownMenuItem(value: 'todos', child: Text('Todos')),
              ...ChequeAdminUtils.estados.map(
                (e) => DropdownMenuItem(value: e.value, child: Text(e.label)),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _estadoFiltro = v);
            },
          ),
          _buildDropdown<String>(
            value: _tipoFecha,
            hint: 'Tipo de fecha',
            items: const [
              DropdownMenuItem(
                value: 'creacion',
                child: Text('Por fecha de registro'),
              ),
              DropdownMenuItem(
                value: 'deposito',
                child: Text('Por fecha de depósito'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _tipoFecha = v);
            },
          ),
          _dateRangeButton(),
          QuickDateFilter(
            isDark: true,
            selectedOption: _selectedQuickDate,
            onChanged: (option) {
              setState(() {
                _selectedQuickDate = option;
                final range = QuickDateFilter.getRangeForFilter(option);
                _startDate = range?.start;
                _endDate = range?.end;
              });
              _loadData();
            },
          ),
          _toggleAtrasados(),
          _actionButton(
            icon: Icons.filter_list,
            label: 'Aplicar',
            color: ChequeAdminColors.red,
            onTap: _loadData,
          ),
          _actionButton(
            icon: Icons.clear,
            label: 'Limpiar',
            color: Colors.white38,
            onTap: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 36,
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ChequeAdminColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (_) => _loadData(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        cursorColor: ChequeAdminColors.red,
        decoration: InputDecoration(
          hintText: 'Buscar cliente o N° cheque...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIconConstraints: const BoxConstraints(
            maxHeight: 20,
            maxWidth: 20,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchCtrl,
            builder: (_, value, __) => value.text.isNotEmpty
                ? InkWell(
                    onTap: () {
                      _searchCtrl.clear();
                      _loadData();
                    },
                    child: const Icon(
                      Icons.clear,
                      color: Colors.white54,
                      size: 14,
                    ),
                  )
                : const Icon(Icons.search, color: Colors.white38, size: 14),
          ),
        ),
      ),
    );
  }

  Widget _toggleAtrasados() {
    return Tooltip(
      message:
          'Pendientes con más de ${ChequeAdminUtils.diasAlertaRegistro} días desde el registro',
      child: InkWell(
        onTap: () {
          setState(() => _soloAtrasados = !_soloAtrasados);
          _loadData();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _soloAtrasados
                ? Colors.redAccent.withValues(alpha: 0.2)
                : ChequeAdminColors.card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _soloAtrasados
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _soloAtrasados ? Colors.redAccent : Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                'Atrasados',
                style: TextStyle(
                  color: _soloAtrasados ? Colors.redAccent : Colors.white,
                  fontSize: 12,
                  fontWeight:
                      _soloAtrasados ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ChequeAdminColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
          dropdownColor: ChequeAdminColors.card,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white38,
            size: 16,
          ),
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRangeButton() {
    String label = 'Fechas: Todas';
    if (_startDate != null && _endDate != null) {
      label = '${_dateFmt.format(_startDate!)} - ${_dateFmt.format(_endDate!)}';
    }
    final hasRange = _startDate != null;

    return InkWell(
      onTap: () async {
        final result = await AppDatePickerDark.showRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
        );
        if (result != null) {
          setState(() {
            _startDate = result.start;
            _endDate = result.end;
            _selectedQuickDate = DateFilterOption.todos;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasRange
              ? ChequeAdminColors.blue.withValues(alpha: 0.15)
              : ChequeAdminColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasRange
                ? ChequeAdminColors.blue.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _tipoFecha == 'deposito' ? Icons.event : Icons.calendar_today,
              color: hasRange ? ChequeAdminColors.blue : Colors.white54,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
