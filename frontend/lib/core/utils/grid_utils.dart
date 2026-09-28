import 'package:flutter/widgets.dart';

class GridUtils {
  /// Devuelve la cantidad de columnas (crossAxisCount) basadas en el ancho de la pantalla
  static int getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 1400) {
      return 5;
    } else if (width > 1100) {
      return 4;
    } else if (width > 700) {
      return 3;
    } else {
      return 2;
    }
  }
}
