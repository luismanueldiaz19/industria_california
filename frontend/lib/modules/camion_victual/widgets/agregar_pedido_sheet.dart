import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../vendedor/widgets/vendedor_mobile_wrapper.dart';
import '../models/camion_victual.dart';
import '../providers/camion_victual_provider.dart';

/// Bottom sheet para buscar y seleccionar pedidos facturados disponibles
/// y agregarlos al camión.
class AgregarPedidoSheet extends StatefulWidget {
  final int camionId;
  const AgregarPedidoSheet({super.key, required this.camionId});

  @override
  State<AgregarPedidoSheet> createState() => _AgregarPedidoSheetState();
}

class _AgregarPedidoSheetState extends State<AgregarPedidoSheet> {
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat('#,##0.00', 'es');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CamionVictualProvider>().fetchPedidosDisponibles();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _buscar(String query) {
    context.read<CamionVictualProvider>().fetchPedidosDisponibles(
      search: query,
    );
  }

  Future<void> _agregar(PedidoDisponible pedido) async {
    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.agregarPedido(widget.camionId, pedido.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #${pedido.id} agregado al camión'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al agregar pedido'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.add_shopping_cart, color: Color(0xFF1976D2)),
                SizedBox(width: 10),
                Text(
                  'Agregar Pedido al Camión',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _buscar,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente...',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lista de pedidos disponibles
          SizedBox(
            height: 340,
            child: Consumer<CamionVictualProvider>(
              builder: (_, provider, __) {
                if (provider.isLoadingPedidos) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                  );
                }
                if (provider.isActualizando) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF4CAF50)),
                        SizedBox(height: 12),
                        Text(
                          'Agregando...',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }
                final pedidos = provider.pedidosDisponibles;
                if (pedidos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: Colors.black12,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No hay pedidos facturados disponibles',
                          style: TextStyle(color: Colors.black38),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: pedidos.length,
                  itemBuilder: (_, i) {
                    final p = pedidos[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        p.clienteNombre ?? 'Cliente #${p.clienteId}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Pedido #${p.id} · ${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${_fmt.format(p.total)}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _agregar(p),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1976D2,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF1976D2),
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF1976D2),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
