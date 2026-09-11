import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';

/// Tarjeta editable de un ítem en el carrito.
/// Responsabilidad única: mostrar y editar un CartItem.
class PedidoCartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onChanged; // notifica al padre que reconstruya el total

  static const _primaryBlue = Color(0xFF1E3A5F);
  static const _accentBlue = Color(0xFF1976D2);
  static final _currencyFmt =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  const PedidoCartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _accentBlue.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productoNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _primaryBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.productoCodigo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            _currencyFmt.format(item.subtotal),
            style: const TextStyle(
              color: _accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildFieldCantidad(),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: _buildFieldPrecio(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCantidad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad (${item.unidad})',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: item.cantidadController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
          ],
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 14),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _buildFieldPrecio(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Precio unit.',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  'Base: ${_currencyFmt.format(item.precioBase)}\n'
                  'Rango: ${_currencyFmt.format(item.minPrecio)} – '
                  '${_currencyFmt.format(item.maxPrecio)}',
              child: Icon(Icons.info_outline,
                  size: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: item.precioController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 14),
          validator: (_) {
            if (!item.precioEsValido) return '±20% máx';
            return null;
          },
          decoration: _inputDecoration(prefix: '\$ ', errorStyle: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? prefix, TextStyle? errorStyle}) {
    return InputDecoration(
      prefixText: prefix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accentBlue),
      ),
      errorStyle: errorStyle,
    );
  }
}
