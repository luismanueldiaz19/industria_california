import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../providers/reporte_vendedores_provider.dart';
import 'reporte_vendedores_constants.dart';

/// Fila con dos gráficos de barras: pedidos por mes y por vendedor×mes.
class ReporteVendedoresGraficos extends StatelessWidget {
  final ReporteVendedoresProvider prov;
  const ReporteVendedoresGraficos({super.key, required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.graficoMeses.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _GraficoMeses(datos: prov.graficoMeses)),
        const SizedBox(width: 12),
        Expanded(
          child: _GraficoVendedoresMes(datos: prov.graficoVendedoresMeses),
        ),
      ],
    );
  }
}

// ── Gráfico 1: pedidos totales por mes ────────────────────────────────────────

class _GraficoMeses extends StatelessWidget {
  final List<GraficoMesDato> datos;
  const _GraficoMeses({required this.datos});

  @override
  Widget build(BuildContext context) {
    final maxY = datos
        .map((d) => d.totalPedidos.toDouble())
        .reduce(math.max);
    final interval = math.max(1.0, (maxY / 4).ceilToDouble());

    return _GraficoContainer(
      title: 'Pedidos por Mes',
      subtitle: 'Total de pedidos mensual',
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.25,
          gridData: _gridH(interval),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: _leftTitles(interval),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= datos.length) {
                    return const SizedBox.shrink();
                  }
                  final parts = datos[idx].mesLabel.split(' ');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      parts.isNotEmpty ? parts[0] : datos[idx].mesLabel,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: datos.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.totalPedidos.toDouble(),
                  color: kColorAccent,
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.25,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => kColorBg,
              getTooltipItem: (group, _, rod, __) {
                final d = datos[group.x];
                return BarTooltipItem(
                  '${d.mesLabel}\n${rod.toY.toInt()} pedidos',
                  const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gráfico 2: pedidos por vendedor × mes ─────────────────────────────────────

class _GraficoVendedoresMes extends StatelessWidget {
  final List<GraficoVendedorMes> datos;
  const _GraficoVendedoresMes({required this.datos});

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const SizedBox.shrink();

    final meses = datos.map((d) => d.mes).toSet().toList()..sort();
    final vendedores = datos.map((d) => d.vendedorNombre).toSet().toList()
      ..sort();

    double maxY = 0;
    for (final m in meses) {
      final suma = datos
          .where((d) => d.mes == m)
          .fold(0.0, (acc, d) => acc + d.totalPedidos);
      if (suma > maxY) maxY = suma;
    }

    final interval = math.max(1.0, (maxY / 4).ceilToDouble());
    final barWidth = math.max(8.0, 28.0 / vendedores.length);

    return _GraficoContainer(
      title: 'Pedidos por Vendedor / Mes',
      subtitle: 'Comparativa mensual por vendedor',
      legend: vendedores
          .asMap()
          .entries
          .map(
            (e) => _LegendItem(
              label: e.value.length > 14
                  ? '${e.value.substring(0, 12)}…'
                  : e.value,
              color: colorPorVendedor(e.key),
            ),
          )
          .toList(),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.3,
          groupsSpace: 10,
          gridData: _gridH(interval),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: _leftTitles(interval, reservedSize: 28),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= meses.length) {
                    return const SizedBox.shrink();
                  }
                  final parts = meses[idx].split('-');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      parts.length >= 2
                          ? mesAbreviado(int.tryParse(parts[1]) ?? 1)
                          : meses[idx],
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: meses.asMap().entries.map((mesEntry) {
            return BarChartGroupData(
              x: mesEntry.key,
              barsSpace: 2,
              barRods: vendedores.asMap().entries.map((vEntry) {
                final punto = datos.firstWhere(
                  (d) =>
                      d.mes == mesEntry.value &&
                      d.vendedorNombre == vEntry.value,
                  orElse: () => GraficoVendedorMes(
                    vendedorNombre: vEntry.value,
                    mes: mesEntry.value,
                    totalPedidos: 0,
                    totalMonto: 0,
                  ),
                );
                return BarChartRodData(
                  toY: punto.totalPedidos.toDouble(),
                  color: colorPorVendedor(vEntry.key),
                  width: barWidth,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                );
              }).toList(),
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => kColorBg,
              getTooltipItem: (group, _, rod, rodIdx) {
                if (rodIdx >= vendedores.length) return null;
                return BarTooltipItem(
                  '${vendedores[rodIdx]}\n${rod.toY.toInt()} ped.',
                  TextStyle(color: colorPorVendedor(rodIdx), fontSize: 9),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers compartidos ────────────────────────────────────────────────────────

FlGridData _gridH(double interval) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: Colors.white.withValues(alpha: 0.07), strokeWidth: 1),
    );

AxisTitles _leftTitles(double interval, {double reservedSize = 30}) =>
    AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: reservedSize,
        interval: interval,
        getTitlesWidget: (v, _) => Text(
          v.toInt().toString(),
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ),
    );

// ── Contenedor visual de gráfico ───────────────────────────────────────────────

class _GraficoContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> legend;

  const _GraficoContainer({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: legend),
          ],
          const SizedBox(height: 10),
          SizedBox(height: 180, child: child),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
      ],
    );
  }
}
