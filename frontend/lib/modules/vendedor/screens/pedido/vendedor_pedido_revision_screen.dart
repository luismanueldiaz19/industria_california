import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/pedido_form_provider.dart';
import '../../../../services/http_service.dart';
import '../../../logistica/providers/pedido_provider.dart';

class VendedorPedidoRevisionScreen extends StatefulWidget {
  final VoidCallback onPrev;

  const VendedorPedidoRevisionScreen({super.key, required this.onPrev});

  @override
  State<VendedorPedidoRevisionScreen> createState() => _VendedorPedidoRevisionScreenState();
}

class _VendedorPedidoRevisionScreenState extends State<VendedorPedidoRevisionScreen> {
  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);
  static final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  String _estadoSeleccionado = 'borrador';
  bool _isSaving = false;

  final Map<String, Map<String, dynamic>> _estadosConfig = {
    'borrador': {'label': 'Guardar como Borrador', 'color': const Color(0xFFFF9800), 'icon': Icons.save_outlined},
    'enviado': {'label': 'Enviar a Logística', 'color': const Color(0xFF2196F3), 'icon': Icons.send},
  };

  @override
  void initState() {
    super.initState();
    // Si estamos editando y el estado era otro (ej. facturado/cancelado, que usualmente el vendedor no setea pero podría ver),
    // podríamos ajustarlo. Por ahora, asumimos que el vendedor crea/edita como Borrador o Enviado.
    final provider = context.read<PedidoFormProvider>();
    // default to borrador unless editing and it was already enviado
    if (provider.isEditing && _estadosConfig.containsKey('enviado')) {
      // Simplificado: por defecto borrador.
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoFormProvider>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna Izquierda: Factura
                Expanded(
                  flex: 3,
                  child: _buildFactura(provider),
                ),
                const SizedBox(width: 32),
                // Columna Derecha: Acciones
                Expanded(
                  flex: 2,
                  child: _buildAcciones(provider),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildFactura(PedidoFormProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Factura
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RESUMEN DE PEDIDO', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text('Cliente: ${provider.cliente?.nombre ?? "N/A"}', style: const TextStyle(color: Colors.white70)),
                    if (provider.ruta != null) Text('Ruta: ${provider.ruta!.nombre}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                Icon(Icons.receipt_long, size: 48, color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),
          ),
          
          // Items
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Tabla header
                Row(
                  children: [
                    Expanded(flex: 3, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                    Expanded(flex: 1, child: Text('Cant.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                    Expanded(flex: 1, child: Text('Precio', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                    Expanded(flex: 1, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                  ],
                ),
                const Divider(height: 24),
                
                // Rows
                ...provider.carrito.map((item) {
                  final cant = double.tryParse(item.cantidadController.text) ?? 0;
                  final precio = double.tryParse(item.precioController.text) ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productoNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(item.productoCodigo, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(cant % 1 == 0 ? cant.toInt().toString() : cant.toStringAsFixed(3), textAlign: TextAlign.center),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(_currencyFmt.format(precio), textAlign: TextAlign.right, style: TextStyle(color: Colors.grey.shade700)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(_currencyFmt.format(item.subtotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }),
                
                const Divider(height: 32),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBlue)),
                    const SizedBox(width: 24),
                    Text(_currencyFmt.format(provider.total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _accentBlue)),
                  ],
                ),
              ],
            ),
          ),
          
          if (provider.comentario.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 20, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notas / Comentarios', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        const SizedBox(height: 4),
                        Text(provider.comentario, style: TextStyle(color: Colors.amber.shade900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcciones(PedidoFormProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Finalizar Pedido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryBlue)),
        const SizedBox(height: 8),
        const Text('Selecciona qué deseas hacer con este pedido:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        
        ..._estadosConfig.entries.map((e) {
          final isSelected = _estadoSeleccionado == e.key;
          final color = e.value['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _estadoSeleccionado = e.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(e.value['icon'] as IconData, color: isSelected ? color : Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        e.value['label'] as String,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87),
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: color),
                  ],
                ),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _confirmarPedido(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _estadosConfig[_estadoSeleccionado]!['color'] as Color,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirmar y Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _isSaving ? null : widget.onPrev,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Atrás (Catálogo)'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarPedido(PedidoFormProvider formProvider) async {
    setState(() => _isSaving = true);

    try {
      final payload = formProvider.buildPayload(_estadoSeleccionado);
      final pedidoProvider = context.read<PedidoProvider>();
      
      bool ok;
      if (formProvider.isEditing && formProvider.originalId != null) {
        ok = await pedidoProvider.updatePedido(formProvider.originalId!, payload);
      } else {
        ok = await pedidoProvider.createPedido(payload);
      }
      
      setState(() => _isSaving = false);
      if (!mounted) return;
      
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_estadoSeleccionado == 'enviado' ? 'Pedido enviado a logística' : 'Borrador guardado exitosamente'),
            backgroundColor: Colors.green,
          )
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pedidoProvider.error ?? 'Error desconocido'), backgroundColor: Colors.red));
      }

      
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
