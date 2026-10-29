import '../../../core/services/http_service.dart';
import '../models/empleado.dart';

class EmpleadoService {
  final HttpService _http = HttpService();
  static const String _base = 'empleados';

  Future<List<Empleado>> getEmpleados({String? estado, String? departamento, String? search}) async {
    final params = {
      if (estado != null && estado != 'todos') 'estado': estado,
      if (departamento != null && departamento != 'todos') 'departamento': departamento,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await _http.getV2(_base, params: params);
    final List data = response is List ? response : [];
    return data.map((e) => Empleado.fromJson(e)).toList();
  }

  Future<Empleado> createEmpleado(Map<String, dynamic> data) async {
    final response = await _http.postV2(_base, data);
    return Empleado.fromJson(response);
  }

  Future<Empleado> updateEmpleado(int id, Map<String, dynamic> data) async {
    final response = await _http.putV2('$_base/$id', data);
    return Empleado.fromJson(response);
  }

  Future<void> deleteEmpleado(int id) async {
    await _http.deleteV2('$_base/$id');
  }

  Future<Map<String, dynamic>> getResumen() async {
    final response = await _http.getV2('$_base/resumen');
    return response as Map<String, dynamic>;
  }

  Future<List<Empleado>> getActivosParaNomina() async {
    final response = await _http.getV2('$_base/activos-para-nomina');
    final List data = response is List ? response : [];
    return data.map((e) => Empleado.fromJson(e)).toList();
  }
}
