import 'package:flutter/material.dart';
import 'cancel_button.dart';

enum ConfirmType {
  danger,
  warning,
  info,
  success,
}

/// Diálogo de confirmación moderno, estandarizado y responsivo para Industria California.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? confirmIcon;
  final ConfirmType type;
  final Widget? content;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isLoading;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmIcon,
    this.type = ConfirmType.warning,
    this.content,
    this.onConfirm,
    this.onCancel,
    this.isLoading = false,
  });

  /// Método estático para invocar el diálogo de confirmación fácilmente
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData? confirmIcon,
    ConfirmType type = ConfirmType.warning,
    Widget? content,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmIcon: confirmIcon,
        type: type,
        content: content,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color lightBgColor;
    Color borderColor;
    IconData defaultIcon;

    switch (type) {
      case ConfirmType.danger:
        primaryColor = const Color(0xFFDC2626);
        lightBgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFECACA);
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case ConfirmType.warning:
        primaryColor = const Color(0xFFD97706);
        lightBgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        defaultIcon = Icons.help_outline_rounded;
        break;
      case ConfirmType.info:
        primaryColor = const Color(0xFF2563EB);
        lightBgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFBFDBFE);
        defaultIcon = Icons.info_outline_rounded;
        break;
      case ConfirmType.success:
        primaryColor = const Color(0xFF16A34A);
        lightBgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFFBBF7D0);
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
    }

    final actionIcon = confirmIcon ?? defaultIcon;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera con Icono y Título ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: lightBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Icon(defaultIcon, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Contenido Opcional (Campos de entrada, advertencias adicionales) ──
              if (content != null) ...[
                const SizedBox(height: 16),
                content!,
              ],

              const SizedBox(height: 20),

              // ── Barra de Acciones ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CancelButton(
                    text: cancelText,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    onPressed: onCancel ?? () => Navigator.pop(context, false),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : (onConfirm ?? () => Navigator.pop(context, true)),
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(actionIcon, size: 14),
                    label: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(64, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

