import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cheque_futurista.dart';
import '../providers/cheque_admin_provider.dart';
import '../utils/cheque_admin_utils.dart';
import 'cheque_admin_detalle_sheet.dart';

/// Tabla del panel admin de cheques. Mismo look que [PedidosTable].
class ChequesAdminTable extends StatefulWidget {
  const ChequesAdminTable({super.key});

  @override
  State<ChequesAdminTable> createState() => _ChequesAdminTableState();
}

class _ChequesAdminTableState extends State<ChequesAdminTable> {
  final ScrollController _scrollCtrl = ScrollController();

  static const _headerStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ChequeAdminProvider>().fetchCheques();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiarEstadoRapido(
    ChequeFuturista cheque,
    ChequeEstadoInfo e,
  ) async {
    if (e.value == cheque.estado) return;
    final color = ChequeAdminUtils.colorEstado(e.value);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChequeAdminColors.card,
        title: const Text(
          'Cambiar estado',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          '¿Cambiar el cheque N° ${cheque.numCheque} (${cheque.nombreCliente}) a "${e.label.toUpperCase()}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ChequeAdminProvider>().cambiarEstado(cheque, e.value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado cambiado a ${e.label}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChequeAdminProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (provider.isLoading && provider.cheques.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ChequeAdminColors.red),
      );
    }

