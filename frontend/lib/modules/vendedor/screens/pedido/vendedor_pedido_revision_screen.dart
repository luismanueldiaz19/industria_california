import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/pedido_form_provider.dart';
import '../../../logistica/providers/pedido_provider.dart';

class VendedorPedidoRevisionScreen extends StatefulWidget {
  final VoidCallback onPrev;

  const VendedorPedidoRevisionScreen({super.key, required this.onPrev});

  @override
  State<VendedorPedidoRevisionScreen> createState() =>
      _VendedorPedidoRevisionScreenState();
}

class _VendedorPedidoRevisionScreenState
    extends State<VendedorPedidoRevisionScreen> {
  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);
  static final _currencyFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  String _estadoSeleccionado = 'borrador';
  bool _isSaving = false;

  final Map<String, Map<String, dynamic>> _estadosConfig = {
    'borrador': {
      'label': 'Guardar como Borrador',
      'color': const Color(0xFFFF9800),
      'icon': Icons.save_outlined,
    },
    'enviado': {
      'label': 'Enviar a Logística',
      'color': const Color(0xFF2196F3),
      'icon': Icons.send,
    },
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda: Factura
                      Expanded(flex: 3, child: _buildFactura(provider)),
                      const SizedBox(width: 32),
                      // Columna Derecha: Acciones
                      Expanded(flex: 2, child: _buildAcciones(provider)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Superior: Factura
                      _buildFactura(provider),
                      const SizedBox(height: 32),
                      // Inferior: Acciones
                      _buildAcciones(provider),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Factura
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESUMEN DE PEDIDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.cliente?.nombre ?? "N/A",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      if (provider.ruta != null)
                        Text(
                          'Ruta: ${provider.ruta!.nombre}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.receipt_long,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 8,
                      horizontalMargin: 4,
                      headingRowHeight: 28,
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 48,
                      columns: [
                        DataColumn(
                          label: Text(
                            'Producto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text(
                            'Cant.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text(
                            'Precio',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                      rows: provider.carrito.map((item) {
                        final cant =
                            double.tryParse(item.cantidadController.text) ?? 0;
                        final precio =
                            double.tryParse(item.precioController.text) ?? 0;
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productoNombre,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.productoCodigo,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                cant % 1 == 0
                                    ? cant.toInt().toString()
                                    : cant.toStringAsFixed(3),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                _currencyFmt.format(precio),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _currencyFmt.format(item.subtotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const Divider(height: 24),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currencyFmt.format(provider.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _accentBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (provider.comentario.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notas / Comentarios',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.comentario,
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 11,
                          ),
                        ),
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
        const Text(
          'Finalizar Pedido',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _primaryBlue,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Selecciona qué deseas hacer con este pedido:',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 12),

        ..._estadosConfig.entries.map((e) {
          final isSelected = _estadoSeleccionado == e.key;
          final color = e.value['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _estadoSeleccionado = e.key),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      e.value['icon'] as IconData,
                      size: 16,
                      color: isSelected ? color : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, size: 16, color: color),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _confirmarPedido(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _estadosConfig[_estadoSeleccionado]!['color'] as Color,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Confirmar y Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _isSaving ? null : widget.onPrev,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Atrás (Catálogo)', style: TextStyle(fontSize: 12)),
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
        ok = await pedidoProvider.updatePedido(
          formProvider.originalId!,
          payload,
        );
      } else {
        ok = await pedidoProvider.createPedido(payload);
      }

      setState(() => _isSaving = false);
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _estadoSeleccionado == 'enviado'
                  ? 'Pedido enviado a logística'
                  : 'Borrador guardado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pedidoProvider.error ?? 'Error desconocido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
