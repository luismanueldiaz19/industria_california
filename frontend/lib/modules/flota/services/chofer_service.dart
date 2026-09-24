import '../../../core/services/http_service.dart';
import '../models/chofer.dart';

class ChoferService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/choferes';

  Future<List<Chofer>> getChoferes() async {
    final response = await _http.get(_base);
    final List data = response is List ? response : [];
    return data.map((json) => Chofer.fromJson(json)).toList();
  }

  Future<Chofer> createChofer(Map<String, dynamic> data) async {
    final response = await _http.post(_base, data);
    return Chofer.fromJson(response);
  }

  Future<Chofer> updateChofer(int id, Map<String, dynamic> data) async {
    final response = await _http.put('$_base/$id', data);
    return Chofer.fromJson(response);
  }

  Future<void> deleteChofer(int id) async {
    await _http.delete('$_base/$id');
  }
}
