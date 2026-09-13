import 'package:flutter/material.dart';
import 'package:industria_california/modules/logistica/providers/ruta_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth_provider.dart';
import '../models/pedido.dart';
import '../providers/pedido_provider.dart';
import 'pedido_detalle_dialog.dart';

class PedidosTable extends StatefulWidget {
  const PedidosTable({super.key});

  @override
  State<PedidosTable> createState() => _PedidosTableState();
}

class _PedidosTableState extends State<PedidosTable> {
  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final Set<int> _selectedIds = {};

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'borrador':
        return const Color(0xFFFF9800);
      case 'enviado':
        return const Color(0xFF2196F3);
      case 'facturado':
        return const Color(0xFF4CAF50);
      case 'cancelado':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  Future<void> _generarPdf(int id) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando Factura...')));
    try {
      final urlStr = await context.read<PedidoProvider>().getPdfUrl(id);
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

  void _goToDetalle(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => PedidoDetalleDialog(pedido: pedido),
    );
  }

  void _showProcesarDialog(Pedido pedido) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F33),
          title: const Text(
            'Procesar Pedido',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seleccione el nuevo estado para el pedido #${pedido.id}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _btnProcesar(
                      ctx,
                      pedido.id,
                      'borrador',
                      'Devolver a Borrador',
                      Icons.undo,
                    ),
                    _btnProcesar(
                      ctx,
                      pedido.id,
                      'facturado',
                      'Marcar Facturado',
                      Icons.check_circle,
                    ),
                    _btnProcesar(
                      ctx,
                      pedido.id,
                      'cancelado',
                      'Cancelar Pedido',
                      Icons.cancel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _btnProcesar(
    BuildContext ctx,
    int id,
    String estado,
    String label,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _getColorForEstado(estado).withValues(alpha: 0.2),
        foregroundColor: _getColorForEstado(estado),
        elevation: 0,
        side: BorderSide(color: _getColorForEstado(estado)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () async {
        Navigator.pop(ctx);
        final provider = context.read<PedidoProvider>();
        final success = await provider.changeStatus(id, estado);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estado cambiado a $estado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  void _confirmDelete(Pedido pedido) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F33),
          title: const Text(
            'Eliminar Pedido',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Estás seguro de eliminar el pedido #${pedido.id}? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<PedidoProvider>();
                final success = await provider.deletePedido(pedido.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${provider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAssignRouteDialog() {
    final rutas = context.read<RutaProvider>().rutas;
    int? selectedRuta;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2F33),
              title: const Text(
                'Asignar a Ruta',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seleccione la ruta para los ${_selectedIds.length} pedidos seleccionados:',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedRuta,
                    dropdownColor: const Color(0xFF2C2F33),
                    items: rutas
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              r.nombre,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedRuta = val);
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1E2124),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                  ),
                  onPressed: selectedRuta == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final provider = context.read<PedidoProvider>();
                          final success = await provider.assignRuta(
                            _selectedIds.toList(),
                            selectedRuta!,
                          );
                          if (success && mounted) {
                            setState(() => _selectedIds.clear());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pedidos asignados con éxito'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: const Text(
                    'Asignar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

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
        if (_selectedIds.isNotEmpty && isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFF2196F3).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedIds.length} pedidos seleccionados',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text(
                        'Asignar a Ruta',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: _showAssignRouteDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF2196F3).withOpacity(0.15);
                    }
                    return Colors.transparent;
                  }),
                  dividerThickness: 0.5,
                  onSelectAll: isAdmin
                      ? (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.addAll(
                                provider.pedidos.map((e) => e.id),
                              );
                            } else {
                              _selectedIds.clear();
                            }
                          });
                        }
                      : null,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'ID',
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
                        'Total',
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
                  rows: provider.pedidos.map((pedido) {
                    final colorEstado = _getColorForEstado(pedido.estado);
                    return DataRow(
                      selected: _selectedIds.contains(pedido.id),
                      onSelectChanged: isAdmin
                          ? (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(pedido.id);
                                } else {
                                  _selectedIds.remove(pedido.id);
                                }
                              });
                            }
                          : null,
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
                          Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(pedido.createdAt ?? DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            pedido.clienteNombre ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
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
                              color: colorEstado.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorEstado.withOpacity(0.5),
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
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                tooltip: 'Ver Detalles',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _goToDetalle(pedido),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                tooltip: 'Ver Factura',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _generarPdf(pedido.id),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_note,
                                  color: Colors.blueAccent,
                                  size: 18,
                                ),
                                tooltip: 'Procesar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showProcesarDialog(pedido),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  tooltip: 'Eliminar',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDelete(pedido),
                                ),
                              ],
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
        _buildPagination(provider),
      ],
    );
  }

  Widget _buildPagination(PedidoProvider provider) {
    if (provider.lastPage <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF23272A),
        border: Border(top: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
