import 'package:flutter/material.dart';

/// Widget wrapper que centra y limita el ancho para dar apariencia
/// de dispositivo móvil cuando la aplicación se ejecuta en pantallas grandes o escritorio.
class MobileWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color backgroundColor;

  const MobileWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.backgroundColor = const Color(0xFF121212),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: backgroundColor, // Fondo oscuro fuera del área móvil
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ClipRRect(
              // Redondeamos los bordes para dar apariencia de dispositivo móvil si está en escritorio
              borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.width > maxWidth ? 20 : 0,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
