import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../services/http_service.dart';
import '../providers/cxc_provider.dart';
import '../services/cxc_service.dart';
import '../widgets/cxc_form_dialog.dart';

// Import newly extracted widgets
import '../widgets/cliente_detail/cxc_cliente_header_card.dart';
import '../widgets/cliente_detail/cxc_cliente_data_table.dart';
import '../widgets/cliente_detail/cxc_cliente_totals_bar.dart';

class CxcClienteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> clienteAgrupado;

  const CxcClienteDetailScreen({super.key, required this.clienteAgrupado});

  @override
  State<CxcClienteDetailScreen> createState() => _CxcClienteDetailScreenState();
}

class _CxcClienteDetailScreenState extends State<CxcClienteDetailScreen> {
  final currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  bool _isImporting = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _clienteId => widget.clienteAgrupado['id'];

  bool _isPastDue(String fechaVencimiento, String estado) {
    if (estado.toLowerCase() == 'pagado' || estado.toLowerCase() == 'cancelado')
      return false;
    try {
      final date = DateTime.parse(fechaVencimiento);
      final todayDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      return date.isBefore(todayDate);
    } catch (_) {
      return false;
    }
  }

  Future<void> _importExcel() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkCardColor,
        surfaceTintColor: AppTheme.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.darkBorderColor, width: 1),
        ),
        elevation: 24,
        shadowColor: Colors.black26,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Importar CXC',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppTheme.darkBorderColor, height: 1),
                const SizedBox(height: 20),
                Text(
                  'El archivo Excel/CSV debe seguir estrictamente este orden de columnas. La primera fila se ignorará (encabezados).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.darkBorderColor),
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.darkInputColor,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFormatRow(
                        'Columna A',
                        'Documento (Factura)',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna B',
                        'Monto Deuda Actual',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna C',
                        'Fecha Factura (YYYY-MM-DD)',
                        isRequired: true,
                      ),
                      _buildFormatRow(
                        'Columna D',
                        'Monto Factura Original',
                        isRequired: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ledhouseBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Importar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (file != null) {
        if (!mounted) return;
        setState(() => _isImporting = true);

        final bytes = await file.readAsBytes();

        final cxcService = CxcService();
        final response = await cxcService.importarExcel(
          _clienteId,
          bytes,
          file.name,
        );

        if (!mounted) return;
        setState(() => _isImporting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Importación exitosa'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Provider.of<CxcProvider>(context, listen: false).fetchCxcs();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Widget _buildFormatRow(String col, String desc, {required bool isRequired}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.darkBorderColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              col,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: isRequired
                    ? AppTheme.dangerColor.withOpacity(0.4)
                    : AppTheme.darkBorderColor,
              ),
              borderRadius: BorderRadius.circular(4),
              color: isRequired
                  ? AppTheme.dangerColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Text(
              isRequired ? 'Obligatorio' : 'Opcional',
              style: TextStyle(
                fontSize: 9,
                color: isRequired ? AppTheme.dangerColor : Colors.grey.shade500,
                fontWeight: isRequired ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.clienteAgrupado;

    return Scaffold(
      backgroundColor: AppTheme.darkBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                cliente['nombre'] ?? 'Detalle Cliente',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDemoMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withOpacity(0.2),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEMO',
                  style: TextStyle(
                    color: Colors.amber.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            tooltip: 'Generar PDF',
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generando PDF, por favor espera...'),
                  ),
                );
                final res = await HttpService().get(
                  'ledhouse/cxc/reporte-pdf-url/$_clienteId',
                );
                final url = Uri.parse(res['url']);
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir el PDF'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al generar PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CxcProvider>(
        builder: (context, provider, _) {
          var clienteCxcs = provider.cxcs
              .where((c) => c.clienteId == _clienteId)
              .toList();

          if (_searchQuery.isNotEmpty) {
            clienteCxcs = clienteCxcs
                .where(
                  (c) => c.documento.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();
          }

          double totalFacturado = 0;
          double totalPendiente = 0;
          double totalVencido = 0;

          for (var c in clienteCxcs) {
            totalFacturado += c.montoFactura;
            totalPendiente += c.montoPendiente;
            if (_isPastDue(c.fechaVencimiento, c.estado)) {
              totalVencido += c.montoPendiente;
            }
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isMobile = constraints.maxWidth < 600;

              final headerWidget = CxcClienteHeaderCard(
                cliente: cliente,
                currencyFormatter: currencyFormatter,
                isImporting: _isImporting,
                onNewAccount: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) =>
                        CxcFormDialog(preselectedClienteId: _clienteId),
                  );
                  if (result == true && mounted) {
                    provider.fetchCxcs();
                  }
                },
                onImportExcel: _importExcel,
              );

              final tableWidget = CxcClienteDataTable(
                cxcs: clienteCxcs,
                cliente: cliente,
                searchController: _searchController,
                currencyFormatter: currencyFormatter,
                onSearchChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              );

              final totalsWidget = clienteCxcs.isEmpty
                  ? const SizedBox.shrink()
                  : CxcClienteTotalsBar(
                      totalFacturado: totalFacturado,
                      totalPendiente: totalPendiente,
                      totalVencido: totalVencido,
                      isMobile: isMobile,
                    );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(children: [headerWidget, totalsWidget]),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: tableWidget,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  headerWidget,
                  Expanded(child: tableWidget),
                  totalsWidget,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
