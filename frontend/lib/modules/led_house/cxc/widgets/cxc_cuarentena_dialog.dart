import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/widgets/compact_snack_bar.dart';
import '../models/cxc_model.dart';
import '../services/cxc_cuarentena_service.dart';

class CxcCuarentenaDialog extends StatefulWidget {
  final CxcModel cxc;

  const CxcCuarentenaDialog({super.key, required this.cxc});

  @override
  State<CxcCuarentenaDialog> createState() => _CxcCuarentenaDialogState();
}

class _CxcCuarentenaDialogState extends State<CxcCuarentenaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = CxcCuarentenaService();

  late TextEditingController _montoController;
  late TextEditingController _justificacionController;

  String _tipoNota = 'credito';
  String _motivo = 'devolucion';
  bool _isLoading = false;

  final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  final List<Map<String, String>> _motivos = [
    {'value': 'devolucion', 'label': 'Devolución de mercancía'},
    {'value': 'descuento', 'label': 'Descuento especial concedido'},
    {'value': 'diferencia_precio', 'label': 'Diferencia en precio / cobro'},
    {'value': 'error_facturacion', 'label': 'Error de facturación'},
    {'value': 'otro', 'label': 'Otro motivo'},
  ];

  @override
  void initState() {
    super.initState();
    final defaultMonto = widget.cxc.montoPendiente > 0
        ? widget.cxc.montoPendiente
        : widget.cxc.montoFactura;
    _montoController = TextEditingController(
      text: defaultMonto.toStringAsFixed(2),
    );
    _justificacionController = TextEditingController();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _justificacionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedMonto = double.tryParse(_montoController.text.replaceAll(',', ''));
    if (parsedMonto == null || parsedMonto <= 0) {
      CompactSnackBar.showError(context, 'El monto debe ser un valor válido mayor a 0');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.enviarACuarentena(
        widget.cxc.id!,
        tipoNota: _tipoNota,
        montoNota: parsedMonto,
        motivo: _motivo,
        justificacion: _justificacionController.text.trim(),
      );

      if (mounted) {
        CompactSnackBar.showSuccess(
          context,
          'Factura ${widget.cxc.documento} movida a cuarentena correctamente',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(
          context,
          'Error al enviar a cuarentena: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enviar a Cuarentena (Nota Pendiente)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Documento: ${widget.cxc.documento}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Aviso de limpieza
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.lightBlueAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Al confirmar, esta factura se quitará de CXC para limpiar el estado de cuenta y quedará registrada en cuarentena como nota a procesar en el sistema externo.',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Resumen de la factura
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2228),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Cliente', widget.cxc.cliente),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        'Vendedor',
                        widget.cxc.vendedorNombre ?? 'No asignado',
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMontoMini(
                            'Facturado',
                            currencyFormatter.format(widget.cxc.montoFactura),
                            Colors.grey.shade300,
                          ),
                          _buildMontoMini(
                            'Pagado',
                            currencyFormatter.format(widget.cxc.montoPagado),
                            AppTheme.successColor,
                          ),
                          _buildMontoMini(
                            'Pendiente',
                            currencyFormatter.format(widget.cxc.montoPendiente),
                            const Color(0xFFFB8C00),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tipo de Nota
                const Text(
                  'Tipo de Nota en sistema externo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildTipoSelector(
                        title: 'Nota de Crédito',
                        value: 'credito',
                        icon: Icons.receipt_long_rounded,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTipoSelector(
                        title: 'Nota de Débito',
                        value: 'debito',
                        icon: Icons.note_add_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Monto de la nota
                const Text(
                  'Monto de la Nota (\$)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFF1E2228),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.ledhouseBlue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Requerido';
                    }
                    final val = double.tryParse(value.replaceAll(',', ''));
                    if (val == null || val <= 0) {
                      return 'Debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Motivo
                const Text(
                  'Motivo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _motivo,
                  isDense: true,
                  dropdownColor: AppTheme.darkCardColor,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFF1E2228),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                  items: _motivos.map((m) {
                    return DropdownMenuItem<String>(
                      value: m['value'],
                      child: Text(m['label']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _motivo = val);
                  },
                ),
                const SizedBox(height: 12),

                // Justificación obligatoria
                const Text(
                  'Justificación detallada (obligatoria)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _justificacionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Explique por qué se manda a cuarentena y qué debe aplicarse en el otro sistema...',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                    filled: true,
                    fillColor: const Color(0xFF1E2228),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.ledhouseBlue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La justificación es obligatoria';
                    }
                    if (value.trim().length < 10) {
                      return 'Escriba al menos 10 caracteres explicativos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        _isLoading ? 'Procesando...' : 'Confirmar Cuarentena',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMontoMini(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTipoSelector({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _tipoNota == value;
    return InkWell(
      onTap: () => setState(() => _tipoNota = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF1E2228),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade800,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
