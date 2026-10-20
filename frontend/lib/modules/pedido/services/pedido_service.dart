import 'package:intl/intl.dart';
import '../../../core/services/http_service.dart';
import '../models/pedido.dart';

class PedidoService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/pedidos';

  Future<Map<String, dynamic>> getPedido(int id) async {
    return await _http.get('$_base/$id');
  }

  Future<Map<String, dynamic>> getPedidos({
    int? clienteId,
    int? rutaId,
    int? vendedorId,
    String? estado,
    bool? faltantes,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
  }) async {
    final queryParams = {
      if (clienteId != null) 'cliente_id': clienteId.toString(),
      if (rutaId != null) 'ruta_id': rutaId.toString(),
      if (vendedorId != null) 'vendedor_id': vendedorId.toString(),
      if (estado != null) 'estado': estado,
      if (faltantes == true) 'has_faltantes': '1',
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (search != null && search.isNotEmpty) 'search': search,
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

  Future<Pedido> changeStatus(int id, String estado, {String? numFactura}) async {
    final response = await _http.patch('$_base/$id/estado', {
      'estado': estado,
      if (numFactura != null) 'num_factura': numFactura,
    });
    return Pedido.fromJson(response);
  }

  Future<Pedido> updateNumFactura(int id, String? numFactura) async {
    final response = await _http.patch('$_base/$id/num-factura', {
      'num_factura': numFactura,
    });
    return Pedido.fromJson(response);
  }

  Future<Pedido> updateInformacion(
    int id, {
    int? clienteId,
    int? rutaId,
    int? vendedorId,
    String? numFactura,
    String? estado,
    DateTime? fechaEntrega,
    String? comentario,
    String? notaProduccion,
  }) async {
    final Map<String, dynamic> data = {
      if (clienteId != null) 'cliente_id': clienteId,
      'ruta_id': rutaId,
      if (vendedorId != null) 'vendedor_id': vendedorId,
      'num_factura': numFactura,
      if (estado != null) 'estado': estado,
      'fecha_entrega': fechaEntrega != null ? DateFormat('yyyy-MM-dd').format(fechaEntrega) : null,
      'comentario': comentario,
      'nota_produccion': notaProduccion,
    };
    final response = await _http.patch('$_base/$id/informacion', data);
    return Pedido.fromJson(response);
  }

  Future<void> deletePedido(int id) async {
    await _http.delete('$_base/$id');
  }

  Future<Pedido> updateItem(
    int pedidoId,
    int detalleId, {
    double? cantidad,
    double? precioUnitario,
  }) async {
    final Map<String, dynamic> data = {
      if (cantidad != null) 'cantidad': cantidad,
      if (precioUnitario != null) 'precio_unitario': precioUnitario,
    };
    final response = await _http.patch('$_base/$pedidoId/items/$detalleId', data);
    return Pedido.fromJson(response);
  }

  Future<Pedido> updateItems(
    int pedidoId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _http.put('$_base/$pedidoId/items', {'items': items});
    return Pedido.fromJson(response);
  }

  Future<Pedido> deleteItem(int pedidoId, int detalleId) async {
    final response = await _http.delete('$_base/$pedidoId/items/$detalleId');
    return Pedido.fromJson(response);
  }

  Future<Map<String, dynamic>> facturarVigente(
    int id, {
    required String numFactura,
    DateTime? fechaEntrega,
    String? notaProduccion,
    String? comentario,
  }) async {
    final Map<String, dynamic> data = {
      'num_factura': numFactura,
      if (fechaEntrega != null)
        'fecha_entrega': DateFormat('yyyy-MM-dd').format(fechaEntrega),
      if (notaProduccion != null) 'nota_produccion': notaProduccion,
      if (comentario != null) 'comentario': comentario,
    };
    final response = await _http.post('$_base/$id/facturar-vigente', data);
    return response as Map<String, dynamic>;
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
    bool? faltantes,
    String? search,
  }) async {
    final queryParams = {
      if (clienteId != null) 'cliente_id': clienteId.toString(),
      if (rutaId != null) 'ruta_id': rutaId.toString(),
      if (vendedorId != null) 'vendedor_id': vendedorId.toString(),
      'estado': ?estado,
      'start_date': ?startDate,
      'end_date': ?endDate,
      if (faltantes == true) 'has_faltantes': '1',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    // Ojo: la ruta de backend es /industria-california/pedidos-pdf-url
    final response = await _http.get(
      'industria-california/pedidos-pdf-url',
      params: queryParams,
    );
    return response['url'] as String;
  }

  /// Obtiene los datos del reporte agrupado por vendedor (paginado).
  /// El parámetro [search] aplica búsqueda insensible a mayúsculas sobre el nombre del vendedor.
  Future<Map<String, dynamic>> getReporteVendedores({
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      // Se envía el texto tal cual; el backend hace mb_strtolower()
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    return await _http.get(
      'industria-california/pedidos/reporte-vendedores',
      params: queryParams,
    );
  }

  /// Genera URL segura con token para el PDF del reporte por vendedor.
  Future<String> getReporteVendedoresPdfUrl({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await _http.get(
      'industria-california/pedidos-vendedores-pdf-url',
      params: queryParams,
    );
    return response['url'] as String;
  }
}
