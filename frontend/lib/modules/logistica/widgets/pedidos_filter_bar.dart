import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/pedido_provider.dart';
import '../providers/ruta_provider.dart';
import '../../led_house/providers/ledhouse_cliente_provider.dart';
import '../../led_house/models/ledhouse_cliente.dart';
import '../../users/providers/users_provider.dart';

class PedidosFilterBar extends StatefulWidget {
  const PedidosFilterBar({super.key});

  @override
  State<PedidosFilterBar> createState() => _PedidosFilterBarState();
}

class _PedidosFilterBarState extends State<PedidosFilterBar> {
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  TextEditingController? _clienteSearchCtrl;

  int? _clienteFiltro;
  int? _vendedorFiltro;
  int? _rutaFiltro;
  String _estadoFiltro = 'todos';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedhouseClienteProvider>().fetchClientes();
      context.read<RutaProvider>().fetchRutas();
      context.read<UsersProvider>().fetchUsers();
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<PedidoProvider>();
    provider.setFiltros(
      estado: _estadoFiltro == 'todos' ? null : _estadoFiltro,
      clienteId: _clienteFiltro,
      rutaId: _rutaFiltro,
      vendedorId: _vendedorFiltro,
      startDate: _startDate != null ? _dateFmt.format(_startDate!) : null,
      endDate: _endDate != null ? _dateFmt.format(_endDate!) : null,
    );
    provider.fetchPedidos();
  }

  void _clearFilters() {
    _clienteSearchCtrl?.clear();
    setState(() {
      _clienteFiltro = null;
      _vendedorFiltro = null;
      _rutaFiltro = null;
      _estadoFiltro = 'todos';
      _startDate = null;
      _endDate = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<LedhouseClienteProvider>().clientes;
    final rutas = context.watch<RutaProvider>().rutas;
    final usuarios = context.watch<UsersProvider>().users;
    
    final vendedores = usuarios.where((u) {
      final roles = u['roles'] as List<dynamic>? ?? [];
      return roles.any((r) => r['name'] == 'vendedor');
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1C1E),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildSearchableClienteDropdown(clientes),
          _buildDropdown<int?>(
            value: _vendedorFiltro,
            hint: 'Vendedor',
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los vendedores'),
              ),
              ...vendedores.map(
                (v) => DropdownMenuItem<int?>(value: v['id'], child: Text(v['name'] ?? '')),
              ),
            ],
            onChanged: (v) {
              setState(() => _vendedorFiltro = v);
            },
          ),
          _buildDropdown<int?>(
            value: _rutaFiltro,
            hint: 'Ruta',
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todas las rutas'),
              ),
              ...rutas.map(
                (r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.nombre)),
              ),
            ],
            onChanged: (v) {
              setState(() => _rutaFiltro = v);
            },
          ),
          _buildDropdown<String>(
            value: _estadoFiltro,
            hint: 'Estado',
            items: const [
              DropdownMenuItem(value: 'todos', child: Text('Todos')),
              DropdownMenuItem(value: 'borrador', child: Text('Borrador')),
              DropdownMenuItem(value: 'enviado', child: Text('Enviado')),
              DropdownMenuItem(value: 'facturado', child: Text('Facturado')),
              DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _estadoFiltro = v);
            },
          ),
          _dateRangeButton(),
          _actionButton(
            icon: Icons.filter_list,
            label: 'Aplicar',
            color: const Color(0xFFE31E24),
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

  Widget _buildSearchableClienteDropdown(List<LedhouseCliente> clientes) {
    return Container(
      height: 36,
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Autocomplete<LedhouseCliente>(
        displayStringForOption: (c) => c.nombre,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<LedhouseCliente>.empty();
          }
          return clientes.where((c) => 
            c.nombre.toLowerCase().contains(textEditingValue.text.toLowerCase())
          );
        },
        onSelected: (LedhouseCliente selection) {
          setState(() {
            _clienteFiltro = selection.id;
          });
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          _clienteSearchCtrl = textEditingController;
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIconConstraints: const BoxConstraints(maxHeight: 20, maxWidth: 20),
              suffixIcon: _clienteFiltro != null
                ? InkWell(
                    onTap: () {
                      textEditingController.clear();
                      setState(() => _clienteFiltro = null);
                    },
                    child: const Icon(Icons.clear, color: Colors.white54, size: 14),
                  )
                : const Icon(Icons.search, color: Colors.white38, size: 14),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 220,
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(
                          option.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
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
        color: const Color(0xFF2C2F33).withValues(alpha: 0.7),
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
          dropdownColor: const Color(0xFF2C2F33),
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
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
    } else if (_startDate != null) {
      label = 'Desde: ${_dateFmt.format(_startDate!)}';
    } else if (_endDate != null) {
      label = 'Hasta: ${_dateFmt.format(_endDate!)}';
    }

    return InkWell(
      onTap: () async {
        final result = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFE31E24),
                  onPrimary: Colors.white,
                  surface: Color(0xFF1A1C1E),
                  onSurface: Colors.white,
                ),
                scaffoldBackgroundColor: const Color(0xFF1A1C1E),
                datePickerTheme: DatePickerThemeData(
                  rangeSelectionOverlayColor: WidgetStateProperty.all(
                    const Color(0xFF1A73E8).withValues(alpha: 0.2),
                  ),
                  rangePickerBackgroundColor: const Color(0xFF1A1C1E),
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: Color(0xFF1A1C1E),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 550,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: child!,
                  ),
                ),
              ),
            );
          },
        );
        if (result != null) {
          setState(() {
            _startDate = result.start;
            _endDate = result.end;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F33).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white54, size: 14),
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
