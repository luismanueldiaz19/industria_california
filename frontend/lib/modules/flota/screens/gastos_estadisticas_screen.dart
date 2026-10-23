import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/http_service.dart';
import '../providers/gasto_vehiculo_provider.dart';

class GastosEstadisticasScreen extends StatefulWidget {
  const GastosEstadisticasScreen({super.key});

  @override
  State<GastosEstadisticasScreen> createState() =>
      _GastosEstadisticasScreenState();
}

class _GastosEstadisticasScreenState extends State<GastosEstadisticasScreen> {
  final _http = HttpService();
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  Map<String, dynamic>? _data;

  static const List<String> _meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _http.get(
        'industria-california/vehiculos/gastos/estadisticas',
        params: {'year': _selectedYear.toString()},
      );
      setState(() => _data = res as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, Map<int, double>> _parseGrouped(dynamic raw) {
    if (raw == null) return {};
    if (raw is List) {
      if (raw.isEmpty) return {};
      // If for some reason it's a non-empty list, we return empty map or try to parse
      return {};
    }
    final outer = raw as Map<String, dynamic>;
    return outer.map((key, inner) {
      if (inner == null) return MapEntry(key, <int, double>{});
      if (inner is List) {
        if (inner.isEmpty) return MapEntry(key, <int, double>{});
        return MapEntry(key, <int, double>{});
      }
      final innerMap = (inner as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      );
      return MapEntry(key, innerMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text(
          'Estadísticas de Gastos',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          // Year picker
          _YearSelector(
            year: _selectedYear,
            onChanged: (y) {
              setState(() => _selectedYear = y);
              _loadData();
            },
          ),
          // PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
            tooltip: 'Exportar PDF',
            onPressed: () => context
                .read<GastoVehiculoProvider>()
                .generarPdfEstadisticas(_selectedYear),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            )
          : _data == null
          ? const Center(
              child: Text('Sin datos', style: TextStyle(color: Colors.white54)),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final porVehiculo = _parseGrouped(_data!['por_vehiculo']);
    final porTipo = _parseGrouped(_data!['por_tipo']);
    final totalYear = (_data!['total_year'] as num).toDouble();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total anual chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2F33),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total $_selectedYear',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '\$${fmt.format(totalYear)}',
                  style: const TextStyle(
                    color: Color(0xFFE31E24),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildTable('Gasto por Vehículo', porVehiculo),
          const SizedBox(height: 24),
          _buildTable('Gasto por Tipo', porTipo),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTable(String title, Map<String, Map<int, double>> data) {
    if (data.isEmpty) return const SizedBox();

    final fmt = NumberFormat('#,##0.00', 'en_US');
    final keys = data.keys.toList()..sort();

    // Calcular totales por columna
    final List<double> totalesMes = List.filled(12, 0.0);
    double granTotal = 0.0;

    for (final key in keys) {
      final meses = data[key]!;
      for (int i = 1; i <= 12; i++) {
        final val = meses[i] ?? 0.0;
        totalesMes[i - 1] += val;
        granTotal += val;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F33),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2C2F33)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF1E2124)),
              border: const TableBorder(
                horizontalInside: BorderSide(color: Colors.white12),
                verticalInside: BorderSide(color: Colors.white12),
              ),
              columnSpacing: 24,
              columns: [
                const DataColumn(
                  label: Text(
                    'Item',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                for (final mes in _meses)
                  DataColumn(
                    label: Text(
                      mes,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                const DataColumn(
                  label: Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              rows: [
                for (final key in keys)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      for (int i = 1; i <= 12; i++)
                        DataCell(
                          _buildCellNumber(data[key]![i] ?? 0.0, fmt),
                        ),
                      DataCell(
                        _buildCellNumber(
                          List.generate(
                            12,
                            (i) => data[key]![i + 1] ?? 0.0,
                          ).fold(0.0, (a, b) => a + b),
                          fmt,
                          isRowTotal: true,
                        ),
                      ),
                    ],
                  ),
                // Total General Row
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF2C2F33)),
                  cells: [
                    const DataCell(
                      Text(
                        'Total general',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    for (int i = 0; i < 12; i++)
                      DataCell(
                        _buildTotalGeneralCell(totalesMes[i], fmt),
                      ),
                    DataCell(
                      _buildTotalGeneralCell(granTotal, fmt, isGranTotal: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye la celda numérica destacando los meses donde hubo gastos reales (> 0)
  /// y atenuando los ceros (0.00) para facilitar la lectura inmediata de datos.
  Widget _buildCellNumber(
    double val,
    NumberFormat fmt, {
    bool isRowTotal = false,
  }) {
    if (val <= 0.0) {
      return Text(
        '0.00',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.22),
          fontSize: 11.5,
          fontWeight: FontWeight.normal,
        ),
      );
    }

    if (isRowTotal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Text(
          fmt.format(val),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF93C5FD), // Azul celeste brillante
            fontSize: 12.5,
          ),
        ),
      );
    }

    // Celda de mes con gasto real (> 0): badge suave con texto blanco brillante
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        fmt.format(val),
        style: const TextStyle(
          color: Colors.white, // Blanco brillante nítido
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Construye la celda para la fila de Total General
  Widget _buildTotalGeneralCell(
    double val,
    NumberFormat fmt, {
    bool isGranTotal = false,
  }) {
    if (val <= 0.0) {
      return Text(
        '0.00',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.22),
          fontSize: 11.5,
          fontWeight: FontWeight.normal,
        ),
      );
    }

    if (isGranTotal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Text(
          fmt.format(val),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFFFCA5A5), // Rojo destacado
            fontSize: 13.5,
          ),
        ),
      );
    }

    // Mes en Total General con gastos acumulados (> 0)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Text(
        fmt.format(val),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF86EFAC), // Verde brillante
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _YearSelector extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;
  const _YearSelector({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final years = List.generate(6, (i) => DateTime.now().year - i);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          dropdownColor: const Color(0xFF2C2F33),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white54,
            size: 16,
          ),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
