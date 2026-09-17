import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/reporte_vendedores_provider.dart';
import '../widgets/reporte_vendedores_constants.dart';
import '../widgets/reporte_vendedores_filter_bar.dart';
import '../widgets/reporte_vendedores_graficos.dart';
import '../widgets/reporte_vendedores_resumen.dart';
import '../widgets/reporte_vendedores_tabla.dart';

/// Pantalla de análisis de pedidos agrupados por vendedor.
/// Solo orquesta los widgets hijos y maneja las acciones de nivel de pantalla.
class ReporteVendedoresScreen extends StatefulWidget {
  const ReporteVendedoresScreen({super.key});

  @override
  State<ReporteVendedoresScreen> createState() =>
      _ReporteVendedoresScreenState();
}

class _ReporteVendedoresScreenState extends State<ReporteVendedoresScreen> {
  final _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReporteVendedoresProvider>().fetchReporte();
    });
  }

  // ── Acciones de pantalla ──────────────────────────────────────────────────

  void _aplicarFiltros({
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final prov = context.read<ReporteVendedoresProvider>();
    prov.setFiltros(
      startDate: startDate != null ? _dateFmt.format(startDate) : null,
      endDate: endDate != null ? _dateFmt.format(endDate) : null,
      search: search,
    );
    prov.fetchReporte();
  }

  void _limpiarFiltros() {
    final prov = context.read<ReporteVendedoresProvider>();
    prov.setFiltros(startDate: null, endDate: null, search: null);
    prov.fetchReporte();
  }

  Future<void> _generarPdf() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Generando PDF...')));
    try {
      final urlStr =
          await context.read<ReporteVendedoresProvider>().getReportePdfUrl();
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2124),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScreenHeader(onPdf: _generarPdf),
          ReporteVendedoresFilterBar(
            onApply: _aplicarFiltros,
            onClear: _limpiarFiltros,
          ),
          Expanded(child: _BodyContent()),
        ],
      ),
    );
  }
}

// ── Header de pantalla ────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  final VoidCallback onPdf;
  const _ScreenHeader({required this.onPdf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kColorSurface,
        border: Border(bottom: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _HeaderTitle(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: onPdf,
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kColorAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              const Icon(Icons.bar_chart_rounded, color: kColorAccent, size: 28),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análisis de Ventas por Vendedor',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Agrupación de pedidos · Gráficos · PDF',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _BodyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReporteVendedoresProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kColorAccent),
          );
        }
        if (prov.error != null) {
          return Center(
            child: Text(prov.error!,
                style: const TextStyle(color: Colors.redAccent)),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReporteVendedoresResumen(prov: prov),
              const SizedBox(height: 16),
              ReporteVendedoresGraficos(prov: prov),
              const SizedBox(height: 16),
              ReporteVendedoresTabla(prov: prov),
            ],
          ),
        );
      },
    );
  }
}
