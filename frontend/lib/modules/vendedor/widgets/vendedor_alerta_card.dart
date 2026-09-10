import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants.dart';
import '../models/vendedor_alerta_model.dart';

class CxcEvidencia {
  final int id;
  final String rutaArchivo;
  final String nombreArchivo;

  CxcEvidencia({
    required this.id,
    required this.rutaArchivo,
    required this.nombreArchivo,
  });

  factory CxcEvidencia.fromJson(Map<String, dynamic> json) {
    return CxcEvidencia(
      id: json['id'] ?? 0,
      rutaArchivo: json['ruta_archivo'] ?? '',
      nombreArchivo: json['nombre_archivo'] ?? '',
    );
  }
}

class VendedorAlertaCard extends StatelessWidget {
  final VendedorAlertaModel alerta;
  final VoidCallback? onTap;

  const VendedorAlertaCard({super.key, required this.alerta, this.onTap});

  Color _estadoColor(String estado) {
    if (estado == 'pendiente') return Colors.orange;
    if (estado == 'revisada') return Colors.blue;
    if (estado == 'procesada') return Colors.green;
    return Colors.grey;
  }

  IconData _getIconoPorTipo(String? tipo) {
    switch (tipo) {
      case 'pago_recibido':
        return Icons.monetization_on_rounded;
      case 'informacion':
        return Icons.info_outline_rounded;
      case 'consulta':
        return Icons.help_outline_rounded;
      case 'credito':
      case 'debito':
      case 'retencion':
        return Icons.article_rounded;
      case 'devolucion':
      case 'mer_no_entregada':
        return Icons.inventory_2_rounded;
      case 'anular':
        return Icons.cancel_presentation_rounded;
      case 'diferencia':
        return Icons.balance_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _estadoColor(alerta.estadoAlerta);
    final tipoTexto = alerta.tipo ?? 'Desconocido';
    final monto = alerta.montoInformado;
    final nota = alerta.nota;
    final cliente = alerta.cxc?.cliente?.nombre ?? 'Cliente Desconocido';
    final documento = alerta.cxc?.documento ?? 'Doc Desconocido';

    // Obtenemos evidencias del CXC primero (ya que al subirlas no se les asigna alerta_id) o de la alerta directamente.
    final rawEvidencias = alerta.cxc?.evidencias ?? alerta.evidencias ?? [];
    final List<CxcEvidencia> evidencias = rawEvidencias
        .map((e) => CxcEvidencia.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Accent Bar
              Container(height: 4, color: colorEstado),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconoPorTipo(tipoTexto),
                            color: colorEstado,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                documento,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cliente,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            alerta.estadoAlerta.toUpperCase(),
                            style: TextStyle(
                              color: colorEstado,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Detalles
                    Row(
                      children: [
                        const Icon(
                          Icons.label_important_outline_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tipo: ${tipoTexto.toString().replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),

                    if (monto != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Monto Informado:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$$monto',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (nota != null && nota.toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nota,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    ///backend\storage\app\public\cxc-evidencias
                    if (evidencias.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _EvidenciasDialog(
                                  evidencias: evidencias,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: Text(
                            evidencias.length > 1
                                ? 'Ver Documentos (${evidencias.length})'
                                : 'Ver Documento Adjunto',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy • HH:mm',
                          ).format(alerta.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenciasDialog extends StatelessWidget {
  final List<CxcEvidencia> evidencias;

  const _EvidenciasDialog({required this.evidencias});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            color: Colors.white,
            constraints: const BoxConstraints(maxHeight: 600),
            child: ListView.separated(
              padding: const EdgeInsets.all(20).copyWith(top: 40),
              itemCount: evidencias.length,
              separatorBuilder: (_, __) => const Divider(height: 40),
              itemBuilder: (context, index) {
                final ev = evidencias[index];
                final ruta = ev.rutaArchivo;
                if (ruta.isEmpty) return const SizedBox.shrink();

                // Formamos el URL correcto
                final urlStr = '$host/storage/$ruta';
                final isPdf = ruta.toLowerCase().endsWith('.pdf');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documento ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isPdf)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(urlStr),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          label: const Text('Abrir PDF en el navegador'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Image.network(
                          urlStr,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text('Error al cargar la imagen'),
                                ),
                              ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.8),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
