import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/alerta_utils.dart';
import '../models/cxc_alerta_model.dart';

class AlertasDataTable extends StatelessWidget {
  final List<CxcAlertaModel> alertas;
  final bool? isPendiente;
  final String? filtroEstado;
  final Set<int> facturasRepetidasIds;
  final void Function(CxcAlertaModel alerta) onGestionarAlerta;

  const AlertasDataTable({
    super.key,
    required this.alertas,
    this.isPendiente,
    this.filtroEstado,
    required this.facturasRepetidasIds,
    required this.onGestionarAlerta,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '-';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return ts;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'pago_recibido':
        return Colors.greenAccent;
      case 'consulta':
        return Colors.blueAccent;
      case 'credito':
      case 'debito':
      case 'devolucion':
      case 'retencion':
        return Colors.purpleAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      final String emptyMsg = (filtroEstado == 'pendiente' || isPendiente == true)
          ? 'Sin alertas pendientes'
          : (filtroEstado == 'procesada' || isPendiente == false)
              ? 'Sin alertas procesadas'
              : 'No se encontraron alertas';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (filtroEstado == 'procesada' || isPendiente == false)
                  ? Icons.check_circle_outline_rounded
                  : Icons.notifications_none_rounded,
              size: 48,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 10),
            Text(
              emptyMsg,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppTheme.darkBorderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: AppTheme.darkBorderColor,
                      dataTableTheme: DataTableThemeData(
                        headingRowColor: WidgetStateProperty.all(
                          AppTheme.darkInputColor,
                        ),
                        dataRowColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.blueAccent.withValues(alpha: 0.08);
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                    child: DataTable(
                      showCheckboxColumn: false,
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 44,
                      columnSpacing: 18,
                      horizontalMargin: 14,
                      headingRowHeight: 32,
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
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
                        DataColumn(label: Text('ESTADO')),
                        DataColumn(label: Text('VENDEDOR')),
                        DataColumn(label: Text('ACCIÓN')),
                      ],
                      rows: alertas.map((a) => _buildRow(context, a)).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, CxcAlertaModel alerta) {
    final tipo = alerta.tipo;
    final cxc = alerta.cxc;
    final cliente = cxc?.cliente;
    final tipoColor = _getTipoColor(tipo);
    final tieneEvidencias =
        alerta.evidencias.isNotEmpty || (cxc?.evidencias.isNotEmpty ?? false);
    final tieneNota = alerta.nota != null && alerta.nota!.trim().isNotEmpty;
    final tieneRepetidas = cxc != null && facturasRepetidasIds.contains(cxc.id);
    final bool rowIsPendiente = alerta.estadoAlerta == 'pendiente';

    return DataRow(
      onSelectChanged: (_) => onGestionarAlerta(alerta),
      cells: [
        // 1. FECHA
        DataCell(
          Text(
            _formatTimestamp(alerta.createdAt),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ),

        // 2. CLIENTE
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              cliente?.nombre ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 3. CONCEPTO (Badge compacto)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: tipoColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: tipoColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AlertaUtils.getTipoLabel(tipo),
                      style: TextStyle(
                        color: tipoColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (tieneNota)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: alerta.nota!,
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              if (tieneEvidencias)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: 'Tiene archivos adjuntos',
                    child: const Icon(
                      Icons.attach_file_rounded,
                      size: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 4. FACTURA
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cxc?.noFactura ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              if (tieneRepetidas)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: 'Factura con múltiples alertas',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 5. MONTO
        DataCell(
          Text(
            alerta.montoInformado != null
                ? _formatCurrency(alerta.montoInformado!)
                : '-',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppTheme.successColor,
            ),
          ),
        ),

        // 6. ESTADO
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: rowIsPendiente
                  ? Colors.orangeAccent.withValues(alpha: 0.12)
                  : Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: rowIsPendiente
                    ? Colors.orangeAccent.withValues(alpha: 0.3)
                    : Colors.greenAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              rowIsPendiente ? 'Pendiente' : 'Procesada',
              style: TextStyle(
                color: rowIsPendiente ? Colors.orangeAccent : Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // 7. VENDEDOR
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              alerta.vendedor?.name ?? '-',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 8. ACCIÓN / GESTIONAR
        DataCell(
          InkWell(
            onTap: () => onGestionarAlerta(alerta),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (rowIsPendiente ? AppTheme.ledhouseBlue : Colors.greenAccent).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (rowIsPendiente ? AppTheme.ledhouseBlue : Colors.greenAccent).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    rowIsPendiente ? Icons.tune_rounded : Icons.visibility_rounded,
                    size: 12,
                    color: rowIsPendiente ? AppTheme.ledhouseBlue : Colors.greenAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rowIsPendiente ? 'Gestionar' : 'Ver',
                    style: TextStyle(
                      color: rowIsPendiente ? AppTheme.ledhouseBlue : Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