    if (provider.error != null && provider.cheques.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 10),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => provider.fetchCheques(refresh: true),
              icon: const Icon(Icons.refresh, color: ChequeAdminColors.red),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: ChequeAdminColors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.cheques.isEmpty) {
      return const Center(
        child: Text(
          'No hay cheques encontrados.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ChequeAdminColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            showCheckboxColumn: false,
                      columnSpacing: 20,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 54,
                      headingRowHeight: 40,
                      headingRowColor: WidgetStateProperty.all(
                        ChequeAdminColors.header,
                      ),
                      dividerThickness: 0.5,
                      columns: const [
                        DataColumn(label: Text('#', style: _headerStyle)),
                        DataColumn(label: Text('Registro', style: _headerStyle)),
                        DataColumn(label: Text('F. Depósito', style: _headerStyle)),
                        DataColumn(label: Text('Cliente', style: _headerStyle)),
                        DataColumn(label: Text('N° Cheque', style: _headerStyle)),
                        DataColumn(label: Text('Vendedor', style: _headerStyle)),
                        DataColumn(label: Text('Comentario', style: _headerStyle)),
                        DataColumn(label: Text('Estado', style: _headerStyle)),
                        DataColumn(label: Text('Alertas', style: _headerStyle)),
                        DataColumn(label: Text('Evid.', style: _headerStyle)),
                        DataColumn(
                          numeric: true,
                          label: Text('Monto', style: _headerStyle),
                        ),
                        DataColumn(label: Text('Acciones', style: _headerStyle)),
                      ],
                      rows: provider.cheques
                          .map((c) => _buildRow(c, isAdmin))
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
                if (provider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: ChequeAdminColors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildFooter(provider),
      ],
    );
  }

  DataRow _buildRow(ChequeFuturista cheque, bool isAdmin) {
    final colorEstado = ChequeAdminUtils.colorEstado(cheque.estado);
    final alerta = ChequeAdminUtils.alerta(
      cheque.estado,
      cheque.createdAt,
      cheque.fechaDeposito,
    );

    Color? rowColor;
    if (alerta == ChequeAlerta.deposito) {
      rowColor = Colors.redAccent.withValues(alpha: 0.08);
    } else if (alerta == ChequeAlerta.registro) {
      rowColor = Colors.orangeAccent.withValues(alpha: 0.05);
    }

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.04);
        }
        return rowColor;
      }),
      onSelectChanged: (_) => showChequeAdminDetalleSheet(context, cheque),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alerta != ChequeAlerta.ninguna)
                Container(
                  width: 3,
                  height: 22,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: alerta == ChequeAlerta.deposito
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Text(
                '#${cheque.id}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            ChequeAdminUtils.fmt(cheque.createdAt, 'dd/MM/yyyy HH:mm'),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        DataCell(
          Text(
            cheque.fechaDeposito != null
                ? ChequeAdminUtils.fmt(cheque.fechaDeposito)
                : 'No def.',
            style: TextStyle(
              color: cheque.fechaDeposito != null
                  ? Colors.amberAccent
                  : Colors.white38,
              fontSize: 11,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              cheque.nombreCliente.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            cheque.numCheque,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            cheque.nombreVendedor ?? 'N/A',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              cheque.comentario ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorEstado.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorEstado.withValues(alpha: 0.5)),
            ),
            child: Text(
              cheque.estado.toUpperCase(),
              style: TextStyle(
                color: colorEstado,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(_alertasCell(cheque)),
        DataCell(_evidenciasCell(cheque)),
        DataCell(
          Text(
            Formatters.formatCurrency(cheque.monto),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: 'Ver detalle y evidencias',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => showChequeAdminDetalleSheet(context, cheque),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<ChequeEstadoInfo>(
                tooltip: 'Cambiar estado',
                color: ChequeAdminColors.card,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (e) => _cambiarEstadoRapido(cheque, e),
                itemBuilder: (_) => ChequeAdminUtils.estados.map((e) {
                  final color = ChequeAdminUtils.colorEstado(e.value);
                  final selected = e.value == cheque.estado;
                  return PopupMenuItem<ChequeEstadoInfo>(
                    value: e,
                    height: 36,
                    enabled: !selected,
                    child: Row(
                      children: [
                        Icon(e.icon, size: 16, color: color),
                        const SizedBox(width: 10),
                        Text(
                          e.label,
                          style: TextStyle(
                            color: selected ? color : Colors.white,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check, size: 14, color: color),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Muestra las dos alertas: días desde registro y desde depósito.
  Widget _alertasCell(ChequeFuturista cheque) {
    final pendiente = cheque.estado.toLowerCase() == 'pendiente';
    final dReg = ChequeAdminUtils.diasDesde(cheque.createdAt) ?? 0;
    final dDep = ChequeAdminUtils.diasDesde(cheque.fechaDeposito);

    final regAlert = pendiente && dReg > ChequeAdminUtils.diasAlertaRegistro;
    final depAlert =
        pendiente && dDep != null && dDep > ChequeAdminUtils.diasAlertaDeposito;

    String depText;
    Color depColor;
    if (dDep == null) {
      depText = 'Dep: —';
      depColor = Colors.white24;
    } else if (dDep < 0) {
      depText = 'Dep: faltan ${-dDep}d';
      depColor = Colors.lightBlueAccent;
    } else if (dDep == 0) {
      depText = 'Dep: hoy';
      depColor = Colors.amberAccent;
    } else {
      depText = 'Dep: +${dDep}d';
      depColor = depAlert ? Colors.redAccent : Colors.white54;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniChip(
          icon: regAlert ? Icons.warning_amber_rounded : Icons.history,
          text: 'Reg: ${dReg}d',
          color: regAlert ? Colors.orangeAccent : Colors.white54,
          strong: regAlert,
        ),
        const SizedBox(height: 3),
        _miniChip(
          icon: depAlert ? Icons.error_outline : Icons.event,
          text: depText,
          color: depColor,
          strong: depAlert,
        ),
      ],
    );
  }

  Widget _miniChip({
    required IconData icon,
    required String text,
    required Color color,
    bool strong = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: strong
          ? BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenciasCell(ChequeFuturista cheque) {
    final n = cheque.documentosCount;
    final color = n > 0 ? Colors.lightBlueAccent : Colors.white24;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_outlined, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          '$n',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ChequeAdminProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: ChequeAdminColors.header,
        border: Border(top: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        children: [
          Text(
            'Total: ${provider.totalFilas}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          _legend(Colors.orangeAccent,
              '+${ChequeAdminUtils.diasAlertaRegistro}d registro'),
          const SizedBox(width: 12),
          _legend(Colors.redAccent,
              '+${ChequeAdminUtils.diasAlertaDeposito}d depósito'),
          const Spacer(),
          Text(
            'Mostrando ${provider.cheques.length}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 20),
          const Text(
            'MONTO TOTAL  ',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            Formatters.formatCurrency(provider.montoTotal),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );
}
