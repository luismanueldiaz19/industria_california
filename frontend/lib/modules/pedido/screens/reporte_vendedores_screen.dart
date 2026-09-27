import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/general_header.dart';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando PDF...')));
    try {
      final urlStr = await context
          .read<ReporteVendedoresProvider>()
          .getReportePdfUrl();
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
          GeneralHeader(
            title: 'Análisis de Ventas por Vendedor',
            subtitle: 'Agrupación de pedidos · Gráficos · PDF',
            icon: Icons.bar_chart_rounded,
            iconColor: Color(0xFFE31E24),
            actions: [
              HeaderButton(
                icon: Icons.picture_as_pdf,
                tooltip: 'Reporte General',
                onTap: _generarPdf,
              ),
            ],
          ),

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
            child: Text(
              prov.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
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
