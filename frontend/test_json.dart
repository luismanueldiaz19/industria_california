import 'dart:convert';
import 'package:industria_california/modules/flota/models/vehiculo_mantenimiento.dart';

void main() {
  final jsonString = '{"id":2,"vehiculo_id":1,"tipo":"preventivo","fecha_reporte":"2026-09-25T20:16:57.000000Z","descripcion":"Goma","costo":"35000.00","estado":"en_proceso","evidencias":null,"reportado_por":1,"created_at":"2026-09-25T20:16:57.000000Z","updated_at":"2026-09-25T20:57:35.000000Z","reportador":{"id":1,"name":"Lwader Soft S.R.L"}}';
  
  try {
    final Map<String, dynamic> data = json.decode(jsonString);
    final obj = VehiculoMantenimiento.fromJson(data);
    print("Success: \${obj.id}");
  } catch (e, stack) {
    print("Error: \$e");
    print(stack);
  }
}
