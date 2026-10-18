import 'package:flutter/material.dart';
import 'package:industria_california/core/widgets/compact_snack_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/cancel_button.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/drop_down_widget.dart';
import '../../../core/widgets/input_field.dart';
import '../../../core/widgets/single_date_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ruta/providers/ruta_provider.dart';
import '../../users/providers/users_provider.dart';
import '../models/pedido.dart';
import '../providers/pedido_provider.dart';
import '../utils/pedido_utils.dart';
import '../../produccion/widgets/orden_produccion_pedido_dialog.dart';

class PedidoGestionDialog extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onUpdated;

  const PedidoGestionDialog({
    super.key,
    required this.pedido,
    required this.onUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required Pedido pedido,
    required VoidCallback onUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PedidoGestionDialog(pedido: pedido, onUpdated: onUpdated),
    );
  }

  @override
  State<PedidoGestionDialog> createState() => _PedidoGestionDialogState();
}

class _PedidoGestionDialogState extends State<PedidoGestionDialog> {
  final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _formKey = GlobalKey<FormState>();

  // ── Light Theme Palette (AppTheme) ──
  static const _bgDialog = AppTheme.dialogBg;
  static const _headerBg = AppTheme.dialogHeaderBg;
  static const _footerBg = AppTheme.dialogFooterBg;
  static const _cardSubtleBg = AppTheme.dialogCardSubtleBg;
  static const _borderColor = AppTheme.dialogBorderColor;
  static const _textPrimary = AppTheme.dialogTextPrimary;
  static const _textSecondary = AppTheme.dialogTextSecondary;
  static const _textMuted = AppTheme.dialogTextMuted;

  late TextEditingController _numFacturaCtrl;
  late TextEditingController _clienteCtrl;
  late TextEditingController _comentarioCtrl;
  late TextEditingController _notaProduccionCtrl;
  final _numFacturaFocusNode = FocusNode();

  late String _estadoSeleccionado;
  int? _clienteId;
  int? _rutaId;
  int? _vendedorId;
  DateTime? _fechaEntrega;

  bool _isSaving = false;

  late final List<String> _estadosDisponibles;

  bool get _esEntregado =>
      widget.pedido.estado.toLowerCase() == 'entregado' ||
      _estadoSeleccionado.toLowerCase() == 'entregado';

  @override
  void initState() {
    super.initState();
    _numFacturaCtrl = TextEditingController(
      text: widget.pedido.numFactura ?? '',
    );
    _clienteCtrl = TextEditingController(
      text: widget.pedido.clienteNombre ?? 'Cliente sin nombre',
    );
    _comentarioCtrl = TextEditingController(
      text: widget.pedido.comentario ?? '',
    );
    _notaProduccionCtrl = TextEditingController(
      text: widget.pedido.notaProduccion ?? '',
    );

    final estadoOriginal = widget.pedido.estado.toLowerCase();
    _estadoSeleccionado = estadoOriginal;

    // Reglas de transición solicitadas:
    // 0. Entregado: ya pasó por despacho y finalizó su ciclo, totalmente bloqueado.
    // 1. Facturado no puede cambiar a ningún otro.
    // 2. Enviado puede ponerse en borrador, facturado o cancelado.
    // 3. Cotización puede ponerse en borrador, facturar o cancelar.
    // 4. Cancelado queda cerrado.
    // 5. Borrador puede pasar a cotización, enviado, facturado o cancelado.
    switch (estadoOriginal) {
      case 'entregado':
        _estadosDisponibles = const ['entregado'];
        break;
      case 'facturado':
        _estadosDisponibles = const ['facturado'];
        break;
      case 'enviado':
        _estadosDisponibles = const [
          'enviado',
          'borrador',
          'facturado',
          'cancelado',
        ];
        break;
      case 'cotizacion':
        _estadosDisponibles = const [
          'cotizacion',
          'borrador',
          'facturado',
          'cancelado',
        ];
        break;
      case 'cancelado':
        _estadosDisponibles = const ['cancelado'];
        break;
      case 'borrador':
      default:
        _estadosDisponibles = const [
          'borrador',
          'enviado',
          'cotizacion',
          'facturado',
          'cancelado',
        ];
        break;
    }

    if (!_estadosDisponibles.contains(_estadoSeleccionado)) {
      _estadoSeleccionado = _estadosDisponibles.first;
    }

    _clienteId = widget.pedido.clienteId;
    _rutaId = widget.pedido.rutaId;
    _vendedorId = widget.pedido.vendedorId;
    _fechaEntrega = widget.pedido.fechaEntrega;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RutaProvider>().fetchRutas();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _numFacturaCtrl.dispose();
    _clienteCtrl.dispose();
    _comentarioCtrl.dispose();
    _notaProduccionCtrl.dispose();
    _numFacturaFocusNode.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_esEntregado) {
      CompactSnackBar.showWarning(
        context,
        '⚠️ Este pedido ya fue ENTREGADO y no admite modificaciones.',
      );
      return;
    }

