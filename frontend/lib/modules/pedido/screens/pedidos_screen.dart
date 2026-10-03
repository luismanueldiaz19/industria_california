import 'package:flutter/material.dart';
import 'package:industria_california/core/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/general_header.dart';
import '../providers/pedido_provider.dart';
import '../widgets/pedidos_filter_bar.dart';
import '../widgets/pedidos_table.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  Future<void> _generarReporteGeneralPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando Reporte General...')),
    );
    try {
      final urlStr = await context.read<PedidoProvider>().getGeneralPdfUrl();
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GeneralHeader(
            title: 'Gestión de Pedidos',
            subtitle: 'Oficina / Administración',
            icon: Icons.shopping_cart,
            iconColor: Color(0xFFE31E24),
            actions: [
              HeaderButton(
                icon: Icons.picture_as_pdf,
                tooltip: 'Reporte General',
                onTap: _generarReporteGeneralPdf,
              ),
            ],
          ),
          const PedidosFilterBar(),
          const Expanded(child: PedidosTable()),
        ],
      ),
    );
  }
}
