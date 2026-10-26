import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:industria_california/core/themes/app_theme.dart';
import 'package:industria_california/core/utils/alerta_utils.dart';
import 'package:industria_california/core/utils/formatters.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/vendedor_cxc_service.dart';

class VendedorPagoAgrupadoDialog extends StatefulWidget {
  final List<Map<String, dynamic>> facturasSeleccionadas;
  final VoidCallback onSuccess;

  const VendedorPagoAgrupadoDialog({
    super.key,
    required this.facturasSeleccionadas,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> facturas,
    required VoidCallback onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VendedorPagoAgrupadoDialog(
        facturasSeleccionadas: facturas,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<VendedorPagoAgrupadoDialog> createState() =>
      _VendedorPagoAgrupadoDialogState();
}

class _VendedorPagoAgrupadoDialogState
    extends State<VendedorPagoAgrupadoDialog> {
  final _service = VendedorCxcService();
  final _imagePicker = ImagePicker();

  String _tipoAlerta = 'pago_recibido';
  String? _formaPago;
  final _notaController = TextEditingController();
  final _montoTotalController = TextEditingController();

  // Controladores de monto por cada factura seleccionada
  final Map<int, TextEditingController> _itemControllers = {};

  Uint8List? _archivoBytes;
  String? _archivoNombre;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Calcular suma total de montos pendientes de las facturas seleccionadas
    double sumaPendiente = 0;
    for (var f in widget.facturasSeleccionadas) {
      final id = int.tryParse(f['id']?.toString() ?? '0') ?? 0;
      final pend = double.tryParse(f['monto_pendiente']?.toString() ?? '0') ?? 0;
      sumaPendiente += pend;
      _itemControllers[id] = TextEditingController(
        text: pend.toStringAsFixed(2),
      );
    }
    _montoTotalController.text = sumaPendiente.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _notaController.dispose();
    _montoTotalController.dispose();
    for (var c in _itemControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Distribuye el monto total ingresado entre las facturas seleccionadas
  /// comenzando por la más antigua (o en el orden de la lista) hasta agotarlo.
  void _distribuirAutomaticamente() {
    final cleanTotal =
        _montoTotalController.text.trim().replaceAll(',', '');
    double restante = double.tryParse(cleanTotal) ?? 0;

    if (restante <= 0) return;

    setState(() {
      for (var f in widget.facturasSeleccionadas) {
        final id = int.tryParse(f['id']?.toString() ?? '0') ?? 0;
        final pend =
            double.tryParse(f['monto_pendiente']?.toString() ?? '0') ?? 0;
        final c = _itemControllers[id];
        if (c == null) continue;

        if (restante <= 0) {
          c.text = '0.00';
        } else if (restante >= pend) {
          c.text = pend.toStringAsFixed(2);
          restante -= pend;
        } else {
          c.text = restante.toStringAsFixed(2);
          restante = 0;
        }
      }
    });
  }

  double _getSumaRepartida() {
    double suma = 0;
    for (var c in _itemControllers.values) {
      final val = double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;
      suma += val;
    }
    return suma;
  }

  Future<void> _pickCamara() async {
    final img = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _archivoBytes = bytes;
        _archivoNombre = img.name;
      });
    }
  }

  Future<void> _pickGaleria() async {
    final img = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _archivoBytes = bytes;
        _archivoNombre = img.name;
      });
    }
  }

  Future<void> _pickArchivo() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _archivoBytes = bytes;
        _archivoNombre = file.name;
      });
    }
  }

  Future<void> _enviar() async {
    final total =
        double.tryParse(_montoTotalController.text.trim().replaceAll(',', '')) ??
            0;
    if (total <= 0) {
      CompactSnackBar.showError(
        context,
        'Ingresa un monto total válido mayor a 0',
      );
      return;
    }

    final sumaRepartida = _getSumaRepartida();
    if ((sumaRepartida - total).abs() > 0.05) {
      CompactSnackBar.showError(
        context,
        'La suma de las facturas (${Formatters.formatCurrency(sumaRepartida)}) '
        'no coincide con el total (${Formatters.formatCurrency(total)})',
      );
      return;
    }

    if (_archivoBytes == null || _archivoNombre == null) {
      CompactSnackBar.showError(
        context,
        'Debes adjuntar la foto o comprobante del pago',
      );
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (var f in widget.facturasSeleccionadas) {
      final id = int.tryParse(f['id']?.toString() ?? '0') ?? 0;
      final c = _itemControllers[id];
      final m = double.tryParse(c?.text.trim().replaceAll(',', '') ?? '0') ?? 0;
      if (m > 0) {
        items.add({'cxc_id': id, 'monto': m});
      }
    }

    if (items.length < 2) {
      CompactSnackBar.showError(
        context,
        'El pago agrupado debe cubrir al menos 2 facturas con monto mayor a 0',
      );
      return;
    }

    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() => _isSubmitting = true);

    try {
      String nota = _notaController.text.trim();
      if (_formaPago != null && _formaPago!.isNotEmpty) {
        nota = 'Forma de pago: $_formaPago\n$nota'.trim();
      }

      await _service.addAlertaLote(
        montoTotal: total,
        tipo: _tipoAlerta,
        nota: nota.isNotEmpty ? nota : 'Pago agrupado recibido.',
        items: items,
        fileBytes: _archivoBytes!,
        fileName: _archivoNombre!,
        token: token,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      CompactSnackBar.showSuccess(
        context,
        '¡Pago agrupado enviado a contabilidad exitosamente!',
      );
    } catch (e) {
      if (mounted) {
        CompactSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clienteNombre =
        widget.facturasSeleccionadas.first['cliente']?['nombre'] ??
            'Cliente';
    final sumaRepartida = _getSumaRepartida();
    final total =
        double.tryParse(_montoTotalController.text.trim().replaceAll(',', '')) ??
            0;
    final cuadra = (sumaRepartida - total).abs() <= 0.05 && total > 0;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          children: [
            // Header compacto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pago Agrupado (${widget.facturasSeleccionadas.length} Facturas)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          clienteNombre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Contenido con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo: Monto Total Pagado
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _montoTotalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Monto Total del Comprobante',
                              labelStyle: const TextStyle(fontSize: 11),
                              prefixIcon: const Icon(
                                Icons.attach_money,
                                size: 18,
                                color: Colors.green,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Distribuir automáticamente por antigüedad',
                          child: ElevatedButton.icon(
                            onPressed: _distribuirAutomaticamente,
                            icon: const Icon(Icons.auto_fix_high, size: 14),
                            label: const Text(
                              'Auto',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Lista de facturas con reparto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Distribución por Factura:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Repartido: ${Formatters.formatCurrency(sumaRepartida)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cuadra ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.facturasSeleccionadas.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final f = widget.facturasSeleccionadas[index];
                          final id =
                              int.tryParse(f['id']?.toString() ?? '0') ?? 0;
                          final doc = f['documento'] ?? 'Doc';
                          final pend = double.tryParse(
                                f['monto_pendiente']?.toString() ?? '0',
                              ) ??
                              0;
                          final c = _itemControllers[id];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Pendiente: ${Formatters.formatCurrency(pend)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  height: 34,
                                  child: TextFormField(
                                    controller: c,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.end,
                                    decoration: InputDecoration(
                                      prefixText: '\$ ',
                                      prefixStyle: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tipo de alerta y forma de pago
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _tipoAlerta,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Concepto',
                              labelStyle: const TextStyle(fontSize: 11),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: AlertaUtils.tiposDeAlerta.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(
                                  AlertaUtils.getTipoLabel(t),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _tipoAlerta = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _formaPago,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Forma de Pago',
                              labelStyle: const TextStyle(fontSize: 11),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: AlertaUtils.formasDePago.map((forma) {
                              return DropdownMenuItem(
                                value: forma,
                                child: Text(
                                  AlertaUtils.getFormaPagoLabel(forma),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _formaPago = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Nota opcional
                    TextFormField(
                      controller: _notaController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        labelText: 'Nota o detalle (opcional)',
                        labelStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sección: Subir Comprobante Único
                    const Text(
                      '📎 Comprobante Único del Pago:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Esta foto se asociará automáticamente a todas las facturas.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickCamara,
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text(
                              'Cámara',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickGaleria,
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text(
                              'Galería',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _pickArchivo,
                            icon: const Icon(Icons.attach_file, size: 16),
                            label: const Text(
                              'Archivo',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_archivoNombre != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _archivoNombre!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.grey,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _archivoBytes = null;
                                  _archivoNombre = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer con botón de Enviar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: (_isSubmitting || !cuadra) ? null : _enviar,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isSubmitting ? 'Enviando...' : 'Enviar Alerta Agrupada',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