    final esFacturado = _estadoSeleccionado.toLowerCase() == 'facturado';

    if (esFacturado && _numFacturaCtrl.text.trim().isEmpty) {
      _numFacturaFocusNode.requestFocus();
      _formKey.currentState?.validate();
      CompactSnackBar.showWarning(
        context,
        '⚠️ Debes ingresar el número de factura para guardar el pedido como FACTURADO.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PedidoProvider>();
    final nav = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      final success = await provider.updateInformacion(
        widget.pedido.id,
        clienteId: _clienteId,
        rutaId: _rutaId,
        vendedorId: _vendedorId,
        numFactura: _numFacturaCtrl.text.trim().isEmpty
            ? null
            : _numFacturaCtrl.text.trim(),
        estado: _estadoSeleccionado,
        fechaEntrega: _fechaEntrega,
        comentario: _comentarioCtrl.text.trim().isEmpty
            ? null
            : _comentarioCtrl.text.trim(),
        notaProduccion: _notaProduccionCtrl.text.trim().isEmpty
            ? null
            : _notaProduccionCtrl.text.trim(),
      );

      if (success) {
        if (!mounted) return;
        nav.pop();
        widget.onUpdated();
        CompactSnackBar.showSuccess(context, 'Pedido actualizado exitosamente');
      } else {
        final err = provider.error ?? 'Error al actualizar el pedido';
        throw Exception(err);
      }
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showError(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generarPdf() async {
    CompactSnackBar.showInfo(context, 'Generando Factura...');
    try {
      final urlStr = await context.read<PedidoProvider>().getPdfUrl(
        widget.pedido.id,
      );
      final url = Uri.parse(urlStr);
      if (!await launchUrl(url)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (!mounted) return;
      CompactSnackBar.showError(context, 'Error al abrir PDF: $e');
    }
  }

  void _confirmDelete() {
    if (_esEntregado) {
      CompactSnackBar.showWarning(
        context,
        '⚠️ No se puede eliminar un pedido que ya fue ENTREGADO.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _bgDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _borderColor),
          ),
          title: const Text(
            'Eliminar Pedido',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Estás seguro de eliminar el pedido #${widget.pedido.id}? Esta acción no se puede deshacer.',
            style: const TextStyle(color: _textSecondary, fontSize: 13),
          ),
          actions: [
            CancelButton(
              text: 'CANCELAR',
              isDark: false,
              height: 36,
              borderRadius: 6,
              onPressed: () => Navigator.pop(ctx),
            ),
            CustomButton(
              text: 'ELIMINAR',
              color: const Color(0xFFE31E24),
              height: 36,
              fontSize: 11,
              borderRadius: 6,
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<PedidoProvider>();
                final success = await provider.deletePedido(widget.pedido.id);
                if (success && mounted) {
                  Navigator.pop(context);
                  widget.onUpdated();
                  CompactSnackBar.showSuccess(context, 'Pedido eliminado');
                } else if (mounted) {
                  CompactSnackBar.showError(
                    context,
                    'Error: ${provider.error}',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _abrirDialogFacturarVigente({
    required double totalVigente,
    required double totalFaltante,
  }) {
    if (totalVigente <= 0) {
      CompactSnackBar.showWarning(
        context,
        'No hay artículos disponibles en stock para facturar (\$0.00). Todos los ítems están en producción.',
      );
      return;
    }
    final numFacturaInputCtrl = TextEditingController(
      text: _numFacturaCtrl.text,
    );
    final formKey = GlobalKey<FormState>();
    final comentarioLocalCtrl = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: _bgDialog,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _borderColor),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF059669),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Facturar Artículos Vigentes',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Despacho de lote disponible en almacén',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Resumen de la escisión
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardSubtleBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'A Facturar Ahora (En Stock):',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currencyFmt.format(totalVigente),
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14, color: _borderColor),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'A Escindir (Orden de Producción):',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currencyFmt.format(totalFaltante),
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Al confirmar, el Pedido #${widget.pedido.id} quedará FACTURADO con el lote disponible (${_currencyFmt.format(totalVigente)}). Se creará automáticamente un Pedido Remanente para los artículos faltantes vinculado a Producción.',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    InputField(
                      label: 'No. de Factura *',
                      controller: numFacturaInputCtrl,
                      hint: 'Ej: B0100000045',
                      icon: Icons.receipt_rounded,
                      isDark: false,
                      dense: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa el número de factura';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    InputField(
                      label: 'Nota de Facturación (Opcional)',
                      controller: comentarioLocalCtrl,
                      hint: 'Ej: Entregado parcialmente según disponibilidad',
                      icon: Icons.note_rounded,
                      isDark: false,
                      dense: true,
                      optional: true,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CancelButton(
                          text: 'CANCELAR',
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.pop(ctx),
                          isDark: false,
                          height: 36,
                          borderRadius: 6,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          text: isProcessing
                              ? 'PROCESANDO...'
                              : 'CONFIRMAR Y FACTURAR',
                          color: const Color(0xFF059669),
                          textColor: Colors.white,
                          isLoading: isProcessing,
                          height: 36,
                          fontSize: 11,
                          borderRadius: 6,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  final nav = Navigator.of(context);
                                  final dialogNav = Navigator.of(ctx);
                                  final pedidoProv = context
                                      .read<PedidoProvider>();

                                  setDialogState(() => isProcessing = true);
                                  final numFac = numFacturaInputCtrl.text
                                      .trim();
                                  final res = await pedidoProv.facturarVigente(
                                    widget.pedido.id,
                                    numFactura: numFac,
                                    fechaEntrega: _fechaEntrega,
                                    notaProduccion:
                                        _notaProduccionCtrl.text.trim().isEmpty
                                        ? null
                                        : _notaProduccionCtrl.text.trim(),
                                    comentario:
                                        comentarioLocalCtrl.text.trim().isEmpty
                                        ? null
                                        : comentarioLocalCtrl.text.trim(),
                                  );

                                  if (!mounted) return;
                                  dialogNav.pop();
                                  if (res != null) {
                                    nav.pop();
                                    widget.onUpdated();
                                    final remanente = res['pedido_remanente'];
                                    final remanenteId = remanente?['id'];
                                    CompactSnackBar.showSuccess(
                                      context,
                                      'Pedido #${widget.pedido.id} facturado por ${_currencyFmt.format(totalVigente)}.'
                                      '${remanenteId != null ? " Creado Pedido Remanente #$remanenteId para producción." : ""}',
                                    );
                                  } else {
                                    final err =
                                        pedidoProv.error ??
                                        'Error al procesar la facturación';
                                    CompactSnackBar.showError(context, err);
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final estadoColor = PedidoUtils.getColorForEstado(_estadoSeleccionado);
    final fechaCreacion = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(widget.pedido.createdAt);

    double totalFaltante = 0.0;
    double totalVigente = 0.0;
    for (var det in widget.pedido.detalles) {
      final cantFaltante = det.cantidadEnProduccion;
      final cantVigente = (det.cantidad - cantFaltante).clamp(
        0.0,
        double.infinity,
      );
      totalFaltante += (cantFaltante * det.precioUnitario);
      totalVigente += (cantVigente * det.precioUnitario);
    }
    final tieneFaltantes = totalFaltante > 0;
    final estadoLower = widget.pedido.estado.toLowerCase();
    final isFacturado = estadoLower == 'facturado';
    final isCancelado = estadoLower == 'cancelado';
    final puedeFacturarVigente =
        !isFacturado && !isCancelado && tieneFaltantes && totalVigente > 0;
    final puedeVerOrdenProd = !isCancelado && tieneFaltantes;

    return Dialog(
      backgroundColor: _bgDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: _headerBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: _borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: estadoColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Trabajar Pedido #${widget.pedido.id}',
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: estadoColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: estadoColor.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _estadoSeleccionado.toUpperCase(),
                                style: TextStyle(
                                  color: estadoColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (widget.pedido.tieneOrdenProduccion) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.precision_manufacturing_rounded,
                                      size: 10,
                                      color: Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'OP #${widget.pedido.ordenProduccionId} (${widget.pedido.ordenProduccionEstado?.toUpperCase()})',
                                      style: const TextStyle(
                                        color: Color(0xFFB45309),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (tieneFaltantes) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'FALTANTES',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.pedido.clienteNombre ?? 'Cliente sin nombre'} • Vendedor: ${widget.pedido.vendedorNombre ?? '-'} • $fechaCreacion',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver / Imprimir Factura (PDF)',
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    onPressed: _generarPdf,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _textSecondary,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Resumen de métricas ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _cardSubtleBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            if (tieneFaltantes) ...[
                              Expanded(
                                child: _buildMetricItem(
                                  'Total Original',
                                  _currencyFmt.format(widget.pedido.total),
                                  _textPrimary,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: _borderColor,
                              ),
                              Expanded(
                                child: _buildMetricItem(
                                  'Vigente (Stock)',
                                  _currencyFmt.format(totalVigente),
                                  const Color(0xFF059669),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: _borderColor,
                              ),
                              Expanded(
                                child: _buildMetricItem(
                                  'Faltante (OP)',
                                  _currencyFmt.format(totalFaltante),
                                  const Color(0xFFDC2626),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: _borderColor,
                              ),
                              Expanded(
                                child: _buildMetricItem(
                                  'Factura',
                                  (widget.pedido.numFactura != null &&
                                          widget.pedido.numFactura!
                                              .trim()
                                              .isNotEmpty)
                                      ? widget.pedido.numFactura!
                                      : 'Sin Facturar',
                                  (widget.pedido.numFactura != null &&
                                          widget.pedido.numFactura!
                                              .trim()
                                              .isNotEmpty)
                                      ? const Color(0xFF2563EB)
                                      : _textMuted,
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: _buildMetricItem(
                                  'Total Pedido',
                                  _currencyFmt.format(widget.pedido.total),
                                  const Color(0xFF059669),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: _borderColor,
                              ),
                              Expanded(
                                child: _buildMetricItem(
                                  'Productos',
                                  '${widget.pedido.detalles.length} ítem(s)',
                                  _textSecondary,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: _borderColor,
                              ),
                              Expanded(
                                child: _buildMetricItem(
                                  'Factura Actual',
                                  (widget.pedido.numFactura != null &&
                                          widget.pedido.numFactura!
                                              .trim()
                                              .isNotEmpty)
                                      ? widget.pedido.numFactura!
                                      : 'Sin Facturar',
                                  (widget.pedido.numFactura != null &&
                                          widget.pedido.numFactura!
                                              .trim()
                                              .isNotEmpty)
                                      ? const Color(0xFF2563EB)
                                      : _textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_esEntregado) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF059669),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Este pedido ya fue ENTREGADO en despacho y su ciclo comercial finalizó. La información está protegida en modo solo lectura y no puede ser modificada ni eliminada.',
                                  style: TextStyle(
                                    color: Color(0xFF065F46),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (tieneFaltantes) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hay faltantes de inventario por ${_currencyFmt.format(totalFaltante)}. Puedes facturar lo vigente disponible hoy (${_currencyFmt.format(totalVigente)}) y escindir los faltantes a un Pedido Remanente con Orden de Producción.',
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 10.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // ── SECCIÓN 1: INFORMACIÓN PRINCIPAL ──
                      Row(
                        children: [
                          Icon(
                            _esEntregado
                                ? Icons.lock_outline_rounded
                                : Icons.edit_note_rounded,
                            color: _esEntregado
                                ? const Color(0xFF059669)
                                : AppTheme.primaryBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _esEntregado
                                ? 'Información del Pedido (Solo Lectura - Entregado)'
                                : 'Información Principal (Editable)',
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Campos: Estado & No. Factura
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Estado
                          Expanded(
                            child: DropDownWidget<String>(
                              label: _esEntregado
                                  ? 'Estado del Pedido (Entregado / Cerrado):'
                                  : (_estadosDisponibles.length <= 1
                                      ? 'Estado del Pedido (Bloqueado):'
                                      : 'Estado del Pedido:'),
                              value: _estadoSeleccionado,
                              icon: (_esEntregado || _estadosDisponibles.length <= 1)
                                  ? Icons.lock_outline_rounded
                                  : Icons.tune_rounded,
                              iconColor: estadoColor,
                              isDark: false,
                              dense: true,
                              customItems: _estadosDisponibles.map((e) {
                                final col = PedidoUtils.getColorForEstado(e);
                                return DropdownMenuItem<String>(
                                  value: e,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: col,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        e.toUpperCase(),
                                        style: TextStyle(
                                          color: col,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (_esEntregado ||
                                      _estadosDisponibles.length <= 1)
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setState(
                                          () => _estadoSeleccionado = val,
                                        );
                                        if (val.toLowerCase() == 'facturado' &&
                                            _numFacturaCtrl.text
                                                .trim()
                                                .isEmpty) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                _numFacturaFocusNode
                                                    .requestFocus();
                                                _formKey.currentState
                                                    ?.validate();
                                              });
                                        }
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // No. Factura
                          Expanded(
                            child: InputField(
                              controller: _numFacturaCtrl,
                              focusNode: _numFacturaFocusNode,
                              label: _esEntregado
                                  ? 'No. Factura (Bloqueado):'
                                  : (_estadoSeleccionado.toLowerCase() ==
                                          'facturado'
                                      ? 'No. Factura: *'
                                      : 'No. Factura:'),
                              hint: _estadoSeleccionado.toLowerCase() ==
                                      'facturado'
                                  ? 'Ej. B0100000045 (obligatorio)'
                                  : 'Ej. B0100000045 (opcional)',
                              icon: Icons.receipt_long_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              isDark: false,
                              dense: true,
                              readOnly: _esEntregado,
                              suffixIcon: _esEntregado
                                  ? const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Icon(
                                        Icons.lock_outline_rounded,
                                        size: 15,
                                        color: _textMuted,
                                      ),
                                    )
                                  : null,
                              optional: _esEntregado ||
                                  _estadoSeleccionado.toLowerCase() !=
                                      'facturado',
                              validator: (val) {
                                if (_esEntregado) return null;
                                if (_estadoSeleccionado.toLowerCase() ==
                                    'facturado') {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Requerido al facturar';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Campos: Cliente & Ruta
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cliente (Solo lectura)
                          Expanded(
                            child: InputField(
                              controller: _clienteCtrl,
                              label: 'Cliente:',
                              hint: 'Sin cliente asignado',
                              icon: Icons.person_rounded,
                              iconColor: AppTheme.primaryBlue,
                              isDark: false,
                              dense: true,
                              readOnly: true,
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 15,
                                  color: _textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Ruta
                          Expanded(
                            child: Consumer<RutaProvider>(
                              builder: (context, rutaProv, _) {
                                final rutas = rutaProv.rutas;
                                return DropDownWidget<int?>(
                                  label: _esEntregado
                                      ? 'Ruta de Entrega (Bloqueado):'
                                      : 'Ruta de Entrega:',
                                  value: _rutaId,
                                  hint:
                                      widget.pedido.rutaNombre ??
                                      'Sin ruta asignada',
                                  icon: _esEntregado
                                      ? Icons.lock_outline_rounded
                                      : Icons.local_shipping_rounded,
                                  iconColor: Colors.blueAccent,
                                  isDark: false,
                                  dense: true,
                                  optional: true,
                                  customItems: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(
                                        '-- Sin ruta asignada --',
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    ...rutas.map((r) {
                                      return DropdownMenuItem<int?>(
                                        value: r.id,
                                        child: Text(
                                          r.nombre,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: _esEntregado
                                      ? null
                                      : (val) {
                                          setState(() => _rutaId = val);
                                        },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Campos: Vendedor & Fecha de Entrega
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vendedor
                          Expanded(
                            child: Consumer<UsersProvider>(
                              builder: (context, userProv, _) {
                                final users = userProv.users;
                                return DropDownWidget<int>(
                                  label: _esEntregado
                                      ? 'Vendedor Asignado (Bloqueado):'
                                      : 'Vendedor Asignado:',
                                  value: _vendedorId,
                                  hint:
                                      widget.pedido.vendedorNombre ??
                                      'Seleccionar vendedor',
                                  icon: _esEntregado
                                      ? Icons.lock_outline_rounded
                                      : Icons.badge_rounded,
                                  iconColor: Colors.teal.shade700,
                                  isDark: false,
                                  dense: true,
                                  customItems: users.map((u) {
                                    final id = u['id'] as int;
                                    final name = u['name'] ?? 'Usuario #$id';
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _esEntregado
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setState(() => _vendedorId = val);
                                          }
                                        },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Fecha de Entrega
                          Expanded(
                            child: SingleDatePicker(
                              label: _esEntregado
                                  ? 'Fecha de Entrega (Bloqueado):'
                                  : 'Fecha de Entrega Estimada:',
                              value: _fechaEntrega,
                              hint: 'Sin fecha de entrega',
                              icon: _esEntregado
                                  ? Icons.lock_outline_rounded
                                  : Icons.calendar_today_rounded,
                              iconColor: const Color(0xFFD97706),
                              isDark: false,
                              dense: true,
                              optional: true,
                              enabled: !_esEntregado,
                              onChanged: _esEntregado
                                  ? (_) {}
                                  : (picked) {
                                      setState(() => _fechaEntrega = picked);
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Comentarios
                      InputField(
                        controller: _comentarioCtrl,
                        label: _esEntregado
                            ? 'Comentarios / Observaciones (Solo Lectura):'
                            : 'Comentarios / Observaciones del Pedido:',
                        hint: 'Detalles u observaciones del cliente...',
                        icon: Icons.comment_outlined,
                        iconColor: _textSecondary,
                        isDark: false,
                        dense: true,
                        maxLines: 2,
                        readOnly: _esEntregado,
                        optional: true,
                      ),
                      const SizedBox(height: 10),

                      // Nota de Producción
                      InputField(
                        controller: _notaProduccionCtrl,
                        label: _esEntregado
                            ? 'Nota para Producción (Solo Lectura):'
                            : 'Nota para Producción:',
                        hint: 'Instrucciones para planta o despacho...',
                        icon: Icons.precision_manufacturing_outlined,
                        iconColor: const Color(0xFFEA580C),
                        isDark: false,
                        dense: true,
                        maxLines: 2,
                        readOnly: _esEntregado,
                        optional: true,
                      ),
                      const SizedBox(height: 20),

                      // ── SECCIÓN 2: PRODUCTOS (SOLO LECTURA) ──
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFFD97706),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Productos del Pedido',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 11,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Solo Lectura',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tabla de productos
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2.8), // Producto
                              1: FlexColumnWidth(1.1), // Solicitado
                              2: FlexColumnWidth(0.9), // Vigente
                              3: FlexColumnWidth(1.0), // Faltante
                              4: FlexColumnWidth(1.1), // Precio
                              5: FlexColumnWidth(1.4), // Subtotal
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: _cardSubtleBg,
                                  border: Border(
                                    bottom: BorderSide(color: _borderColor),
                                  ),
                                ),
                                children: [
                                  _buildTableHeaderCell('PRODUCTO'),
                                  _buildTableHeaderCell(
                                    'PEDIDO',
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'VIGENTE',
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'FALTANTE',
                                    align: TextAlign.center,
                                  ),
                                  _buildTableHeaderCell(
                                    'PRECIO',
                                    align: TextAlign.right,
                                  ),
                                  _buildTableHeaderCell(
                                    'SUBTOTAL',
                                    align: TextAlign.right,
                                  ),
                                ],
                              ),
                              ...widget.pedido.detalles.map((det) {
                                final cantFaltante = det.cantidadEnProduccion;
                                final cantVigente =
                                    (det.cantidad - cantFaltante).clamp(
                                      0.0,
                                      double.infinity,
                                    );
                                final subtotalVigente =
                                    cantVigente * det.precioUnitario;

                                return TableRow(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: _borderColor),
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            det.productoNombre ??
                                                'Producto #${det.productoId}',
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (det.productoCodigo != null &&
                                              det.productoCodigo!.isNotEmpty)
                                            Text(
                                              'Cód: ${det.productoCodigo}',
                                              style: const TextStyle(
                                                color: _textMuted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          if (det.observacion != null &&
                                              det.observacion!
                                                  .trim()
                                                  .isNotEmpty)
                                            Text(
                                              'Obs: ${det.observacion}',
                                              style: const TextStyle(
                                                color: Color(0xFFB45309),
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Solicitado / Pedido
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        '${det.cantidad.toStringAsFixed(det.cantidad % 1 == 0 ? 0 : 2)}${det.productoUnidad != null && det.productoUnidad!.trim().isNotEmpty ? ' ${det.productoUnidad!.trim()}' : ''}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: _textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    // Vigente (Stock)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        cantVigente.toStringAsFixed(
                                          cantVigente % 1 == 0 ? 0 : 2,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: cantFaltante > 0
                                              ? const Color(0xFF059669)
                                              : _textSecondary,
                                          fontSize: 11,
                                          fontWeight: cantFaltante > 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    // Faltante (OP)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: cantFaltante > 0
                                          ? Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFEF2F2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFFECACA,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  cantFaltante.toStringAsFixed(
                                                    cantFaltante % 1 == 0
                                                        ? 0
                                                        : 2,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFFDC2626),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              '-',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                    ),
                                    // Precio
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        _currencyFmt.format(det.precioUnitario),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: _textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    // Subtotal
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _currencyFmt.format(
                                              cantFaltante > 0
                                                  ? subtotalVigente
                                                  : det.subtotal,
                                            ),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              color: Color(0xFF059669),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (cantFaltante > 0)
                                            Text(
                                              'Orig: ${_currencyFmt.format(det.subtotal)}',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                color: _textMuted,
                                                fontSize: 9,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      if (tieneFaltantes) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _cardSubtleBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Subtotal Vigente: ${_currencyFmt.format(totalVigente)}',
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.precision_manufacturing_rounded,
                                    size: 14,
                                    color: Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Faltante a Escindir: ${_currencyFmt.format(totalFaltante)}',
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        '* Los productos, cantidades y precios no se modifican desde este formulario para resguardar la consistencia contable y de inventario.',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── FOOTER ACTIONS ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: _footerBg,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 620;

                  final operationalActions = <Widget>[
                    if (isAdmin && !_esEntregado)
                      CustomButton(
                        text: 'ELIMINAR',
                        icon: Icons.delete_outline,
                        isOutlined: true,
                        color: const Color(0xFFE31E24),
                        textColor: const Color(0xFFE31E24),
                        height: 32,
                        fontSize: 10.5,
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        onPressed: _isSaving ? null : _confirmDelete,
                      ),
                    if (puedeVerOrdenProd)
                      CustomButton(
                        text: 'ORDEN PROD.',
                        icon: Icons.precision_manufacturing_rounded,
                        isOutlined: true,
                        color: const Color(0xFFD97706),
                        textColor: const Color(0xFFD97706),
                        height: 32,
                        fontSize: 10.5,
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        onPressed: () {
                          OrdenProduccionPedidoDialog.show(
                            context: context,
                            pedido: widget.pedido,
                            onUpdated: widget.onUpdated,
                          );
                        },
                      ),
                    if (puedeFacturarVigente && !_esEntregado)
                      CustomButton(
                        text: 'FACTURAR VIGENTE',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF059669),
                        textColor: Colors.white,
                        height: 32,
                        fontSize: 10.5,
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => _abrirDialogFacturarVigente(
                                totalVigente: totalVigente,
                                totalFaltante: totalFaltante,
                              ),
                      ),
                  ];

                  final confirmActions = <Widget>[
                    if (_esEntregado)
                      CancelButton(
                        text: 'CERRAR',
                        onPressed: () => Navigator.pop(context),
                        isDark: false,
                        height: 32,
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                      )
                    else ...[
                      CancelButton(
                        text: 'CANCELAR',
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        isDark: false,
                        height: 32,
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: _isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
                        color: const Color(0xFFE31E24),
                        textColor: Colors.white,
                        isLoading: _isSaving,
                        height: 32,
                        fontSize: 10.5,
                        borderRadius: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        onPressed: _isSaving ? null : _guardarCambios,
                      ),
                    ],
                  ];

                  if (isCompact && operationalActions.isNotEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: operationalActions,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: confirmActions,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (int i = 0; i < operationalActions.length; i++) ...[
                        operationalActions[i],
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      ...confirmActions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(
    String text, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _textMuted,
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
