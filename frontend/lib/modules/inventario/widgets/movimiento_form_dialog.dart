import 'package:flutter/material.dart';
import '../models/inventario_movimiento.dart';
import '../models/inventario_producto.dart';
import '../providers/inventario_movimiento_provider.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/auth_submit_button.dart';

class MovimientoFormDialog extends StatefulWidget {
  final InventarioProducto producto;
  final InventarioMovimientoProvider movimientoProvider;

  const MovimientoFormDialog({
    super.key,
    required this.producto,
    required this.movimientoProvider,
  });

  @override
  State<MovimientoFormDialog> createState() => _MovimientoFormDialogState();
}

class _MovimientoFormDialogState extends State<MovimientoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();

  String _tipo = 'AJUSTE';
  String? _subtipo;
  bool _isLoading = false;
  String? _error;

  static const _accentRed = Color(0xFFE31E24);
  static const _dark = Color(0xFF1A1C1E);
  static const _card = Color(0xFF2C2F33);

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  double get _cantidadPreview {
    final cantidad = double.tryParse(_cantidadCtrl.text) ?? 0;
    // Para VENTA y BAJA la cantidad es negativa
    if (_tipo == 'VENTA' || _tipo == 'BAJA') {
      return -cantidad.abs();
    }
    return cantidad;
  }

  double get _stockResultante => widget.producto.stock + _cantidadPreview;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    final movimiento = InventarioMovimiento(
      productoId: widget.producto.id!,
      tipo: _tipo,
      subtipo: _tipo == 'BAJA' ? _subtipo : null,
      cantidad: _cantidadPreview,
      stockAnterior: widget.producto.stock,
      stockResultante: _stockResultante,
      nota: _notaCtrl.text.trim().isNotEmpty ? _notaCtrl.text.trim() : null,
    );

    final success = await widget.movimientoProvider.registrarMovimiento(movimiento);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = widget.movimientoProvider.error ?? 'Error desconocido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _card.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, color: _accentRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registrar Movimiento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.producto.nombre,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_error != null) _errorBanner(),

                    // Stock actual info
                    _stockPreviewCard(),
                    const SizedBox(height: 14),

                    // Tipo de movimiento
                    _tipoSelector(),
                    const SizedBox(height: 10),

                    // Subtipo (solo para BAJA)
                    if (_tipo == 'BAJA') ...[
                      _subtipoSelector(),
                      const SizedBox(height: 10),
                    ],

                    // Cantidad
                    AuthTextField(
                      controller: _cantidadCtrl,
                      hintText: 'Cantidad',
                      prefixIcon: Icons.tag,
                      keyboardType: TextInputType.number,
                      accentColor: _accentRed,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Ingrese un número positivo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Nota
                    AuthTextField(
                      controller: _notaCtrl,
                      hintText: 'Nota u observación (opcional)',
                      prefixIcon: Icons.notes,
                      accentColor: _accentRed,
                    ),
                    const SizedBox(height: 14),

                    // Submit
                    AuthSubmitButton(
                      text: 'REGISTRAR MOVIMIENTO',
                      isLoading: _isLoading,
                      onPressed: _submit,
                      backgroundColor: _accentRed,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11.5)),
    );
  }

  Widget _stockPreviewCard() {
    final resultante = _stockResultante;
    final color = resultante < 0
        ? const Color(0xFFE31E24)
        : resultante == 0
            ? Colors.orange
            : const Color(0xFF34A853);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _stockInfo(
            'Stock actual',
            widget.producto.stock.toStringAsFixed(2),
            Colors.white70,
          ),
          const Icon(Icons.arrow_forward, color: Colors.white24, size: 16),
          _stockInfo(
            'Resultante',
            resultante.toStringAsFixed(2),
            color,
          ),
          const Spacer(),
          Text(
            widget.producto.unidad,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _stockInfo(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _tipoSelector() {
    final tipos = [
      ('AJUSTE', Icons.tune_rounded, const Color(0xFF1A73E8)),
      ('PRODUCCION', Icons.factory_outlined, const Color(0xFF34A853)),
      ('VENTA', Icons.point_of_sale_outlined, const Color(0xFFE31E24)),
      ('BAJA', Icons.delete_sweep_outlined, Colors.orange),
    ];

    return Row(
      children: tipos.map((t) {
        final isSelected = _tipo == t.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() {
                _tipo = t.$1;
                _subtipo = null;
              }),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? t.$3.withValues(alpha: 0.18) : _card.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? t.$3 : Colors.white.withValues(alpha: 0.06),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(t.$2, color: isSelected ? t.$3 : Colors.white38, size: 18),
                    const SizedBox(height: 3),
                    Text(
                      t.$1,
                      style: TextStyle(
                        color: isSelected ? t.$3 : Colors.white38,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _subtipoSelector() {
    final subtipos = ['MALO', 'PERDIDO', 'DAÑADO'];
    return Row(
      children: subtipos.map((s) {
        final isSelected = _subtipo == s;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _subtipo = s),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.withValues(alpha: 0.15) : _card.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
