import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cheque_futurista_service.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/general_header.dart';
import '../providers/cheque_admin_provider.dart';
import '../utils/cheque_admin_utils.dart';
import '../widgets/cheques_admin_filter_bar.dart';
import '../widgets/cheques_admin_table.dart';

/// Pantalla de administración global de Cheques Futuristas.
/// Utiliza los componentes modulares (Filtros y Tabla).
class ChequesAdminScreen extends StatefulWidget {
  const ChequesAdminScreen({super.key});

  @override
  State<ChequesAdminScreen> createState() => _ChequesAdminScreenState();
}

class _ChequesAdminScreenState extends State<ChequesAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChequeAdminProvider>().fetchCheques(refresh: true);
    });
  }

  void _descargarPdf() async {
    final provider = context.read<ChequeAdminProvider>();
    final service = ChequeFuturistaService();

    try {
      final url = await service.getPdfUrl(
        fechaInicio: provider.fechaInicio?.toIso8601String().split('T').first,
        fechaFin: provider.fechaFin?.toIso8601String().split('T').first,
        buscar: provider.buscar,
        estado: provider.estado,
        idVendedor: provider.idVendedor,
        atrasados: provider.soloAtrasados,
      );

      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el PDF')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
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
            title: 'Gestión de Cheques',
            subtitle: 'Oficina / Administración',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: ChequeAdminColors.red,
            actions: [
              HeaderButton(
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'Generar PDF',
                onTap: _descargarPdf,
              ),
              const SizedBox(width: 8),
              HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualizar',
                onTap: () => context.read<ChequeAdminProvider>().fetchCheques(
                  refresh: true,
                ),
              ),
            ],
          ),
          const ChequesAdminFilterBar(),
          const Expanded(child: ChequesAdminTable()),
        ],
      ),
    );
  }
}
