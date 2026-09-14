import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/orden_produccion_provider.dart';

class AdminOrdenesProduccionScreen extends StatefulWidget {
  const AdminOrdenesProduccionScreen({super.key});

  @override
  State<AdminOrdenesProduccionScreen> createState() =>
      _AdminOrdenesProduccionScreenState();
}

class _AdminOrdenesProduccionScreenState
    extends State<AdminOrdenesProduccionScreen> {
  static const _primaryBlue = Color(0xFF1E3A5F);

  final ScrollController _scrollController = ScrollController();
  String _estadoFiltro = 'pendiente';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrdenProduccionProvider>();
      provider.setEstadoFiltro(_estadoFiltro);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<OrdenProduccionProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.fetchOrdenes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Órdenes de Producción'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryBlue,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _estadoFiltro.isEmpty ? null : _estadoFiltro,
            hint: const Text('Todos'),
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos')),
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'en_proceso', child: Text('En Proceso')),
              DropdownMenuItem(value: 'lista', child: Text('Lista')),
            ],
            onChanged: (val) {
              setState(() {
                _estadoFiltro = val ?? '';
              });
              context.read<OrdenProduccionProvider>().setEstadoFiltro(
                _estadoFiltro,
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: _primaryBlue,
            onPressed: () => context
                .read<OrdenProduccionProvider>()
                .fetchOrdenes(refresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return Consumer<OrdenProduccionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.ordenes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.ordenes.isEmpty) {
          return const Center(
            child: Text(
              'No hay órdenes de producción con los filtros actuales.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchOrdenes(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.ordenes.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.ordenes.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final orden = provider.ordenes[index];
              return _buildOrdenCard(orden, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrdenCard(orden, OrdenProduccionProvider provider) {
    Color estadoColor;
    switch (orden.estado) {
      case 'pendiente':
        estadoColor = Colors.orange;
        break;
      case 'en_proceso':
        estadoColor = Colors.blue;
        break;
      case 'lista':
        estadoColor = Colors.green;
        break;
      default:
        estadoColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OP-#${orden.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: estadoColor),
                  ),
                  child: Text(
                    orden.estado.toUpperCase(),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${orden.cliente?.nombre ?? "Desconocido"}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Vendedor: ${orden.vendedor?.name ?? "Desconocido"}'),
            Text(
              'Fecha Estimada: ${orden.fechaEstimadaEntrega != null ? DateFormat('dd/MM/yyyy').format(orden.fechaEstimadaEntrega!) : "No definida"}',
            ),
            if (orden.pedidoId != null)
              Text(
                'Pedido Asociado: #${orden.pedidoId}',
                style: const TextStyle(color: Colors.blue),
              ),
            if (orden.notas != null && orden.notas!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Notas: ${orden.notas}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            const Divider(height: 24),
            const Text(
              'Detalles de Producción:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...orden.detalles.map((det) => _buildDetalleRow(det, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(detalle, OrdenProduccionProvider provider) {
    final isListo = detalle.estado == 'listo';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isListo ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isListo ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.producto?.nombre ?? 'Producto Desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Cantidad a Producir: ${detalle.cantidadFaltante}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isListo)
            ElevatedButton.icon(
              onPressed: () => _marcarListo(detalle.id, provider),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Marcar Listo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Future<void> _marcarListo(
    int detalleId,
    OrdenProduccionProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text(
          '¿Marcar este producto como producido y listo para enviar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await provider.marcarDetalleListo(detalleId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto marcado como listo.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
