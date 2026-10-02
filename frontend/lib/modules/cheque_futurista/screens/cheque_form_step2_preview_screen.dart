import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cheque_form_provider.dart';
import '../services/cheque_futurista_service.dart';
import '../../../core/utils/formatters.dart';

/// Paso 2: Preview / Confirmación del cheque antes de enviar a la API.
/// Muestra todos los datos ingresados en una tarjeta resumen con el payload
/// exacto que se enviará, y permite confirmar o volver a editar.
class ChequeFormStep2PreviewScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const ChequeFormStep2PreviewScreen({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<ChequeFormStep2PreviewScreen> createState() =>
      _ChequeFormStep2PreviewScreenState();
}

class _ChequeFormStep2PreviewScreenState
    extends State<ChequeFormStep2PreviewScreen> {
  static const _red = Color(0xFFB71C1C);
  static const _redDark = Color(0xFF7F0000);

  bool _isSending = false;
  bool _isUploadingFiles = false;
  double _uploadProgress = 0.0;

  Future<void> _confirmar() async {
    final form = context.read<ChequeFormProvider>();
    final auth = context.read<AuthProvider>();
    final payload = form.toPayload(auth.id!);
    final service = ChequeFuturistaService();

    setState(() {
      _isSending = true;
      _isUploadingFiles = false;
    });

    try {
      // PASO 1 - Crear Cheque en BD
      final cheque = await service.crear(payload);
      final chequeId = cheque['id'];

      // PASO 2 - Subir archivos (si hay)
      if (form.archivos.isNotEmpty) {
        setState(() {
          _isUploadingFiles = true;
          _uploadProgress = 0.0;
        });

        final totalArchivos = form.archivos.length;
        int subidos = 0;

        for (final archivo in form.archivos) {
          await service.subirDocumento(chequeId, archivo);
          subidos++;
          if (mounted) {
            setState(() {
              _uploadProgress = subidos / totalArchivos;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isSending = false;
          _isUploadingFiles = false;
        });
        _mostrarExito(payload);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isUploadingFiles = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarExito(Map<String, dynamic> payload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Cheque Registrado!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'El cheque futurista fue guardado\nexitosamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ChequeFormProvider>().reset(); // Limpiar formulario
              Navigator.of(context).pop(); // cierra dialog
              widget.onSuccess();
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ChequeFormProvider>();
    final auth = context.watch<AuthProvider>();
    final estadoColor = _colorEstado(form.estado);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado de confirmación ────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F0000), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Cheque',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Verifica que todo esté correcto',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tarjeta de datos ──────────────────────────────
          _previewCard(
            children: [
              _previewRow(
                icon: Icons.person_outline,
                label: 'Cliente',
                value: form.cliente?.nombre ?? '—',
                highlight: true,
              ),
              const Divider(height: 1),
              _previewRow(
                icon: Icons.badge_outlined,
                label: 'Vendedor',
                value: auth.name ?? auth.username ?? '—',
                highlight: true,
              ),
              _previewRow(
                icon: Icons.numbers,
                label: 'N° Cheque',
                value: form.numCheque,
                highlight: true,
              ),
              const Divider(height: 1),
              _previewRow(
                icon: Icons.tag,
                label: 'N° Pedido',
                value: form.numPedido.isEmpty ? 'Sin número' : form.numPedido,
                muted: form.numPedido.isEmpty,
              ),
              const Divider(height: 1),
              _previewRow(
                icon: Icons.attach_money,
                label: 'Monto',
                value: Formatters.formatCurrency(form.monto),
                highlight: true,
              ),
              const Divider(height: 1),
              _previewRow(
                icon: Icons.flag_outlined,
                label: 'Estado',
                valueWidget: _estadoBadge(form.estado, estadoColor),
              ),
              if (form.comentario.trim().isNotEmpty) ...[
                const Divider(height: 1),
                _previewRow(
                  icon: Icons.comment_outlined,
                  label: 'Comentario',
                  value: form.comentario,
                ),
              ],
              if (form.archivos.isNotEmpty) ...[
                const Divider(height: 1),
                _previewRow(
                  icon: Icons.attach_file,
                  label: 'Documentos',
                  value: '${form.archivos.length} archivo(s) adjunto(s)',
                  highlight: true,
                ),
              ],
            ],
          ),

          const SizedBox(height: 32),

          // ── Botones de acción / Cargando ─────────────────────────────
          if (_isUploadingFiles)
            _buildUploadProgress()
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSending ? null : widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFB71C1C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16, color: _red),
                    label: const Text(
                      'Editar',
                      style: TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isSending ? 'Guardando...' : 'Confirmar y Guardar',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _previewCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _previewRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
    bool highlight = false,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (valueWidget != null)
            valueWidget
          else
            Flexible(
              child: Text(
                value ?? '—',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  color: muted ? Colors.grey.shade400 : const Color(0xFF1E2F4C),
                  fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado, Color color) {
    final labels = {
      'pendiente': 'Pendiente',
      'depositado': 'Depositado',
      'cancelado': 'Cancelado',
      'vencido': 'Vencido',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        labels[estado] ?? estado,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _colorEstado(String estado) {
    return switch (estado) {
      'pendiente' => const Color(0xFFFF9800),
      'depositado' => const Color(0xFF4CAF50),
      'cancelado' => Colors.grey,
      'vencido' => const Color(0xFFB71C1C),
      _ => Colors.grey,
    };
  }

  Widget _buildUploadProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Subiendo documentos...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _red,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: _red.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(_red),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
