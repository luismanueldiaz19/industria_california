import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

enum CompactSnackBarType { success, error, info, warning }

/// Notificación compacta estilo Toast superior para reemplazar los banners
/// gigantes predeterminados. Diseñado según las guías de compactación UI.
class CompactSnackBar extends StatelessWidget {
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

  const CompactSnackBar.success({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = Icons.check_circle_rounded,
       backgroundColor = const Color(0xFF16A34A), // Verde esmeralda moderno
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.success;

  const CompactSnackBar.error({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = Icons.error_outline_rounded,
       backgroundColor = const Color(0xFFDC2626), // Rojo carmesí
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.error;

  const CompactSnackBar.info({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = Icons.info_outline_rounded,
       backgroundColor = const Color(0xFF2563EB), // Azul vibrante
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.info;

  const CompactSnackBar.warning({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  }) : icon = Icons.warning_amber_rounded,
       backgroundColor = const Color(0xFFD97706), // Ámbar / naranja
       iconColor = Colors.white,
       textColor = Colors.white,
       type = CompactSnackBarType.warning;

  // ── Métodos estáticos de conveniencia ─────────────────────────────────

  /// Muestra un snackbar de éxito compacto en el Overlay superior
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _show(
      context,
      CompactSnackBar.success(message: message, title: title),
      duration: duration,
    );
  }

  /// Muestra un snackbar de error compacto en el Overlay superior
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    _show(
      context,
      CompactSnackBar.error(message: message, title: title),
      duration: duration,
    );
  }

  /// Muestra un snackbar informativo compacto en el Overlay superior
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _show(
      context,
      CompactSnackBar.info(message: message, title: title),
      duration: duration,
    );
  }

  /// Muestra un snackbar de advertencia compacto en el Overlay superior
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    _show(
      context,
      CompactSnackBar.warning(message: message, title: title),
      duration: duration,
    );
  }

  /// Método genérico para mostrar cualquier widget en el Overlay superior con animación rápida
  static void _show(
    BuildContext context,
    Widget child, {
    Duration duration = const Duration(milliseconds: 320),
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    showTopSnackBar(
      overlay,
      child,
      displayDuration: duration,
      animationDuration: const Duration(milliseconds: 320),
      reverseAnimationDuration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 420,
          minWidth: 260,
          minHeight: 38,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
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
