import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/orden_produccion_provider.dart';
import 'orden_produccion_detalles_dialog.dart';

class OrdenesProduccionTabla extends StatelessWidget {
  const OrdenesProduccionTabla({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdenProduccionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.ordenes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE31E24)),
          );
        }

        if (provider.ordenes.isEmpty) {
          return const Center(
            child: Text(
              'No hay órdenes de producción encontradas.',
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
                    borderRadius: BorderRadius.circular(8),
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
                      dividerThickness: 0.5,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'OP-#',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Fecha Estimada',
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
                            'Pedido Asoc.',
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
                            'Acciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      rows: provider.ordenes.map((orden) {
                        final estadoColor = _getColorForEstado(orden.estado);
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '#${orden.id}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                orden.fechaEstimadaEntrega != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(orden.fechaEstimadaEntrega!)
                                    : 'No definida',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                orden.cliente?.nombre ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                orden.vendedor?.name ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                orden.pedidoId != null
                                    ? '#${orden.pedidoId}'
                                    : 'N/A',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
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
                                  color: estadoColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: estadoColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  orden.estado.toUpperCase(),
                                  style: TextStyle(
                                    color: estadoColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) =>
                                        OrdenProduccionDetallesDialog(
                                          orden: orden,
                                        ),
                                  );
                                },
                                icon: const Icon(Icons.settings, size: 14),
                                label: const Text(
                                  'Administrar',
                                  style: TextStyle(fontSize: 11),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
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
            _buildPaginationBar(context, provider),
          ],
        );
      },
    );
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'lista':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaginationBar(
    BuildContext context,
    OrdenProduccionProvider provider,
  ) {
    final totalRows = provider.totalRows;
    final totalPages = provider.lastPage;
    final currentPage = provider.currentPage;
    final rowsPerPage = provider.rowsPerPage;
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage > totalRows)
        ? totalRows
        : startIndex + rowsPerPage;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF24262A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                totalRows > 0
                    ? 'Mostrando ${startIndex + 1} - $endIndex de $totalRows registros'
                    : '0 registros',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Por pág:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: rowsPerPage,
                    isDense: true,
                    dropdownColor: const Color(0xFF24262A),
                    iconEnabledColor: Colors.grey.shade400,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 30, child: Text('30')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        provider.setRowsPerPage(val);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.first_page_rounded),
                    color: Colors.grey.shade400,
                    disabledColor: Colors.grey.shade700,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Primera página',
                    onPressed: currentPage > 1
                        ? () => provider.fetchOrdenes(page: 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: Colors.grey.shade400,
                    disabledColor: Colors.grey.shade700,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Página anterior',
                    onPressed: currentPage > 1
                        ? () => provider.fetchOrdenes(page: currentPage - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$currentPage / ${totalPages == 0 ? 1 : totalPages}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: Colors.grey.shade400,
                    disabledColor: Colors.grey.shade700,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Página siguiente',
                    onPressed: currentPage < totalPages
                        ? () => provider.fetchOrdenes(page: currentPage + 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page_rounded),
                    color: Colors.grey.shade400,
                    disabledColor: Colors.grey.shade700,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    tooltip: 'Última página',
                    onPressed: currentPage < totalPages
                        ? () => provider.fetchOrdenes(page: totalPages)
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
