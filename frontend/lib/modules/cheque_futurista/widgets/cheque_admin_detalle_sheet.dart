import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cheque_futurista.dart';
import '../providers/cheque_admin_provider.dart';
import '../services/cheque_futurista_service.dart';
import '../utils/cheque_admin_utils.dart';

/// Abre el panel de detalle/evidencias del cheque (modo admin, tema oscuro).
Future<void> showChequeAdminDetalleSheet(
  BuildContext context,
  ChequeFuturista cheque,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 760),
    builder: (_) => ChequeAdminDetalleSheet(chequeId: cheque.id),
  );
}

class ChequeAdminDetalleSheet extends StatefulWidget {
  final int chequeId;
  const ChequeAdminDetalleSheet({super.key, required this.chequeId});

  @override
  State<ChequeAdminDetalleSheet> createState() =>
      _ChequeAdminDetalleSheetState();
}

class _ChequeAdminDetalleSheetState extends State<ChequeAdminDetalleSheet> {
  final _service = ChequeFuturistaService();
  late Future<List<dynamic>> _docsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _docsFuture = _service.obtenerDocumentos(widget.chequeId);
  }

  void _reloadDocs() {
    setState(() {
      _docsFuture = _service.obtenerDocumentos(widget.chequeId);
    });
  }

  ChequeFuturista? _findCheque(ChequeAdminProvider p) {
    for (final c in p.cheques) {
      if (c.id == widget.chequeId) return c;
    }
    return null;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmText,
    Color color = ChequeAdminColors.red,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChequeAdminColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      _snack(okMsg);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Acciones ──────────────────────────────────────────────

  Future<void> _cambiarEstado(ChequeFuturista cheque, ChequeEstadoInfo e) async {
    if (e.value == cheque.estado || _busy) return;
    final ok = await _confirm(
      title: 'Cambiar estado',
      message:
          '¿Cambiar el cheque N° ${cheque.numCheque} de "${cheque.estado.toUpperCase()}" a "${e.label.toUpperCase()}"?',
      confirmText: 'Cambiar',
      color: ChequeAdminUtils.colorEstado(e.value),
    );
    if (!ok || !mounted) return;
    await _run(
      () => context.read<ChequeAdminProvider>().cambiarEstado(cheque, e.value),
      'Estado actualizado a ${e.label}',
    );
  }

  Future<void> _eliminarDocumento(ChequeFuturista cheque, dynamic doc) async {
    final ok = await _confirm(
      title: 'Eliminar evidencia',
      message:
          '¿Eliminar "${doc['nombre_archivo'] ?? 'imagen'}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      await context
          .read<ChequeAdminProvider>()
          .eliminarDocumento(cheque, doc['id'] as int);
      _reloadDocs();
    }, 'Evidencia eliminada');
  }

  Future<void> _subirEvidencia(ChequeFuturista cheque) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null || !mounted) return;
    await _run(() async {
      await _service.subirDocumento(cheque.id, image);
      if (!mounted) return;
      context.read<ChequeAdminProvider>().documentoAgregado(cheque.id);
      _reloadDocs();
    }, 'Evidencia subida correctamente');
  }

  Future<void> _eliminarCheque(ChequeFuturista cheque) async {
    final ok = await _confirm(
      title: 'Eliminar cheque',
      message:
          '¿Eliminar el cheque N° ${cheque.numCheque} de ${cheque.nombreCliente}?\n\nDebe eliminar primero todas sus evidencias.',
      confirmText: 'Eliminar',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<ChequeAdminProvider>().eliminarCheque(cheque);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Cheque eliminado'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _snack(e.toString(), error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  void _verImagen(String url, String? titulo) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.network(
                    url,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white38,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChequeAdminProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final cheque = _findCheque(provider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: ChequeAdminColors.bar,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: cheque == null
          ? const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Cheque no disponible',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          : Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _handle(),
                    _header(cheque),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _alertaBanner(cheque),
                            _infoGrid(cheque),
                            if (cheque.comentario?.isNotEmpty == true)
                              _comentario(cheque.comentario!),
                            const SizedBox(height: 14),
                            _sectionTitle(Icons.swap_horiz, 'Cambiar estado'),
                            const SizedBox(height: 8),
                            _estadoSelector(cheque),
                            const SizedBox(height: 16),
                            _evidenciasSection(cheque, isAdmin),
                          ],
                        ),
                      ),
                    ),
                    _footer(cheque, isAdmin),
                  ],
                ),
                if (_busy)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: ChequeAdminColors.red,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 8),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(ChequeFuturista cheque) {
    final color = ChequeAdminUtils.colorEstado(cheque.estado);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ChequeAdminColors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: ChequeAdminColors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cheque.nombreCliente.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Cheque N° ${cheque.numCheque}  ·  #${cheque.id}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          _estadoBadge(cheque.estado, color),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          estado.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _alertaBanner(ChequeFuturista cheque) {
    final alerta = ChequeAdminUtils.alerta(
      cheque.estado,
      cheque.createdAt,
      cheque.fechaDeposito,
    );
    if (alerta == ChequeAlerta.ninguna) return const SizedBox.shrink();

    final critico = alerta == ChequeAlerta.deposito;
    final color = critico ? Colors.redAccent : Colors.orangeAccent;
    final dias = critico
        ? ChequeAdminUtils.diasDesde(cheque.fechaDeposito)
        : ChequeAdminUtils.diasDesde(cheque.createdAt);
    final texto = critico
        ? 'CRÍTICO: $dias días desde la fecha de depósito y aún sigue pendiente (límite ${ChequeAdminUtils.diasAlertaDeposito} días).'
        : 'SEGUIMIENTO: $dias días desde su registro sin depositar (límite ${ChequeAdminUtils.diasAlertaRegistro} días).';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            critico ? Icons.error_outline : Icons.warning_amber_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(ChequeFuturista cheque) {
    final items = [
      _InfoItem(
        Icons.attach_money,
        'MONTO',
        Formatters.formatCurrency(cheque.monto),
        Colors.greenAccent,
      ),
      _InfoItem(
        Icons.person_outline,
        'VENDEDOR',
        cheque.nombreVendedor ?? 'N/A',
        Colors.white,
      ),
      _InfoItem(
        Icons.history,
        'REGISTRO',
        ChequeAdminUtils.fmt(cheque.createdAt, 'dd/MM/yyyy HH:mm'),
        Colors.white70,
      ),
      _InfoItem(
        Icons.event,
        'DEPÓSITO',
        cheque.fechaDeposito != null
            ? ChequeAdminUtils.fmt(cheque.fechaDeposito)
            : 'No definido',
        cheque.fechaDeposito != null ? Colors.amberAccent : Colors.white38,
      ),
      _InfoItem(
        Icons.receipt_long,
        'N° PEDIDO',
        cheque.numPedido?.isNotEmpty == true ? cheque.numPedido! : '—',
        Colors.white70,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (i) => Container(
              width: 170,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: ChequeAdminColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(i.icon, size: 16, color: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.label,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          i.value,
                          style: TextStyle(
                            color: i.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _comentario(String texto) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ChequeAdminColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes, size: 16, color: Colors.white38),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(IconData icon, String text, {Widget? trailing}) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      );

  Widget _estadoSelector(ChequeFuturista cheque) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ChequeAdminUtils.estados.map((e) {
        final color = ChequeAdminUtils.colorEstado(e.value);
        final selected = cheque.estado == e.value;
        return InkWell(
          onTap: () => _cambiarEstado(cheque, e),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.22)
                  : ChequeAdminColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.3),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : e.icon,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  e.label,
                  style: TextStyle(
                    color: selected ? color : Colors.white70,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _evidenciasSection(ChequeFuturista cheque, bool isAdmin) {
    return FutureBuilder<List<dynamic>>(
      future: _docsFuture,
      builder: (context, snap) {
        final docs = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(
              Icons.photo_library_outlined,
              'Evidencias (${snap.connectionState == ConnectionState.done ? docs.length : '…'})',
              trailing: _smallButton(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Subir',
                color: Colors.greenAccent,
                onTap: _busy ? null : () => _subirEvidencia(cheque),
              ),
            ),
            const SizedBox(height: 8),
            if (snap.connectionState != ConnectionState.done)
              const SizedBox(
                height: 110,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ChequeAdminColors.red,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (docs.isEmpty)
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: ChequeAdminColors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: Colors.white24, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'Sin evidencias adjuntas',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: docs
                    .map((d) => _docTile(cheque, d, isAdmin))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _docTile(ChequeFuturista cheque, dynamic doc, bool isAdmin) {
    final tipo = doc['tipo_archivo']?.toString().toLowerCase();
    final isImage = tipo == 'jpg' || tipo == 'jpeg' || tipo == 'png';
    final url = doc['ruta_archivo'] != null
        ? '$host/storage/${doc['ruta_archivo']}'
        : null;
    final nombre = doc['nombre_archivo']?.toString() ?? 'Documento';
    final fecha = ChequeAdminUtils.fmt(doc['created_at']?.toString());

    return SizedBox(
      width: 130,
      child: Container(
        decoration: BoxDecoration(
          color: ChequeAdminColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                InkWell(
                  onTap: (isImage && url != null)
                      ? () => _verImagen(url, nombre)
                      : null,
                  child: SizedBox(
                    height: 100,
                    child: (isImage && url != null)
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white24,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.insert_drive_file,
                              color: Colors.white38,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Tooltip(
                      message: 'Eliminar evidencia',
                      child: InkWell(
                        onTap: _busy
                            ? null
                            : () => _eliminarDocumento(cheque, doc),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fecha,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(ChequeFuturista cheque, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: ChequeAdminColors.header,
        border: Border(top: BorderSide(color: Colors.black26, width: 2)),
      ),
      child: Row(
        children: [
          if (isAdmin)
            _smallButton(
              icon: Icons.delete_forever_outlined,
              label: 'Eliminar cheque',
              color: Colors.redAccent,
              onTap: _busy ? null : () => _eliminarCheque(cheque),
            ),
          const Spacer(),
          _smallButton(
            icon: Icons.close,
            label: 'Cerrar',
            color: Colors.white54,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoItem(this.icon, this.label, this.value, this.color);
}
