import 'package:flutter/material.dart';
import '../../models/vehiculo_mantenimiento.dart';
import '../../services/vehiculo_service.dart';
import 'package:intl/intl.dart';
import 'mantenimiento_form_modal.dart';

class VehiculoMantenimientosTab extends StatefulWidget {
  final int vehiculoId;

  const VehiculoMantenimientosTab({super.key, required this.vehiculoId});

  @override
  State<VehiculoMantenimientosTab> createState() =>
      _VehiculoMantenimientosTabState();
}

class _VehiculoMantenimientosTabState extends State<VehiculoMantenimientosTab> {
  final VehiculoService _service = VehiculoService();
  bool _isLoading = false;

  List<VehiculoMantenimiento> _todosMantenimientos = [];
  List<VehiculoMantenimiento> _mantenimientos = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 20;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _selectedYear = DateTime.now().year.toString();
  String _selectedTipo = 'Todos';
  String _selectedEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({int page = 1, bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      if (_todosMantenimientos.isEmpty || forceRefresh) {
        _todosMantenimientos = await _service.getMantenimientos(
          widget.vehiculoId,
        );
      }

      _applyFiltersAndPagination(page);
    } catch (e) {
      debugPrint('Error fetching mantenimientos: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFiltersAndPagination(int page) {
    List<VehiculoMantenimiento> filtrados = _todosMantenimientos.where((mant) {
      bool passSearch = true;
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        passSearch =
            (mant.descripcion?.toLowerCase().contains(query) ?? false) ||
            (mant.estado.toLowerCase().contains(query)) ||
            (mant.tipo.toLowerCase().contains(query));
      }

      bool passTipo = true;
      if (_selectedTipo != 'Todos') {
        passTipo = mant.tipo == _selectedTipo;
      }

      bool passEstado = true;
      if (_selectedEstado != 'Todos') {
        passEstado = mant.estado == _selectedEstado;
      }

      bool passYear = true;
      if (_selectedYear != 'Todos' && _selectedYear != 'todos') {
        passYear = mant.fechaReporte?.year.toString() == _selectedYear;
      }

      return passSearch && passTipo && passEstado && passYear;
    }).toList();

    filtrados.sort((a, b) {
      final dateA = a.fechaReporte ?? DateTime.now();
      final dateB = b.fechaReporte ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    _total = filtrados.length;
    _lastPage = (_total / _perPage).ceil();
    if (_lastPage == 0) _lastPage = 1;

    _currentPage = page;
    if (_currentPage > _lastPage) {
      _currentPage = _lastPage;
    }

    final startIndex = (_currentPage - 1) * _perPage;
    _mantenimientos = filtrados.skip(startIndex).take(_perPage).toList();

    setState(() {});
  }

  void _onSearch(String value) {
    _applyFiltersAndPagination(1);
  }

  void _onFilterChanged() {
    _applyFiltersAndPagination(1);
  }

  List<String> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    List<String> years = ['Todos'];
    for (int i = 0; i < 5; i++) {
      years.add((currentYear - i).toString());
    }
    return years;
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'resuelto':
        return Colors.green;
      case 'en_proceso':
        return Colors.orange;
      case 'pendiente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final curFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE31E24),
        onPressed: () async {
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) =>
                MantenimientoFormModal(vehiculoIdFijo: widget.vehiculoId),
          );
          if (result == true) {
            _fetchData(page: 1, forceRefresh: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // FILTROS SUPERIORES
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Buscar libre...',
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                    ),
                    onSubmitted: _onSearch,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    dropdownColor: const Color(0xFF2C2F33),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Año'),
                    items: _getAvailableYears().map((y) {
                      return DropdownMenuItem(value: y, child: Text(y));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectedYear = val;
                        _onFilterChanged();
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _selectedTipo,
                    dropdownColor: const Color(0xFF2C2F33),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'preventivo',
                        child: Text('Preventivo'),
                      ),
                      DropdownMenuItem(
                        value: 'correctivo',
                        child: Text('Correctivo'),
                      ),
                      DropdownMenuItem(value: 'averia', child: Text('Avería')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _selectedTipo = val;
                        _onFilterChanged();
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    dropdownColor: const Color(0xFF2C2F33),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(
                        value: 'en_proceso',
                        child: Text('En Proceso'),
                      ),
                      DropdownMenuItem(
                        value: 'resuelto',
                        child: Text('Resuelto'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _selectedEstado = val;
                        _onFilterChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // CONTENIDO LISTA
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE31E24),
                      ),
                    )
                  : _mantenimientos.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron mantenimientos.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _mantenimientos.length,
                      itemBuilder: (context, index) {
                        final mant = _mantenimientos[index];
                        return Card(
                          color: const Color(0xFF2C2F33),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              mant.tipo.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  mant.descripcion,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fecha: ${mant.fechaReporte != null ? DateFormat('dd/MM/yyyy').format(mant.fechaReporte!) : 'N/A'}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  curFormat.format(mant.costo),
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEstadoColor(
                                      mant.estado,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getEstadoColor(mant.estado),
                                    ),
                                  ),
                                  child: Text(
                                    mant.estado.toUpperCase().replaceAll(
                                      '_',
                                      ' ',
                                    ),
                                    style: TextStyle(
                                      color: _getEstadoColor(mant.estado),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // PAGINACIÓN BOTTOM BAR
            if (_lastPage > 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: $_total',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: _currentPage > 1
                            ? () => _fetchData(page: _currentPage - 1)
                            : null,
                      ),
                      Text(
                        '$_currentPage de $_lastPage',
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: _currentPage < _lastPage
                            ? () => _fetchData(page: _currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
