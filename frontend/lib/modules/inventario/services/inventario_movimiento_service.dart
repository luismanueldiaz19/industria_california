import '../models/inventario_movimiento.dart';
import '../../../services/http_service.dart';

class InventarioMovimientoService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/inventario/movimientos';

  Future<Map<String, dynamic>> getMovimientos({
    int? productoId,
    String? tipo,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 30,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (productoId != null) params['producto_id'] = productoId.toString();
    if (tipo != null && tipo.isNotEmpty) params['tipo'] = tipo;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await _http.get(_base, params: params);
    final data = response as Map<String, dynamic>;

    final items = (data['data'] as List? ?? [])
        .map((e) => InventarioMovimiento.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'items': items,
      'current_page': data['current_page'] ?? 1,
      'last_page': data['last_page'] ?? 1,
      'total': data['total'] ?? 0,
      'resumen': data['resumen'] ?? {},
    };
  }

  Future<InventarioMovimiento> registrarMovimiento(InventarioMovimiento movimiento) async {
    final response = await _http.post(_base, movimiento.toJson());
    return InventarioMovimiento.fromJson(response as Map<String, dynamic>);
  }

  Future<String?> getMovimientoPdfUrl({
    int? productoId,
    String? tipo,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (productoId != null) params['producto_id'] = productoId.toString();
    if (tipo != null && tipo.isNotEmpty) params['tipo'] = tipo;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await _http.get(
      'industria-california/inventario/movimientos-pdf-url',
      params: params,
    );
    return response?['url'] as String?;
  }
}
