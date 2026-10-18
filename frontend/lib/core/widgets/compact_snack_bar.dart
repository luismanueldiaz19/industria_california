import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

enum CompactSnackBarType { success, error, info, warning }

/// Notificación compacta estilo Toast superior para reemplazar los banners
/// gigantes predeterminados. Diseñado según las guías de compactación UI.
/// Todos los tiempos, animaciones y dimensiones se controlan centralizadamente desde aquí.
class CompactSnackBar extends StatelessWidget {
  // ── Parámetros y Tiempos Centralizados ────────────────────────────────
  /// Duración por defecto para notificaciones de éxito
  static Duration successDuration = const Duration(milliseconds: 320);

  /// Duración por defecto para notificaciones de error
  static Duration errorDuration = const Duration(milliseconds: 320);

  /// Duración por defecto para notificaciones informativas
  static Duration infoDuration = const Duration(milliseconds: 320);

  /// Duración por defecto para notificaciones de advertencia
  static Duration warningDuration = const Duration(milliseconds: 320);

  /// Duración de la animación de entrada
  static Duration animationDuration = const Duration(milliseconds: 320);

  /// Duración de la animación de salida
  static Duration reverseAnimationDuration = const Duration(milliseconds: 240);

  /// Curva de animación de entrada
  static Curve animationCurve = Curves.easeOutCubic;

  /// Curva de animación de salida
  static Curve reverseAnimationCurve = Curves.easeInCubic;

  /// Padding superior respecto a la pantalla
  static EdgeInsets padding = const EdgeInsets.only(
    top: 12,
    left: 16,
    right: 16,
  );

  /// Ancho máximo de la píldora compacta
  static double maxWidth = 420;

  /// Ancho mínimo de la píldora compacta
  static double minWidth = 260;

  /// Altura mínima
  static double minHeight = 38;

  /// Radio de bordes
  static BorderRadius borderRadius = BorderRadius.circular(8);

  /// Colores centralizados
  static Color successBackgroundColor = const Color(
    0xFF16A34A,
  ); // Verde esmeralda moderno
  static Color errorBackgroundColor = const Color(0xFFDC2626); // Rojo carmesí
  static Color infoBackgroundColor = const Color(0xFF2563EB); // Azul vibrante
  static Color warningBackgroundColor = const Color(
    0xFFD97706,
  ); // Ámbar / naranja

  /// Iconos centralizados
  static IconData successIcon = Icons.check_circle_rounded;
  static IconData errorIcon = Icons.error_outline_rounded;
  static IconData infoIcon = Icons.info_outline_rounded;
  static IconData warningIcon = Icons.warning_amber_rounded;

  final String message;
  final String? title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onClose;
  final CompactSnackBarType type;

  const CompactSnackBar({
    super.key,
    required this.message,
    this.title,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.onClose,
    this.type = CompactSnackBarType.info,
  });

  CompactSnackBar.success({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = successIcon,
       backgroundColor = successBackgroundColor,
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.success;

  CompactSnackBar.error({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = errorIcon,
       backgroundColor = errorBackgroundColor,
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.error;

  CompactSnackBar.info({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = infoIcon,
       backgroundColor = infoBackgroundColor,
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.info;

  CompactSnackBar.warning({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = warningIcon,
       backgroundColor = warningBackgroundColor,
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.warning;

  // ── Métodos estáticos de conveniencia ─────────────────────────────────

  /// Muestra un snackbar de éxito compacto en el Overlay superior
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    _show(
      context,
      CompactSnackBar.success(message: message, title: title, onClose: onClose),
      duration: duration ?? successDuration,
    );
  }

  /// Muestra un snackbar de error compacto en el Overlay superior
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    _show(
      context,
      CompactSnackBar.error(message: message, title: title, onClose: onClose),
      duration: duration ?? errorDuration,
    );
  }

  /// Muestra un snackbar informativo compacto en el Overlay superior
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    _show(
      context,
      CompactSnackBar.info(message: message, title: title, onClose: onClose),
      duration: duration ?? infoDuration,
    );
  }

  /// Muestra un snackbar de advertencia compacto en el Overlay superior
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    _show(
      context,
      CompactSnackBar.warning(message: message, title: title, onClose: onClose),
      duration: duration ?? warningDuration,
    );
  }

  /// Muestra un snackbar según el tipo especificado
  static void show(
    BuildContext context,
    String message, {
    String? title,
    CompactSnackBarType type = CompactSnackBarType.info,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    switch (type) {
      case CompactSnackBarType.success:
        showSuccess(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        break;
      case CompactSnackBarType.error:
        showError(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        break;
      case CompactSnackBarType.warning:
        showWarning(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        break;
      case CompactSnackBarType.info:
        showInfo(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        break;
    }
  }

  /// Infiere automáticamente el tipo según el color de fondo o el mensaje recibido
  static void showWithColor(
    BuildContext context,
    String message, {
    String? title,
    Color? backgroundColor,
    Duration? duration,
    VoidCallback? onClose,
  }) {
    if (backgroundColor != null) {
      final val = backgroundColor.toARGB32();
      if (val == Colors.green.toARGB32() ||
          val == Colors.greenAccent.toARGB32() ||
          val == 0xFF16A34A ||
          val == 0xFF4CAF50 ||
          val == 0xFF2E7D32) {
        showSuccess(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        return;
      }
      if (val == Colors.red.toARGB32() ||
          val == Colors.redAccent.toARGB32() ||
          val == 0xFFDC2626 ||
          val == 0xFFE53935 ||
          val == 0xFFD32F2F) {
        showError(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        return;
      }
      if (val == Colors.orange.toARGB32() ||
          val == Colors.orangeAccent.toARGB32() ||
          val == Colors.amber.toARGB32() ||
          val == Colors.amberAccent.toARGB32() ||
          val == 0xFFD97706) {
        showWarning(
          context,
          message,
          title: title,
          duration: duration,
          onClose: onClose,
        );
        return;
      }
    }

    final lower = message.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('falló') ||
        lower.contains('fallo') ||
        lower.contains('no se pudo') ||
        lower.contains('incorrecta') ||
        lower.contains('no coinciden') ||
        lower.contains('requerido')) {
      showError(
        context,
        message,
        title: title,
        duration: duration,
        onClose: onClose,
      );
    } else if (lower.contains('éxito') ||
        lower.contains('exito') ||
        lower.contains('correctamente') ||
        lower.contains('guardad') ||
        lower.contains('cread') ||
        lower.contains('actualizad') ||
        lower.contains('eliminad') ||
        lower.contains('asignad') ||
        lower.contains('enviad')) {
      showSuccess(
        context,
        message,
        title: title,
        duration: duration,
        onClose: onClose,
      );
    } else {
      showInfo(
        context,
        message,
        title: title,
        duration: duration,
        onClose: onClose,
      );
    }
  }

  /// Método genérico para mostrar cualquier widget en el Overlay superior con animación rápida
  static void _show(
    BuildContext context,
    Widget child, {
    required Duration duration,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    showTopSnackBar(
      overlay,
      child,
      displayDuration: duration,
      animationDuration: animationDuration,
      reverseAnimationDuration: reverseAnimationDuration,
      curve: animationCurve,
      reverseCurve: reverseAnimationCurve,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minWidth: minWidth,
          minHeight: minHeight,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: title != null && title!.isNotEmpty
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.95),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(
                          message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        color: textColor.withValues(alpha: 0.75),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
