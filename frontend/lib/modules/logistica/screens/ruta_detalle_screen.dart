import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/ruta.dart';
import '../models/pedido.dart';
import '../providers/pedido_provider.dart';
import '../services/pedido_service.dart';

class RutaDetalleScreen extends StatefulWidget {
  final Ruta ruta;
  const RutaDetalleScreen({super.key, required this.ruta});

  @override
  State<RutaDetalleScreen> createState() => _RutaDetalleScreenState();
}

class _RutaDetalleScreenState extends State<RutaDetalleScreen> {
  final PedidoService _pedidoService = PedidoService();
  bool _isLoading = true;
  bool _isOptimizing = false;
  List<Pedido> _pedidos = [];
  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    setState(() => _isLoading = true);
    try {
      final result = await _pedidoService.getPedidos(
        rutaId: widget.ruta.id,
        // Eliminado filtro por estado, para mostrar todos los despachados.
        page: 1,
      );
      if (mounted) {
        setState(() {
          _pedidos = result['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _optimizarRuta() async {
    // Coordenadas base (ej: Almacén de Industria California en Santiago)
    final double originLat = 19.4517;
    final double originLng = -70.6970;

    setState(() => _isOptimizing = true);
    try {
      final optimizados = await _pedidoService.optimizeRoute(widget.ruta.id, originLat, originLng);
      if (mounted) {
        setState(() {
          _pedidos = optimizados;
          _isOptimizing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta optimizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOptimizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al optimizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2124),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F33),
        title: Text('Detalle de Ruta: ${widget.ruta.nombre}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pedidos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                icon: _isOptimizing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.route, size: 16),
                label: const Text('Optimizar Orden', style: TextStyle(fontSize: 12)),
                onPressed: _isOptimizing ? null : _optimizarRuta,
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
          : _pedidos.isEmpty
              ? const Center(
                  child: Text('No hay pedidos asignados a esta ruta.', style: TextStyle(color: Colors.white54, fontSize: 14)),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pedidos.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _pedidos.removeAt(oldIndex);
                      _pedidos.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final pedido = _pedidos[index];
                    return Card(
                      key: ValueKey(pedido.id),
                      color: const Color(0xFF2C2F33),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
                          child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(pedido.clienteNombre ?? 'Cliente Desconocido', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Pedido #${pedido.id} • ${_currencyFmt.format(pedido.total)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('Vendedor: ${pedido.vendedorNombre}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        trailing: const Icon(Icons.drag_handle, color: Colors.white38),
                      ),
                    );
                  },
                ),
    );
  }
}
