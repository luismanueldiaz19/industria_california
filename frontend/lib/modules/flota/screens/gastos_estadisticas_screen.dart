import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  // Chart colors palette
  static const List<Color> _palette = [
    Color(0xFFE31E24),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
  ];

  static const List<String> _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
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

  Map<int, double> _parsePorMes(dynamic raw) {
    if (raw == null) return {};
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
  }

  Map<String, Map<int, double>> _parseGrouped(dynamic raw) {
    if (raw == null) return {};
    final outer = raw as Map<String, dynamic>;
    return outer.map((key, inner) {
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
            onPressed: () =>
                context.read<GastoVehiculoProvider>().generarPdf(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31E24)),
            )
          : _data == null
              ? const Center(
                  child: Text(
                    'Sin datos',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final porMes = _parsePorMes(_data!['por_mes']);
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

          // ── Gráfico 1: Total por mes ──────────────────────────────
          _ChartCard(
            title: 'Total de Gastos por Mes',
            subtitle: 'Monto acumulado mensual ($_selectedYear)',
            child: SizedBox(
              height: 220,
              child: _buildBarChart(porMes, _palette[0]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Gráfico 2: Por vehículo (líneas) ─────────────────────
          _ChartCard(
            title: 'Gasto por Vehículo',
            subtitle: 'Total mensual por ficha de vehículo',
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: _buildLineChart(porVehiculo),
                ),
                const SizedBox(height: 8),
                _buildLegend(porVehiculo.keys.toList()),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Gráfico 3: Por tipo de gasto (líneas) ────────────────
          _ChartCard(
            title: 'Gasto por Tipo',
            subtitle: 'Total mensual por tipo de gasto',
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: _buildLineChart(porTipo),
                ),
                const SizedBox(height: 8),
                _buildLegend(porTipo.keys.toList()),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> porMes, Color color) {
    final maxY = porMes.values.fold(0.0, (a, b) => a > b ? a : b);
    final bars = List.generate(12, (i) {
      final mes = i + 1;
      final val = porMes[mes] ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            color: val > 0 ? color : color.withOpacity(0.15),
            width: 14,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 1000 : maxY * 1.2,
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFF3A3D42),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) => Text(
                _meses[val.toInt()],
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (val, _) => Text(
                _compact(val),
                style: const TextStyle(color: Colors.white38, fontSize: 8),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '\$${NumberFormat('#,##0.00').format(rod.toY)}',
              const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<String, Map<int, double>> groups) {
    final keys = groups.keys.toList();
    final lines = keys.asMap().entries.map((entry) {
      final color = _palette[entry.key % _palette.length];
      final monthData = groups[entry.value]!;
      final spots = List.generate(12, (i) {
        return FlSpot((i).toDouble(), monthData[i + 1] ?? 0.0);
      });
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.07),
        ),
      );
    }).toList();

    double maxY = 0;
    for (final g in groups.values) {
      for (final v in g.values) {
        if (v > maxY) maxY = v;
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxY == 0 ? 1000 : maxY * 1.2,
        lineBarsData: lines,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFF3A3D42),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= 12) return const SizedBox.shrink();
                return Text(
                  _meses[i],
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                );
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (val, _) => Text(
                _compact(val),
                style: const TextStyle(color: Colors.white38, fontSize: 8),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '\$${NumberFormat('#,##0.00').format(s.y)}',
                      TextStyle(
                        color: lines[s.barIndex].color,
                        fontSize: 10,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(List<String> keys) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: keys.asMap().entries.map((entry) {
        final color = _palette[entry.key % _palette.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              entry.value.toUpperCase(),
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _compact(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;
  const _YearSelector({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      6,
      (i) => DateTime.now().year - i,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          dropdownColor: const Color(0xFF2C2F33),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
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
