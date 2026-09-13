import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_theme.dart';
import '../../models/cxc_alerta_model.dart';

class LedhouseAlertasDataTable extends StatelessWidget {
  final List<CxcAlertaModel> alertas;
  final bool isPendiente;
  final Set<int> facturasRepetidasIds;
  
  final void Function(CxcAlertaModel, String) onResolverAlerta;
  final void Function(CxcAlertaModel) onEliminarAlerta;
  final void Function(CxcAlertaModel) onProcesarAlerta;
  final void Function(List<EvidenciaModel>) onVerEvidencias;
  final void Function(CxcAlertaModel, Color) onVerNota;

  const LedhouseAlertasDataTable({
    super.key,
    required this.alertas,
    required this.isPendiente,
    required this.facturasRepetidasIds,
    required this.onResolverAlerta,
    required this.onEliminarAlerta,
    required this.onProcesarAlerta,
    required this.onVerEvidencias,
    required this.onVerNota,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return ts;
    }
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'pago_recibido':
        return '💵 Pago Recibido';
      case 'credito':
        return '💳 Nota de credito';
      case 'debito':
        return '🧾 Nota de débito';
      case 'devolucion':
        return '↩️ Devolución';
      case 'retencion':
        return '✂️ Retención';
      case 'diferencia':
        return '⚖️ Diferencia de Precio';
      case 'mer_no_entregada':
        return '📦 Mercancía No Entregada';
      case 'anular':
        return '❌ Anular Factura';
      case 'consulta':
        return '❓ Consulta';
      case 'informacion':
      default:
        return '📝 Información';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendiente
                  ? Icons.notifications_none
                  : Icons.check_circle_outline,
              size: 72,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              isPendiente ? 'Sin alertas pendientes' : 'Sin alertas procesadas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkBorderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: AppTheme.darkBorderColor,
                  dataTableTheme: DataTableThemeData(
                    headingRowColor: WidgetStateProperty.all(
                      AppTheme.darkInputColor,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.blueAccent.withValues(alpha: 0.05);
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
                child: DataTable(
                  dataRowMinHeight: 45,
                  dataRowMaxHeight: 60,
                  columnSpacing: 16,
                  headingRowHeight: 36,
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                  columns: const [
                    DataColumn(label: Text('FECHA')),
                    DataColumn(label: Text('CLIENTE')),
                    DataColumn(label: Text('CONCEPTO')),
                    DataColumn(label: Text('FACTURA')),
                    DataColumn(label: Text('MONTO')),
                    DataColumn(label: Text('ACCIONES')),
                  ],
                  rows: alertas.map((a) => _buildDataRow(context, a)).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, CxcAlertaModel alerta) {
    final tipo = alerta.tipo;
    final cxc = alerta.cxc;
    final cliente = cxc?.cliente;

    Color tipoColor;
    switch (tipo) {
      case 'pago_recibido':
        tipoColor = Colors.greenAccent;
        break;
      case 'consulta':
        tipoColor = Colors.blueAccent;
        break;
      case 'credito':
      case 'debito':
      case 'devolucion':
      case 'retencion':
        tipoColor = Colors.purpleAccent;
        break;
      default:
        tipoColor = Colors.orangeAccent;
    }

    final listaEvidencias = <EvidenciaModel>[];
    final idsVistos = <int>{};
    for (var ev in alerta.evidencias) {
      if (!idsVistos.contains(ev.id)) {
        listaEvidencias.add(ev);
        idsVistos.add(ev.id);
      }
    }
    if (alerta.cxc?.evidencias != null) {
      for (var ev in alerta.cxc!.evidencias) {
        if (!idsVistos.contains(ev.id)) {
          listaEvidencias.add(ev);
          idsVistos.add(ev.id);
        }
      }
    }

    return DataRow(
      cells: [
        DataCell(
          Text(
            _formatTimestamp(alerta.createdAt),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            cliente?.nombre ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tipoColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        size: 11,
                        color: tipoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _tipoLabel(tipo),
                        style: TextStyle(
                          color: tipoColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alerta.nota != null && alerta.nota!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => onVerNota(alerta, tipoColor),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver nota',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cxc?.noFactura ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              if (cxc != null && facturasRepetidasIds.contains(cxc.id))
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: 'Esta factura tiene múltiples alertas',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            alerta.montoInformado != null
                ? _formatCurrency(alerta.montoInformado!)
                : '-',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.successColor,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPendiente) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.visibility_outlined, color: Colors.orangeAccent, size: 18),
                  tooltip: 'Marcar revisada (Mover a procesadas)',
                  onPressed: () => onResolverAlerta(alerta, 'procesada'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  tooltip: 'Eliminar alerta',
                  onPressed: () => onEliminarAlerta(alerta),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 18),
                  tooltip: 'Procesar',
                  onPressed: () => onProcesarAlerta(alerta),
                ),
              ] else ...[
                Tooltip(
                  message: 'Procesada por ${alerta.revisador?.name ?? '-'}',
                  child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  tooltip: 'Eliminar alerta',
                  onPressed: () => onEliminarAlerta(alerta),
                ),
              ],
              if (listaEvidencias.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.attach_file, color: Colors.redAccent, size: 18),
                  tooltip: 'Ver evidencias',
                  onPressed: () => onVerEvidencias(listaEvidencias),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
