import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/alerta_utils.dart';
import '../../../core/utils/constants.dart';
import '../models/cxc_alerta_model.dart';
import '../services/cxc_alerta_service.dart';

class AlertaGestionDialog extends StatefulWidget {
  final CxcAlertaModel alerta;
  final VoidCallback onUpdated;

  const AlertaGestionDialog({
    super.key,
    required this.alerta,
    required this.onUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required CxcAlertaModel alerta,
    required VoidCallback onUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertaGestionDialog(alerta: alerta, onUpdated: onUpdated),
    );
  }

  @override
  State<AlertaGestionDialog> createState() => _AlertaGestionDialogState();
}

class _AlertaGestionDialogState extends State<AlertaGestionDialog> {
  final _service = CxcAlertaService();

  late String _tipoSeleccionado;
  late TextEditingController _montoController;
  late String _estadoCxc;
  late bool _actualizarCxc;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.alerta.tipo;
    final montoInicial =
        widget.alerta.montoInformado ?? widget.alerta.cxc?.montoPendiente;
    _montoController = TextEditingController(
      text: montoInicial?.toStringAsFixed(2) ?? '',
    );
    final saldoPendiente = widget.alerta.cxc?.montoPendiente ?? 0.0;
    _estadoCxc =
        (montoInicial != null &&
            saldoPendiente > 0 &&
            montoInicial >= saldoPendiente)
        ? 'pagado'
        : 'pendiente';
    _actualizarCxc = widget.alerta.tipo == 'pago_recibido';
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '-';
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'pago_recibido':
        return Colors.greenAccent;
      case 'consulta':
        return Colors.blueAccent;
      case 'credito':
      case 'debito':
      case 'devolucion':
      case 'retencion':
        return Colors.purpleAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  List<EvidenciaModel> _obtenerEvidenciasUnicas() {
    final list = <EvidenciaModel>[];
    final ids = <int>{};
    for (var ev in widget.alerta.evidencias) {
      if (!ids.contains(ev.id)) {
        list.add(ev);
        ids.add(ev.id);
      }
    }
    if (widget.alerta.cxc?.evidencias != null) {
      for (var ev in widget.alerta.cxc!.evidencias) {
        if (!ids.contains(ev.id)) {
          list.add(ev);
          ids.add(ev.id);
        }
      }
    }
    return list;
  }

