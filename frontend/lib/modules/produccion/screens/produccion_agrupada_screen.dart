import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/produccion_agrupada_provider.dart';

class ProduccionAgrupadaScreen extends StatefulWidget {
  final TipoAgrupacion tipo;

  const ProduccionAgrupadaScreen({super.key, required this.tipo});

  @override
  State<ProduccionAgrupadaScreen> createState() => _ProduccionAgrupadaScreenState();
}

class _ProduccionAgrupadaScreenState extends State<ProduccionAgrupadaScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProduccionAgrupadaProvider>();
      provider.setSearchQuery('', widget.tipo);
    });
  }

  @override
  void didUpdateWidget(covariant ProduccionAgrupadaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tipo != widget.tipo) {
      _searchController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<ProduccionAgrupadaProvider>();
        provider.setSearchQuery('', widget.tipo);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTitulo() {
    switch (widget.tipo) {
      case TipoAgrupacion.producto:
        return 'Producción por Producto';
      case TipoAgrupacion.pedido:
        return 'Producción por Pedido';
      case TipoAgrupacion.cliente:
        return 'Producción por Cliente';
      case TipoAgrupacion.fecha:
        return 'Producción por Fecha';
    }
  }

  List<DataColumn> _getColumnas() {
    switch (widget.tipo) {
      case TipoAgrupacion.producto:
        return const [
          DataColumn(label: Text('Cód.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cantidad Faltante', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ];
      case TipoAgrupacion.pedido:
        return const [
          DataColumn(label: Text('Pedido Asociado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Órdenes Asociadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ];
      case TipoAgrupacion.cliente:
        return const [
          DataColumn(label: Text('ID Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Nombre Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Órdenes Asociadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ];
      case TipoAgrupacion.fecha:
        return const [
          DataColumn(label: Text('Fecha de Entrega', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Órdenes Asociadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ];
    }
  }

  DataRow _buildRow(Map<String, dynamic> rowData) {
    switch (widget.tipo) {
      case TipoAgrupacion.producto:
        return DataRow(cells: [
          DataCell(Text(rowData['producto_codigo']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white70))),
          DataCell(Text(rowData['producto_nombre']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white))),
          DataCell(Text(
            rowData['cantidad_total']?.toString() ?? '0',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          )),
        ]);
      case TipoAgrupacion.pedido:
        return DataRow(cells: [
          DataCell(Text('#${rowData['pedido_id']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
          DataCell(Text(rowData['cliente_nombre']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white))),
          DataCell(Text(rowData['cantidad_ordenes']?.toString() ?? '0', style: const TextStyle(color: Colors.white70))),
        ]);
      case TipoAgrupacion.cliente:
        return DataRow(cells: [
          DataCell(Text(rowData['cliente_id']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white70))),
          DataCell(Text(rowData['cliente_nombre']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white))),
          DataCell(Text(rowData['cantidad_ordenes']?.toString() ?? '0', style: const TextStyle(color: Colors.white70))),
        ]);
      case TipoAgrupacion.fecha:
        return DataRow(cells: [
          DataCell(Text(rowData['fecha']?.toString() ?? 'Sin fecha', style: const TextStyle(color: Colors.white))),
          DataCell(Text(rowData['cantidad_ordenes']?.toString() ?? '0', style: const TextStyle(color: Colors.white70))),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2124),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildSearchBox(),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F33),
        border: Border(bottom: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.precision_manufacturing,
                  color: Color(0xFFE31E24),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitulo(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Oficina / Producción (Agrupado)',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: const Color(0xFF2C2F33),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF23272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (val) {
                context.read<ProduccionAgrupadaProvider>().setSearchQuery(val, widget.tipo);
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ProduccionAgrupadaProvider>().fetchDatos(widget.tipo, refresh: true);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Consumer<ProduccionAgrupadaProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.datos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE31E24)),
          );
        }

        if (provider.error != null && provider.datos.isEmpty) {
          return Center(
            child: Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        if (provider.datos.isEmpty) {
          return const Center(
            child: Text(
              'No hay registros encontrados.',
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
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F33),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      columnSpacing: 30,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 50,
                      headingRowHeight: 46,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF23272A)),
                      dividerThickness: 0.5,
                      columns: _getColumnas(),
                      rows: provider.datos.map((row) => _buildRow(row)).toList(),
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

  Widget _buildPaginationBar(BuildContext context, ProduccionAgrupadaProvider provider) {
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
                        provider.setRowsPerPage(val, widget.tipo);
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
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Primera página',
                    onPressed: currentPage > 1
                        ? () => provider.fetchDatos(widget.tipo, page: 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: Colors.grey.shade400,
                    disabledColor: Colors.grey.shade700,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Página anterior',
                    onPressed: currentPage > 1
                        ? () => provider.fetchDatos(widget.tipo, page: currentPage - 1)
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
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Página siguiente',
                    onPressed: currentPage < totalPages
                        ? () => provider.fetchDatos(widget.tipo, page: currentPage + 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page_rounded),
                    color: Colors.grey.shade400,
                    disabledColor: Colors.grey.shade700,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    tooltip: 'Última página',
                    onPressed: currentPage < totalPages
                        ? () => provider.fetchDatos(widget.tipo, page: totalPages)
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
