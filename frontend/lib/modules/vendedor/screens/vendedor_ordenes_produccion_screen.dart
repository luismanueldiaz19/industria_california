import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../produccion/models/orden_produccion.dart';
import '../../produccion/providers/orden_produccion_provider.dart';

class VendedorOrdenesProduccionScreen extends StatefulWidget {
  const VendedorOrdenesProduccionScreen({super.key});

  @override
  State<VendedorOrdenesProduccionScreen> createState() =>
      _VendedorOrdenesProduccionScreenState();
}

class _VendedorOrdenesProduccionScreenState
    extends State<VendedorOrdenesProduccionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<OrdenProduccionProvider>().fetchOrdenes(
        refresh: true,
        vendedorId: authProvider.id,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final authProvider = context.read<AuthProvider>();
        context.read<OrdenProduccionProvider>().fetchOrdenes(
          vendedorId: authProvider.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Órdenes en Producción',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E2F4C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<OrdenProduccionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.ordenes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.ordenes.isEmpty) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final misOrdenes = provider.ordenes;

          if (misOrdenes.isEmpty) {
            return const Center(
              child: Text('No has enviado órdenes a producción.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              await provider.fetchOrdenes(
                refresh: true,
                vendedorId: authProvider.id,
              );
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: misOrdenes.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == misOrdenes.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final orden = misOrdenes[index];
                return _buildOrdenCard(orden);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdenCard(OrdenProduccion orden) {
    final format = DateFormat('dd MMM yyyy');
    final fecha = orden.fechaEstimadaEntrega != null
        ? format.format(orden.fechaEstimadaEntrega!)
        : 'Sin fecha';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Cliente: ${orden.cliente?.nombre ?? 'Desconocido'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getColorPorEstado(orden.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getColorPorEstado(orden.estado)),
                  ),
                  child: Text(
                    orden.estado.toUpperCase(),
                    style: TextStyle(
                      color: _getColorPorEstado(orden.estado),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Orden/Pedido #${orden.pedidoId ?? orden.id}',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Entrega: $fecha',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'produccion':
      case 'en produccion':
        return Colors.orange;
      case 'lista':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
