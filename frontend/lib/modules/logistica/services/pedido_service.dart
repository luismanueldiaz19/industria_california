import '../../../services/http_service.dart';
import '../models/pedido.dart';

class PedidoService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/pedidos';

  Future<Map<String, dynamic>> getPedidos({
    int? clienteId,
    int? rutaId,
    String? estado,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final queryParams = {
      'cliente_id': ?clienteId?.toString(),
      'ruta_id': ?rutaId?.toString(),
      'estado': ?estado,
      'start_date': ?startDate,
      'end_date': ?endDate,
      'page': page.toString(),
    };

    final response = await _http.get(_base, params: queryParams);

    final List data = response['data'] ?? [];
    return {
      'data': data.map((item) => Pedido.fromJson(item)).toList(),
      'current_page': response['current_page'],
      'last_page': response['last_page'],
      'total': response['total'],
    };
  }

  Future<Pedido> createPedido(Map<String, dynamic> data) async {
    final response = await _http.post(_base, data);
    return Pedido.fromJson(response);
  }

  Future<Pedido> updatePedido(int id, Map<String, dynamic> data) async {
    final response = await _http.put('$_base/$id', data);
    return Pedido.fromJson(response);
  }

  Future<Pedido> changeStatus(int id, String estado) async {
    final response = await _http.patch('$_base/$id/estado', {'estado': estado});
    return Pedido.fromJson(response);
  }
}
