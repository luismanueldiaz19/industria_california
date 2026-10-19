import 'package:flutter/material.dart';

/// Wrapper para centrar y limitar el ancho en pantallas grandes,
/// proporcionando una experiencia nativa de smartphone para los choferes en cabina.
class ChoferMobileWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color backgroundColor;

  const ChoferMobileWrapper({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.backgroundColor = const Color(0xFFF5F7FA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width > maxWidth ? 16 : 0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
