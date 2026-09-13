import 'package:flutter/material.dart';
import '../../../../../core/app_theme.dart';
import '../../models/cxc_alerta_model.dart';

class LedhouseAlertaProcesarDialog extends StatefulWidget {
  final CxcAlertaModel alerta;
  final Future<void> Function(
    bool actualizarCxc,
    double? montoPagado,
    String? estadoCxc,
  ) onProcesar;

  const LedhouseAlertaProcesarDialog({
    super.key,
    required this.alerta,
    required this.onProcesar,
  });

  @override
  State<LedhouseAlertaProcesarDialog> createState() =>
      _LedhouseAlertaProcesarDialogState();
}

class _LedhouseAlertaProcesarDialogState
    extends State<LedhouseAlertaProcesarDialog> {
  late TextEditingController _montoController;
  late String _estadoCxc;
  late bool _actualizarCxc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.alerta.montoInformado?.toString() ?? '',
    );
    _estadoCxc = 'pendiente';
    _actualizarCxc = widget.alerta.tipo == 'pago_recibido';
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.darkBorderColor),
      ),
      title: Row(
        children: [
          Icon(Icons.edit_rounded, color: Colors.blueAccent),
          const SizedBox(width: 10),
          const Text(
            'Procesar Alerta',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: Colors.grey.shade400,
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Actualizar CXC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'Aplicar cambios en la factura',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              value: _actualizarCxc,
              activeTrackColor: AppTheme.ledhouseBlue.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.ledhouseBlue,
              onChanged: (v) => setState(() => _actualizarCxc = v),
            ),
          ),
          if (_actualizarCxc) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monto pagado a registrar',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.attach_money, color: Colors.white),
                filled: true,
                fillColor: AppTheme.darkInputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.darkBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.darkBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.ledhouseBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _estadoCxc,
              dropdownColor: AppTheme.darkCardColor,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nuevo estado del CXC',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: AppTheme.darkInputColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.darkBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.darkBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.ledhouseBlue),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'pendiente',
                  child: Text('Pendiente'),
                ),
                DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
              ],
              onChanged: (v) => setState(() => _estadoCxc = v!),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final monto = _actualizarCxc && _montoController.text.isNotEmpty
                      ? double.tryParse(_montoController.text)
                      : null;
                  
                  await widget.onProcesar(
                    _actualizarCxc,
                    monto,
                    _actualizarCxc ? _estadoCxc : null,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ledhouseBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Procesar y Guardar'),
        ),
      ],
    );
  }
}
