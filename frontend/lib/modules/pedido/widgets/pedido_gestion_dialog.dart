import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/themes/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../led_house/providers/ledhouse_cliente_provider.dart';
import '../../ruta/providers/ruta_provider.dart';
import '../../users/providers/users_provider.dart';
import '../models/pedido.dart';
import '../providers/pedido_provider.dart';

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

  late TextEditingController _numFacturaCtrl;
  late TextEditingController _comentarioCtrl;
  late TextEditingController _notaProduccionCtrl;

  late String _estadoSeleccionado;
  int? _clienteId;
  int? _rutaId;
  int? _vendedorId;
  DateTime? _fechaEntrega;

  bool _isSaving = false;

  final List<String> _estadosDisponibles = [
    'borrador',
    'cotizacion',
    'enviado',
    'facturado',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _numFacturaCtrl = TextEditingController(
      text: widget.pedido.numFactura ?? '',
    );
    _comentarioCtrl = TextEditingController(
      text: widget.pedido.comentario ?? '',
    );
    _notaProduccionCtrl = TextEditingController(
      text: widget.pedido.notaProduccion ?? '',
    );

    _estadoSeleccionado = widget.pedido.estado.toLowerCase();
    if (!_estadosDisponibles.contains(_estadoSeleccionado)) {
      _estadoSeleccionado = 'borrador';
    }

    _clienteId = widget.pedido.clienteId;
    _rutaId = widget.pedido.rutaId;
    _vendedorId = widget.pedido.vendedorId;
    _fechaEntrega = widget.pedido.fechaEntrega;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedhouseClienteProvider>().fetchClientes();
      context.read<RutaProvider>().fetchRutas();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _numFacturaCtrl.dispose();
    _comentarioCtrl.dispose();
    _notaProduccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectFechaEntrega() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.darkCardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _fechaEntrega = picked);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PedidoProvider>();
    final messenger = ScaffoldMessenger.of(context);
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
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Pedido actualizado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final err = provider.error ?? 'Error al actualizar el pedido';
        throw Exception(err);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generarPdf() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando Factura...')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text(
            'Eliminar Pedido',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          content: Text(
            '¿Estás seguro de eliminar el pedido #${widget.pedido.id}? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<PedidoProvider>();
                final success = await provider.deletePedido(widget.pedido.id);
                if (success && mounted) {
                  Navigator.pop(context);
                  widget.onUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${provider.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'borrador':
        return const Color(0xFFFF9800);
      case 'cotizacion':
        return const Color(0xFF9C27B0);
      case 'enviado':
        return const Color(0xFF2196F3);
      case 'facturado':
        return const Color(0xFF4CAF50);
      case 'cancelado':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final estadoColor = _getEstadoColor(_estadoSeleccionado);
    final fechaCreacion = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(widget.pedido.createdAt);

    return Dialog(
      backgroundColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.darkBorderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.15),
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
                                color: Colors.white,
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
                                color: estadoColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: estadoColor,
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
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.pedido.clienteNombre ?? 'Cliente sin nombre'} • Vendedor: ${widget.pedido.vendedorNombre ?? '-'} • $fechaCreacion',
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
                          color: AppTheme.darkInputColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.darkBorderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                'Total Pedido',
                                _currencyFmt.format(widget.pedido.total),
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
                                'Productos',
                                '${widget.pedido.detalles.length} ítem(s)',
                                Colors.white70,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: AppTheme.darkBorderColor,
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
                                    ? const Color(0xFF60A5FA)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── SECCIÓN 1: INFORMACIÓN PRINCIPAL (EDITABLE) ──
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: AppTheme.primaryBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Información Principal (Editable)',
                            style: TextStyle(
                              color: Colors.white,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Estado del Pedido:'),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkInputColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: estadoColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _estadoSeleccionado,
                                      dropdownColor: AppTheme.darkCardColor,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: estadoColor,
                                        size: 20,
                                      ),
                                      items: _estadosDisponibles.map((e) {
                                        final col = _getEstadoColor(e);
                                        return DropdownMenuItem(
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
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _estadoSeleccionado = val,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // No. Factura
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('No. Factura:'),
                                SizedBox(
                                  height: 40,
                                  child: TextFormField(
                                    controller: _numFacturaCtrl,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ej. B0100000045 (opcional)',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.receipt_long_rounded,
                                        size: 16,
                                        color: Color(0xFF60A5FA),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.darkInputColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppTheme.darkBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Campos: Cliente & Ruta
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cliente
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Cliente:'),
                                Consumer<LedhouseClienteProvider>(
                                  builder: (context, clienteProv, _) {
                                    final clientes = clienteProv.clientes;
                                    final tieneActual = clientes.any(
                                      (c) => c.id == _clienteId,
                                    );

                                    return Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkInputColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.darkBorderColor,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: tieneActual
                                              ? _clienteId
                                              : null,
                                          hint: Text(
                                            widget.pedido.clienteNombre ??
                                                'Seleccionar cliente',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          dropdownColor: AppTheme.darkCardColor,
                                          isExpanded: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          items: clientes.map((c) {
                                            return DropdownMenuItem<int>(
                                              value: c.id,
                                              child: Text(
                                                c.nombre,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _clienteId = val);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Ruta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Ruta de Entrega:'),
                                Consumer<RutaProvider>(
                                  builder: (context, rutaProv, _) {
                                    final rutas = rutaProv.rutas;
                                    final tieneActual = rutas.any(
                                      (r) => r.id == _rutaId,
                                    );

                                    return Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkInputColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.darkBorderColor,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int?>(
                                          value: tieneActual ? _rutaId : null,
                                          hint: Text(
                                            widget.pedido.rutaNombre ??
                                                'Sin ruta asignada',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          dropdownColor: AppTheme.darkCardColor,
                                          isExpanded: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          items: [
                                            const DropdownMenuItem<int?>(
                                              value: null,
                                              child: Text(
                                                '-- Sin ruta asignada --',
                                                style: TextStyle(
                                                  color: Colors.grey,
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
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (val) {
                                            setState(() => _rutaId = val);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Vendedor Asignado:'),
                                Consumer<UsersProvider>(
                                  builder: (context, userProv, _) {
                                    final users = userProv.users;
                                    final tieneActual = users.any(
                                      (u) => u['id'] == _vendedorId,
                                    );

                                    return Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkInputColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.darkBorderColor,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: tieneActual
                                              ? _vendedorId
                                              : null,
                                          hint: Text(
                                            widget.pedido.vendedorNombre ??
                                                'Seleccionar vendedor',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          dropdownColor: AppTheme.darkCardColor,
                                          isExpanded: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          items: users.map((u) {
                                            final id = u['id'] as int;
                                            final name =
                                                u['name'] ?? 'Usuario #$id';
                                            return DropdownMenuItem<int>(
                                              value: id,
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _vendedorId = val);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Fecha de Entrega
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Fecha de Entrega Estimada:'),
                                InkWell(
                                  onTap: _selectFechaEntrega,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.darkInputColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.darkBorderColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 15,
                                          color: Colors.amberAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _fechaEntrega != null
                                                ? DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(_fechaEntrega!)
                                                : 'Sin fecha de entrega',
                                            style: TextStyle(
                                              color: _fechaEntrega != null
                                                  ? Colors.white
                                                  : Colors.grey.shade400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (_fechaEntrega != null)
                                          GestureDetector(
                                            onTap: () => setState(
                                              () => _fechaEntrega = null,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Comentarios
                      _buildFieldLabel(
                        'Comentarios / Observaciones del Pedido:',
                      ),
                      TextFormField(
                        controller: _comentarioCtrl,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Detalles u observaciones del cliente...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                          filled: true,
                          fillColor: AppTheme.darkInputColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.darkBorderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Nota de Producción
                      _buildFieldLabel('Nota para Producción:'),
                      TextFormField(
                        controller: _notaProduccionCtrl,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Instrucciones para planta o despacho...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                          filled: true,
                          fillColor: AppTheme.darkInputColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.darkBorderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── SECCIÓN 2: PRODUCTOS (SOLO LECTURA) ──
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.amberAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Productos del Pedido',
                            style: TextStyle(
                              color: Colors.white,
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
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 11,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Solo Lectura',
                                  style: TextStyle(
                                    color: Colors.amber,
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
                          color: AppTheme.darkInputColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.darkBorderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(4),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: AppTheme.darkInputColor,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.darkBorderColor,
                                    ),
                                  ),
                                ),
                                children: [
                                  _buildTableHeaderCell('PRODUCTO'),
                                  _buildTableHeaderCell(
                                    'CANTIDAD',
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
                                return TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppTheme.darkBorderColor
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            det.productoNombre ??
                                                'Producto #${det.productoId}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (det.productoCodigo != null &&
                                              det.productoCodigo!.isNotEmpty)
                                            Text(
                                              'Cód: ${det.productoCodigo}',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
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
                                                color: Colors.amberAccent,
                                                fontSize: 10,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        '${det.cantidad.toStringAsFixed(det.cantidad % 1 == 0 ? 0 : 2)}${det.productoUnidad != null && det.productoUnidad!.trim().isNotEmpty ? ' ${det.productoUnidad!.trim()}' : ''}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        _currencyFmt.format(det.precioUnitario),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        _currencyFmt.format(det.subtotal),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* Los productos, cantidades y precios no se modifican desde este formulario para resguardar la consistencia contable y de inventario.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
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
                  if (isAdmin)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent.shade100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onPressed: _isSaving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text(
                        'Eliminar Pedido',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSaving ? null : _guardarCambios,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                          ),
                    label: Text(
                      _isSaving ? 'Guardando...' : 'Guardar y Actualizar',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(
    String text, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
