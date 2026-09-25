import '../../../core/services/http_service.dart';
import '../models/vehiculo.dart';
import '../models/vehiculo_mantenimiento.dart';
import '../models/vehiculo_gasto.dart';
import '../models/tipo_gasto.dart';

class VehiculoService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/vehiculos';

  // CRUD Vehiculos
  Future<List<Vehiculo>> getVehiculos() async {
    final response = await _http.get(_base);
    final List data = response is List ? response : [];
    return data.map((json) => Vehiculo.fromJson(json)).toList();
  }

  Future<Vehiculo> getVehiculo(int id) async {
    final response = await _http.get('$_base/$id');
    return Vehiculo.fromJson(response);
  }

  Future<Vehiculo> createVehiculo(Map<String, dynamic> data) async {
    final response = await _http.post(_base, data);
    return Vehiculo.fromJson(response);
  }

  Future<Vehiculo> updateVehiculo(int id, Map<String, dynamic> data) async {
    final response = await _http.put('$_base/$id', data);
    return Vehiculo.fromJson(response);
  }

  Future<void> deleteVehiculo(int id) async {
    await _http.delete('$_base/$id');
  }

  Future<Map<String, dynamic>> getResumen() async {
    final response = await _http.get('$_base/resumen');
    return response as Map<String, dynamic>;
  }

  // Mantenimientos
  Future<List<VehiculoMantenimiento>> getMantenimientos(int vehiculoId) async {
    final response = await _http.get('$_base/$vehiculoId/mantenimientos');
    final List data = response is List ? response : [];
    return data.map((json) => VehiculoMantenimiento.fromJson(json)).toList();
  }

  Future<List<VehiculoMantenimiento>> getMantenimientosTodos() async {
    final response = await _http.get('$_base/mantenimientos/todos');
    final List data = response is List ? response : [];
    return data.map((json) => VehiculoMantenimiento.fromJson(json)).toList();
  }

  Future<String> getMantenimientosPdfUrl(
    Map<String, dynamic> queryParams,
  ) async {
    final Map<String, String> stringParams = {};
    queryParams.forEach((key, value) {
      if (value != null) {
        stringParams[key] = value.toString();
      }
    });

    final response = await _http.get(
      '$_base/mantenimientos/pdf-url',
      params: stringParams,
    );
    return response['url'];
  }

  Future<VehiculoMantenimiento> createMantenimiento(
    int vehiculoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.post(
      '$_base/$vehiculoId/mantenimientos',
      data,
    );
    return VehiculoMantenimiento.fromJson(response);
  }

  Future<VehiculoMantenimiento> updateMantenimiento(
    int vehiculoId,
    int mantenimientoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.patch(
      '$_base/$vehiculoId/mantenimientos/$mantenimientoId',
      data,
    );
    return VehiculoMantenimiento.fromJson(response);
  }

  Future<void> deleteMantenimiento(int vehiculoId, int mantenimientoId) async {
    await _http.delete('$_base/$vehiculoId/mantenimientos/$mantenimientoId');
  }

  // Gastos
  Future<List<VehiculoGasto>> getGastosTodos() async {
    final response = await _http.get('$_base/gastos/todos');
    final List data = response is List ? response : [];
    return data.map((json) => VehiculoGasto.fromJson(json)).toList();
  }

  Future<String> getGastosPdfUrl(
    Map<String, dynamic> queryParams,
  ) async {
    final Map<String, String> stringParams = {};
    queryParams.forEach((key, value) {
      if (value != null) {
        stringParams[key] = value.toString();
      }
    });

    final response = await _http.get(
      '$_base/gastos/pdf-url',
      params: stringParams,
    );
    return response['url'];
  }

  Future<List<VehiculoGasto>> getGastos(int vehiculoId) async {
    final response = await _http.get('$_base/$vehiculoId/gastos');
    final List data = response is List ? response : [];
    return data.map((json) => VehiculoGasto.fromJson(json)).toList();
  }

  Future<VehiculoGasto> createGasto(
    int vehiculoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.post('$_base/$vehiculoId/gastos', data);
    return VehiculoGasto.fromJson(response);
  }

  Future<VehiculoGasto> updateGasto(
    int vehiculoId,
    int gastoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.patch(
      '$_base/$vehiculoId/gastos/$gastoId',
      data,
    );
    return VehiculoGasto.fromJson(response);
  }

  Future<void> deleteGasto(int vehiculoId, int gastoId) async {
    await _http.delete('$_base/$vehiculoId/gastos/$gastoId');
  }

  // Tipos de Gastos
  Future<List<TipoGasto>> getTipoGastos() async {
    final response = await _http.get('$_base/tipo-gastos');
    final List data = response is List ? response : [];
    return data.map((json) => TipoGasto.fromJson(json)).toList();
  }

  Future<TipoGasto> createTipoGasto(String nombre) async {
    final response = await _http.post('$_base/tipo-gastos', {'nombre': nombre});
    return TipoGasto.fromJson(response);
  }

  Future<TipoGasto> updateTipoGasto(int id, String nombre) async {
    final response = await _http.put('$_base/tipo-gastos/$id', {'nombre': nombre});
    return TipoGasto.fromJson(response);
  }

  Future<void> deleteTipoGasto(int id) async {
    await _http.delete('$_base/tipo-gastos/$id');
  }
}
