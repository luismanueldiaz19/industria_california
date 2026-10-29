import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/compact_snack_bar.dart';
import '../services/nomina_service.dart';

/// Helper centralizado para emitir documentos de nómina con rutas seguras encriptadas
/// mediante el mecanismo de tokens opacos (/d/{token}), idéntico al módulo de Pedidos.
class NominaReportHelper {
  static final NominaService _service = NominaService();

  static Future<void> _abrirTokenReporte(
    BuildContext context, {
    required String tipo,
    int? nominaId,
    int? detalleId,
    String modo = 'blade',
    String? mensaje,
  }) async {
    try {
      final urlStr = await _service.getTokenReporteUrl(
        tipo: tipo,
        nominaId: nominaId,
        detalleId: detalleId,
        modo: modo,
      );
      final uri = Uri.parse(urlStr);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (context.mounted) {
          CompactSnackBar.showError(context, 'No se pudo abrir el documento');
        }
      } else if (mensaje != null && context.mounted) {
        CompactSnackBar.showSuccess(context, mensaje);
      }
    } catch (e) {
      if (context.mounted) {
        CompactSnackBar.showError(context, 'Error al generar documento seguro: $e');
      }
    }
  }

  /// 🖨️ Abre los volantes de pago de la nómina con token encriptado
  static Future<void> abrirTodosLosVolantes(
    BuildContext context,
    int nominaId,
  ) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_volantes',
      nominaId: nominaId,
      modo: 'blade',
      mensaje: 'Generando enlace seguro para volantes de nómina...',
    );
  }

  /// 🎫 Abre el volante individual de un colaborador con token encriptado
  static Future<void> abrirVolanteIndividual(
    BuildContext context,
    int nominaId,
    int detalleId,
  ) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_volantes',
      nominaId: nominaId,
      detalleId: detalleId,
      modo: 'blade',
      mensaje: 'Generando volante seguro del colaborador...',
    );
  }

  /// ⬇️ Descarga el archivo PDF con todos los volantes con token encriptado
  static Future<void> descargarPdfVolantes(
    BuildContext context,
    int nominaId,
  ) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_volantes',
      nominaId: nominaId,
      modo: 'pdf',
      mensaje: 'Generando descarga segura de PDF de volantes...',
    );
  }

  /// 📄 Abre el reporte general apaisado de nómina con token encriptado
  static Future<void> abrirReporteGeneral(
    BuildContext context,
    int nominaId,
  ) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_general',
      nominaId: nominaId,
      modo: 'blade',
      mensaje: 'Generando enlace seguro para reporte general...',
    );
  }

  /// ⬇️ Descarga el reporte general en PDF con token encriptado
  static Future<void> descargarPdfGeneral(
    BuildContext context,
    int nominaId,
  ) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_general',
      nominaId: nominaId,
      modo: 'pdf',
      mensaje: 'Generando descarga segura de PDF de nómina general...',
    );
  }

  /// 📊 Descarga el archivo Excel estructurado (.xlsx) con token encriptado
  static Future<void> descargarExcelGeneral(
    BuildContext context,
    int nominaId,
  ) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_general',
      nominaId: nominaId,
      modo: 'excel',
      mensaje: 'Generando descarga segura de Excel de nómina...',
    );
  }

  /// 💼 Abre el reporte de cartera de préstamos y descuentos con token encriptado
  static Future<void> abrirReporteRecurrentes(BuildContext context) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_recurrentes',
      modo: 'blade',
      mensaje: 'Generando enlace seguro para cartera de préstamos...',
    );
  }

  /// ⬇️ Descarga el reporte de cartera en PDF con token encriptado
  static Future<void> descargarPdfRecurrentes(BuildContext context) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_recurrentes',
      modo: 'pdf',
      mensaje: 'Generando descarga segura de PDF de cartera...',
    );
  }

  /// 📊 Descarga la cartera de préstamos en Excel (.xlsx) con token encriptado
  static Future<void> descargarExcelRecurrentes(BuildContext context) {
    return _abrirTokenReporte(
      context,
      tipo: 'nomina_recurrentes',
      modo: 'excel',
      mensaje: 'Generando descarga segura de Excel de cartera...',
    );
  }
}
