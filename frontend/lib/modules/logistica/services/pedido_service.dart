import '../../../services/http_service.dart';
import '../models/pedido.dart';

class PedidoService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/pedidos';

  Future<Map<String, dynamic>> getPedidos({
    int? clienteId,
    int? rutaId,
    int? vendedorId,
    String? estado,
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    final queryParams = {
      if (clienteId != null) 'cliente_id': clienteId.toString(),
      if (rutaId != null) 'ruta_id': rutaId.toString(),
      if (vendedorId != null) 'vendedor_id': vendedorId.toString(),
      if (estado != null) 'estado': estado,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
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

  Future<void> deletePedido(int id) async {
    await _http.delete('$_base/$id');
  }

  Future<void> assignRuta(List<int> pedidoIds, int rutaId) async {
    await _http.post('$_base/assign-ruta', {
      'pedido_ids': pedidoIds,
      'ruta_id': rutaId,
    });
  }

  Future<List<Pedido>> optimizeRoute(int rutaId, double lat, double lng) async {
    final response = await _http.post('$_base/optimize-route', {
      'ruta_id': rutaId,
      'origin_lat': lat,
      'origin_lng': lng,
    });
    final List data = response; // backend returns a JSON array
    return data.map((item) => Pedido.fromJson(item)).toList();
  }

  Future<String> getPdfUrl(int id) async {
    final response = await _http.get('$_base/$id/pdf-url');
    return response['url'] as String;
  }

  Future<String> getGeneralPdfUrl({
    int? clienteId,
    int? rutaId,
    int? vendedorId,
    String? estado,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      if (clienteId != null) 'cliente_id': clienteId.toString(),
      if (rutaId != null) 'ruta_id': rutaId.toString(),
      if (vendedorId != null) 'vendedor_id': vendedorId.toString(),
      if (estado != null) 'estado': estado,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
    // Ojo: la ruta de backend es /industria-california/pedidos-pdf-url
    final response = await _http.get(
      'industria-california/pedidos-pdf-url',
      params: queryParams,
    );
    return response['url'] as String;
  }
}
