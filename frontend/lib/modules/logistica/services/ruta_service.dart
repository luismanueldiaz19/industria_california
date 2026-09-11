import '../../../services/http_service.dart';
import '../models/ruta.dart';

class RutaService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/rutas';

  Future<List<Ruta>> getRutas() async {
    final response = await _http.get(_base);
    List data = response is List ? response : (response['data'] ?? []);
    return data.map((item) => Ruta.fromJson(item)).toList();
  }

  Future<Ruta> createRuta(Map<String, dynamic> data) async {
    final response = await _http.post(_base, data);
    return Ruta.fromJson(response);
  }

  Future<void> updateRuta(int id, Map<String, dynamic> data) async {
    await _http.put('$_base/$id', data);
  }

  Future<void> deleteRuta(int id) async {
    await _http.delete('$_base/$id');
  }
}
