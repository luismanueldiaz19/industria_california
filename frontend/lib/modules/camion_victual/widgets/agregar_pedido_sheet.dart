import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import '../models/camion_victual.dart';
import '../providers/camion_victual_provider.dart';

/// Bottom sheet para buscar y seleccionar pedidos facturados disponibles
/// y agregarlos al camión desde el UI del Vendedor.
class AgregarPedidoSheet extends StatefulWidget {
  final int camionId;
  final CamionVictual? camion;

  const AgregarPedidoSheet({
    super.key,
    required this.camionId,
    this.camion,
  });

  @override
  State<AgregarPedidoSheet> createState() => _AgregarPedidoSheetState();
}

class _AgregarPedidoSheetState extends State<AgregarPedidoSheet> {
  final _searchCtrl = TextEditingController();
  int? _addingPedidoId;

  CamionVictual? get _camion {
    if (widget.camion != null) return widget.camion;
    try {
      return context.read<CamionVictualProvider>().camiones.firstWhere(
            (c) => c.id == widget.camionId,
          );
    } catch (_) {
      return null;
    }
  }

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
          search: query.trim(),
        );
  }

  Future<void> _agregar(PedidoDisponible pedido) async {
    setState(() => _addingPedidoId = pedido.id);
    final provider = context.read<CamionVictualProvider>();
    final ok = await provider.agregarPedido(widget.camionId, pedido.id);
    if (!mounted) return;
    setState(() => _addingPedidoId = null);

    if (ok) {
      final nombreCamion = _camion?.nombre ?? 'camión';
      CompactSnackBar.showSuccess(
        context,
        'Pedido #${pedido.id} agregado al $nombreCamion',
      );
    } else {
      CompactSnackBar.showError(
        context,
        provider.error ?? 'Error al agregar pedido',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final camion = _camion;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.8).clamp(450.0, 680.0);

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle superior para arrastre
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cargar Pedidos Facturados',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Destino: ${camion?.nombre ?? 'Camión #${widget.camionId}'} · Chofer: ${camion?.choferNombre ?? 'Sin asignar'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _buscar,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, dirección o número...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _buscar('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),

          // Lista de pedidos disponibles
          Expanded(
            child: Consumer<CamionVictualProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingPedidos) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE31E24),
                    ),
                  );
                }

                final pedidos = provider.pedidosDisponibles;

                if (pedidos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 44,
                            color: Color(0xFFCBD5E1),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No hay pedidos facturados disponibles',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Los pedidos deben estar en estado FACTURADO y no estar asignados a otro camión.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: pedidos.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final isAdding = _addingPedidoId == pedido.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila superior: Ícono y Datos del Cliente/Pedido
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.receipt_outlined,
                                  color: Color(0xFF16A34A),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nombre Cliente y Badge Factura
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pedido.clienteNombre ?? 'Cliente #${pedido.clienteId}',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (pedido.numFactura != null &&
                                            pedido.numFactura!.trim().isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFFBFDBFE),
                                              ),
                                            ),
                                            child: Text(
                                              'Fac: ${pedido.numFactura}',
                                              style: const TextStyle(
                                                color: Color(0xFF1D4ED8),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    // Pedido # y Fecha
                                    Row(
                                      children: [
                                        Text(
                                          'Pedido #${pedido.id}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '· ${pedido.createdAt.day.toString().padLeft(2, '0')}/${pedido.createdAt.month.toString().padLeft(2, '0')}/${pedido.createdAt.year}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Dirección (si existe)
                                    if (pedido.clienteDireccion != null &&
                                        pedido.clienteDireccion!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              pedido.clienteDireccion!.trim(),
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          const SizedBox(height: 8),

                          // Fila inferior: Monto y Botón Cargar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Total: ',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(pedido.total),
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                                child: ElevatedButton.icon(
                                  onPressed: isAdding ? null : () => _agregar(pedido),
                                  icon: isAdding
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.add, size: 14),
                                  label: const Text(
                                    'Cargar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    visualDensity: VisualDensity.compact,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<CamionVictualProvider>(
                  builder: (context, prov, child) => Text(
                    '${prov.pedidosDisponibles.length} pedidos facturados disponibles',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E8F0),
                    foregroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Listo / Cerrar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
