import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/pedido.dart';
import '../providers/pedido_provider.dart';
import '../utils/pedido_utils.dart';
import 'pedido_gestion_dialog.dart';

class PedidosTable extends StatefulWidget {
  const PedidosTable({super.key});

  @override
  State<PedidosTable> createState() => _PedidosTableState();
}

class _PedidosTableState extends State<PedidosTable> {
  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  void _trabajarPedido(Pedido pedido) {
    PedidoGestionDialog.show(
      context: context,
      pedido: pedido,
      onUpdated: () {
        context.read<PedidoProvider>().fetchPedidos();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoProvider>();

    if (provider.isLoading && provider.pedidos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE31E24)),
      );
    }

    if (provider.pedidos.isEmpty) {
      return const Center(
        child: Text(
          'No hay pedidos encontrados.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2F33),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 20,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 50,
                  headingRowHeight: 40,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF23272A),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.05);
                    }
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF2196F3).withValues(alpha: 0.15);
                    }
                    return Colors.transparent;
                  }),
                  dividerThickness: 0.5,

                  columns: const [
                    DataColumn(
                      label: Text(
                        '#',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'No. Factura',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Fecha',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'F. Entrega',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Cliente',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Estado',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'T. Orig',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Faltante',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Real',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Vendedor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Ruta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  rows: provider.pedidos.map((pedido) {
                    final colorEstado = PedidoUtils.getColorForEstado(
                      pedido.estado,
                    );
                    double faltante = 0;
                    for (var det in pedido.detalles) {
                      faltante +=
                          (det.cantidadEnProduccion * det.precioUnitario);
                    }
                    return DataRow(
                      onSelectChanged: (_) => _trabajarPedido(pedido),
                      cells: [
                        DataCell(
                          Text(
                            '#${pedido.id}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          (pedido.numFactura != null &&
                                  pedido.numFactura!.trim().isNotEmpty)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2196F3,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long,
                                        size: 11,
                                        color: Color(0xFF2196F3),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        pedido.numFactura!,
                                        style: const TextStyle(
                                          color: Color(0xFF2196F3),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Text(
                                  '-',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                        DataCell(
                          Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(pedido.createdAt),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            pedido.fechaEntrega != null
                                ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(pedido.fechaEntrega!)
                                : 'No def.',
                            style: TextStyle(
                              color: pedido.fechaEntrega != null
                                  ? Colors.amberAccent
                                  : Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
                              pedido.clienteNombre ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorEstado.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              pedido.estado.toUpperCase(),
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _currencyFmt.format(pedido.total),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _currencyFmt.format(faltante),
                            style: TextStyle(
                              color: faltante > 0
                                  ? Colors.redAccent
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _currencyFmt.format(pedido.total - faltante),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            pedido.vendedorNombre ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            pedido.rutaNombre ?? 'Sin Asignar',
                            style: TextStyle(
                              color: pedido.rutaNombre == null
                                  ? Colors.redAccent
                                  : Colors.white70,
                              fontSize: 12,
                            ),
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
        _buildPagination(provider),
      ],
    );
  }

  Widget _buildPagination(PedidoProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF23272A),
        border: Border(top: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${provider.total}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (provider.lastPage > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: provider.currentPage > 1
                      ? () => provider.fetchPage(provider.currentPage - 1)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  'Página ${provider.currentPage} de ${provider.lastPage}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: provider.currentPage < provider.lastPage
                      ? () => provider.fetchPage(provider.currentPage + 1)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