  Future<void> _abrirEvidencia(String ruta) async {
    if (ruta.isEmpty) return;
    try {
      final url = Uri.parse('$host/storage/$ruta');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 1. Guardar cambios y Procesar
  Future<void> _procesarYGuardar() async {
    setState(() => _isSaving = true);
    try {
      if (_tipoSeleccionado != widget.alerta.tipo) {
        await _service.updateTipoAlerta(
          alertaId: widget.alerta.id,
          nuevoTipo: _tipoSeleccionado,
        );
      }

      final monto = _actualizarCxc && _montoController.text.isNotEmpty
          ? double.tryParse(_montoController.text.replaceAll(',', ''))
          : null;

      await _service.resolverAlerta(
        alertaId: widget.alerta.id,
        estadoAlerta: 'procesada',
        actualizarCxc: _actualizarCxc,
        montoPagado: monto,
        estadoCxc: _actualizarCxc ? _estadoCxc : null,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerta procesada y guardada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 2. Marcar como revisada solamente
  Future<void> _marcarRevisada() async {
    setState(() => _isSaving = true);
    try {
      if (_tipoSeleccionado != widget.alerta.tipo) {
        await _service.updateTipoAlerta(
          alertaId: widget.alerta.id,
          nuevoTipo: _tipoSeleccionado,
        );
      }

      await _service.resolverAlerta(
        alertaId: widget.alerta.id,
        estadoAlerta: 'procesada',
        actualizarCxc: false,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerta marcada como procesada'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 3. Guardar solo el concepto si ya está procesada
  Future<void> _actualizarSoloConcepto() async {
    setState(() => _isSaving = true);
    try {
      if (_tipoSeleccionado != widget.alerta.tipo) {
        await _service.updateTipoAlerta(
          alertaId: widget.alerta.id,
          nuevoTipo: _tipoSeleccionado,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Concepto actualizado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 4. Eliminar alerta
  Future<void> _eliminarAlerta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.darkBorderColor),
        ),
        title: const Text(
          'Eliminar Alerta',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta alerta? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isDeleting = true);
    try {
      await _service.deleteAlerta(widget.alerta.id);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerta eliminada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cxc = widget.alerta.cxc;
    final cliente = cxc?.cliente;
    final vendedor = widget.alerta.vendedor;
    final isPendiente = widget.alerta.estadoAlerta == 'pendiente';
    final evidencias = _obtenerEvidenciasUnicas();
    final tipoColor = _getTipoColor(_tipoSeleccionado);

    return Dialog(
      backgroundColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.darkBorderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkInputColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.darkBorderColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPendiente
                        ? Icons.notifications_active_rounded
                        : Icons.check_circle_rounded,
                    color: isPendiente
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Factura: ${cxc?.noFactura ?? 'Sin Factura'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isPendiente
                                            ? Colors.orangeAccent
                                            : Colors.greenAccent)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPendiente
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isPendiente ? 'PENDIENTE' : 'PROCESADA',
                                style: TextStyle(
                                  color: isPendiente
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cliente?.nombre ?? 'Cliente desconocido'}  •  Vendedor: ${vendedor?.name ?? '-'}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── BODY SCROLLABLE ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Métricas compactas de montos
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkInputColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.darkBorderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Monto Informado',
                              _formatCurrency(widget.alerta.montoInformado),
                              AppTheme.successColor,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppTheme.darkBorderColor,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              'Saldo Pendiente CXC',
                              _formatCurrency(cxc?.montoPendiente),
                              AppTheme.accentYellow,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppTheme.darkBorderColor,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              'Fecha de Alerta',
                              _formatDateTime(widget.alerta.createdAt),
                              Colors.white70,
                              isDate: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Selector de Concepto
                    Row(
                      children: [
                        const Text(
                          'Concepto:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.darkInputColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tipoColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _tipoSeleccionado,
                                dropdownColor: AppTheme.darkCardColor,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: tipoColor,
                                  size: 18,
                                ),
                                items: AlertaUtils.tiposDeAlerta.map((t) {
                                  final color = _getTipoColor(t);
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AlertaUtils.getTipoLabel(t),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _tipoSeleccionado = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nota del Vendedor
                    const Text(
                      'Detalle / Nota del Vendedor:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.darkInputColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorderColor),
                      ),
                      child: Text(
                        (widget.alerta.nota != null &&
                                widget.alerta.nota!.trim().isNotEmpty)
                            ? widget.alerta.nota!
                            : 'Sin nota adjunta.',
                        style: TextStyle(
                          color:
                              (widget.alerta.nota != null &&
                                  widget.alerta.nota!.trim().isNotEmpty)
                              ? Colors.white
                              : Colors.grey.shade500,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Evidencias adjuntas
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          color: Colors.redAccent,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Evidencias Adjuntas (${evidencias.length}):',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (evidencias.isEmpty)
                      Text(
                        'No hay fotos ni documentos adjuntos en esta alerta.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: evidencias.map((ev) {
                          return ActionChip(
                            backgroundColor: AppTheme.darkInputColor,
                            side: BorderSide(color: AppTheme.darkBorderColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            avatar: Icon(
                              ev.isImage
                                  ? Icons.image_rounded
                                  : Icons.picture_as_pdf_rounded,
                              size: 14,
                              color: ev.isImage
                                  ? Colors.blueAccent
                                  : Colors.redAccent,
                            ),
                            label: Text(
                              ev.nombreArchivo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () => _abrirEvidencia(ev.rutaArchivo),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),

                    // ── SECCIÓN DE PROCESAMIENTO / RESOLUCIÓN ──
                    if (isPendiente) ...[
                      const Divider(
                        color: AppTheme.darkBorderColor,
                        height: 24,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: AppTheme.ledhouseBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Aplicar a Cuenta por Cobrar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkInputColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.darkBorderColor),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              title: const Text(
                                'Actualizar saldo en CXC',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'Registrar abono/pago sobre la factura en el sistema',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              value: _actualizarCxc,
                              activeThumbColor: AppTheme.ledhouseBlue,
                              onChanged: (v) =>
                                  setState(() => _actualizarCxc = v),
                            ),
                            if (_actualizarCxc) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: SizedBox(
                                      height: 38,
                                      child: TextFormField(
                                        controller: _montoController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        onChanged: (val) {
                                          final monto = double.tryParse(
                                            val.replaceAll(',', '').trim(),
                                          );
                                          final saldo =
                                              widget
                                                  .alerta
                                                  .cxc
                                                  ?.montoPendiente ??
                                              0.0;
                                          if (monto != null && saldo > 0) {
                                            if (monto >= saldo &&
                                                _estadoCxc != 'pagado') {
                                              setState(
                                                () => _estadoCxc = 'pagado',
                                              );
                                            } else if (monto < saldo &&
                                                _estadoCxc == 'pagado') {
                                              setState(
                                                () => _estadoCxc = 'pendiente',
                                              );
                                            }
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Monto pagado a registrar',
                                          labelStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 11,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.attach_money,
                                            color: Colors.greenAccent,
                                            size: 16,
                                          ),
                                          filled: true,
                                          fillColor: AppTheme.darkInputColor,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppTheme.darkBorderColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppTheme.ledhouseBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 38,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _estadoCxc,
                                        dropdownColor: AppTheme.darkCardColor,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Estado factura',
                                          labelStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 11,
                                          ),
                                          filled: true,
                                          fillColor: AppTheme.darkInputColor,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppTheme.darkBorderColor,
                                            ),
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'pendiente',
                                            child: Text('Pendiente'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'pagado',
                                            child: Text('Pagado'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'cancelado',
                                            child: Text('Cancelado'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _estadoCxc = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      // Ya procesada: mostrar info de quién procesó
                      const Divider(
                        color: AppTheme.darkBorderColor,
                        height: 24,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.greenAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Procesada por: ${widget.alerta.revisador?.name ?? 'Contabilidad'}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.alerta.fechaRevision != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${_formatDateTime(widget.alerta.fechaRevision)})',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── FOOTER ACTIONS ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkInputColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.darkBorderColor),
                ),
              ),
              child: Row(
                children: [
                  // Botón Eliminar
                  IconButton(
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                    tooltip: 'Eliminar alerta',
                    onPressed: (_isSaving || _isDeleting)
                        ? null
                        : _eliminarAlerta,
                  ),
                  const Spacer(),

                  if (isPendiente) ...[
                    // Marcar solo revisada
                    OutlinedButton(
                      onPressed: (_isSaving || _isDeleting)
                          ? null
                          : _marcarRevisada,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Marcar Revisada',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Procesar y Guardar
                    ElevatedButton(
                      onPressed: (_isSaving || _isDeleting)
                          ? null
                          : _procesarYGuardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ledhouseBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Procesar y Aplicar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ] else ...[
                    // Ya procesada: Guardar concepto si cambió
                    if (_tipoSeleccionado != widget.alerta.tipo) ...[
                      ElevatedButton(
                        onPressed: (_isSaving || _isDeleting)
                            ? null
                            : _actualizarSoloConcepto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.ledhouseBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Guardar Concepto',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    Color color, {
    bool isDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isDate ? 11 : 13,
            fontWeight: isDate ? FontWeight.normal : FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
