import 'package:flutter/material.dart';

/// Contenedor responsivo y adaptable para tablas ([DataTable], [Table], etc.).
///
/// - En pantallas grandes o con espacio disponible: fuerza a la tabla a ocupar el
///   100% del ancho del contenedor (`minWidth: constraints.maxWidth`), distribuyendo
///   el espacio de forma uniforme sin dejar huecos en blanco.
/// - En pantallas pequeñas: habilita scroll horizontal fluido ([BouncingScrollPhysics])
///   para evitar desbordamientos y mantener la legibilidad.
/// - Incluye scroll vertical integrado y opción para estilizar el efecto hover.
class CustomTableScroll extends StatelessWidget {
  /// Widget de la tabla (usualmente un [DataTable] o [Table]).
  final Widget child;

  /// Si es true, envuelve el contenido en un [SingleChildScrollView] vertical.
  /// Por defecto es `true`.
  final bool isVerticalScrollable;

  /// Física del scroll horizontal.
  final ScrollPhysics horizontalPhysics;

  /// Física del scroll vertical.
  final ScrollPhysics verticalPhysics;

  /// Controlador opcional para el scroll horizontal.
  final ScrollController? horizontalController;

  /// Controlador opcional para el scroll vertical.
  final ScrollController? verticalController;

  /// Color de hover suave para filas de [DataTable]. Por defecto `#F1F5F9`.
  final Color? hoverColor;

  /// Elimina los efectos splash y highlight para una apariencia desktop/web más limpia.
  final bool removeSplashes;

  const CustomTableScroll({
    super.key,
    required this.child,
    this.isVerticalScrollable = true,
    this.horizontalPhysics = const BouncingScrollPhysics(),
    this.verticalPhysics = const BouncingScrollPhysics(),
    this.horizontalController,
    this.verticalController,
    this.hoverColor = const Color(0xFFF1F5F9),
    this.removeSplashes = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (removeSplashes || hoverColor != null) {
      content = Theme(
        data: Theme.of(context).copyWith(
          splashColor: removeSplashes ? Colors.transparent : null,
          highlightColor: removeSplashes ? Colors.transparent : null,
          hoverColor: hoverColor,
        ),
        child: content,
      );
    }

    if (isVerticalScrollable) {
      content = SingleChildScrollView(
        controller: verticalController,
        scrollDirection: Axis.vertical,
        physics: verticalPhysics,
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          physics: horizontalPhysics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: content,
          ),
        );
      },
    );
  }
}
