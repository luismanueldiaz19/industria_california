import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/app_theme.dart';
import '../../models/cxc_model.dart';
import '../../providers/cxc_provider.dart';
import '../../widgets/cxc_form_dialog.dart';
import '../../../componentes/dialog_confimacion_delete.dart';

class CxcClienteDataTable extends StatelessWidget {
  final List<CxcModel> cxcs;
  final Map<String, dynamic> cliente;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final NumberFormat currencyFormatter;

  const CxcClienteDataTable({
    super.key,
    required this.cxcs,
    required this.cliente,
    required this.searchController,
    required this.onSearchChanged,
    required this.currencyFormatter,
  });

  bool _isPastDue(String fechaVencimiento, String estado) {
    if (estado.toLowerCase() == 'pagado' || estado.toLowerCase() == 'cancelado') {
      return false;
    }
    try {
      final date = DateTime.parse(fechaVencimiento);
      final todayDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      return date.isBefore(todayDate);
    } catch (e) {
      return false;
    }
  }

  int _diasVencidos(String fechaVencimiento, String estado) {
    if (estado.toLowerCase() == 'pagado' || estado.toLowerCase() == 'cancelado') {
      return 0;
    }
    try {
      final date = DateTime.parse(fechaVencimiento);
      final todayDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final diff = todayDate.difference(date).inDays;
      return diff > 0 ? diff : 0;
    } catch (e) {
      return 0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pagado':
        return AppTheme.successColor;
      case 'cancelado':
        return AppTheme.dangerColor;
      default:
        return AppTheme.accentYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por documento...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                  filled: true,
                  fillColor: AppTheme.darkInputColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.darkBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.darkBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.ledhouseBlue),
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),
          if (cxcs.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No se encontraron documentos.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.darkBgColor),
                      dataRowMinHeight: 45,
                      dataRowMaxHeight: 45,
                      headingRowHeight: 40,
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                      columns: const [
                        DataColumn(label: Text('DOCUMENTO')),
                        DataColumn(label: Text('FACTURA')),
                        DataColumn(label: Text('DEUDA PENDIENTE')),
                        DataColumn(label: Text('VENCIMIENTO')),
                        DataColumn(label: Text('ESTADO')),
                        DataColumn(label: Text('ACCIONES')),
                      ],
                      rows: cxcs.map((cxc) {
                        final pastDue = _isPastDue(cxc.fechaVencimiento, cxc.estado);
                        final dias = _diasVencidos(cxc.fechaVencimiento, cxc.estado);

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  if (cliente['whatsapp'] != null && cliente['whatsapp'].toString().trim().isNotEmpty)
                                    IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 16),
                                      tooltip: 'WhatsApp',
                                      padding: const EdgeInsets.only(right: 8),
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        String mensaje = 'Hola *${cliente['nombre']}*,\n\nLe recordamos que tiene un saldo pendiente con *Ledhouse*.\n\n';
                                        mensaje += '*Doc:* ${cxc.documento}\n*Vencimiento:* ${cxc.fechaVencimiento}\n';
                                        if (dias > 0) mensaje += '*Días de atraso:* $dias días\n';
                                        mensaje += '*Monto:* ${currencyFormatter.format(cxc.montoPendiente)}\n\nPor favor, contáctenos para coordinar el pago. Gracias.';

                                        String phone = cliente['whatsapp'].toString().replaceAll(RegExp(r'\D'), '');
                                        if (!phone.startsWith('1') && phone.length == 10) phone = '1$phone';
                                        if (phone.isNotEmpty) {
                                          final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(mensaje)}');
                                          if (!await launchUrl(url)) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('No se pudo abrir WhatsApp', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: pastDue ? AppTheme.dangerColor.withOpacity(0.1) : AppTheme.ledhouseBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_rounded,
                                      size: 14,
                                      color: pastDue ? AppTheme.dangerColor : AppTheme.ledhouseBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cxc.documento,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade300),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                currencyFormatter.format(cxc.montoFactura),
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                currencyFormatter.format(cxc.montoPendiente),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: pastDue ? AppTheme.dangerColor : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                cxc.fechaVencimiento,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ),
                            DataCell(
                              dias > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.dangerColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        '$dias d',
                                        style: const TextStyle(color: AppTheme.dangerColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(cxc.estado).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _getStatusColor(cxc.estado).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        cxc.estado.toUpperCase(),
                                        style: TextStyle(color: _getStatusColor(cxc.estado), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppTheme.ledhouseBlue, size: 16),
                                    tooltip: 'Editar',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => CxcFormDialog(cxc: cxc),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: AppTheme.dangerColor, size: 16),
                                    tooltip: 'Eliminar',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      if (cxc.id != null) {
                                        DialogConfirmacionDelete.mostrar(
                                          context,
                                          titulo: 'Eliminar Documento',
                                          mensaje: '¿Está seguro de que desea eliminar este documento? Esta acción no se puede deshacer.',
                                          onConfirm: () async {
                                            await Provider.of<CxcProvider>(context, listen: false).deleteCxc(cxc.id!);
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
