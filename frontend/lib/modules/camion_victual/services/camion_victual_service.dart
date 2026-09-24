import '../../../core/services/http_service.dart';
import '../models/camion_victual.dart';

class CamionVictualService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/camiones-victuales';

  Future<String> getConducePdfUrl(int id) async {
    final response = await _http.get('$_base/$id/pdf-url');
    return response['url'] as String;
  }

  /// Obtiene todos los camiones victuales activos (armando, listo, en_ruta).
  /// El vendedor solo ve los que tiene asignados; el backend ya filtra por rol.
  Future<List<CamionVictual>> getCamiones({
    int? choferID,
    bool withPedidos = true,
    String? estado,
  }) async {
    final params = {
      if (choferID != null) 'chofer_id': choferID.toString(),
      if (estado != null) 'estado': estado,
      if (withPedidos) 'with_pedidos': '1',
    };
    final response = await _http.get(_base, params: params);
    final List data = response is List ? response : [];
    return data.map((e) => CamionVictual.fromJson(e)).toList();
  }

  Future<CamionVictual> createCamion(Map<String, dynamic> data) async {
    final response = await _http.post(_base, data);
    return CamionVictual.fromJson(response);
  }

  Future<CamionVictual> updateCamion(int id, Map<String, dynamic> data) async {
    final response = await _http.put('$_base/$id', data);
    return CamionVictual.fromJson(response);
  }

  Future<void> deleteCamion(int id) async {
    await _http.delete('$_base/$id');
  }

  /// Ver detalle de un camión con sus pedidos ordenados.
  Future<CamionVictual> getCamion(int id) async {
    final response = await _http.get('$_base/$id');
    return CamionVictual.fromJson(response);
  }

  /// Obtiene el monto mínimo configurado globalmente en el sistema.
  Future<double> getMontoMinimo() async {
    final response = await _http.get('$_base/monto-minimo');
    return double.tryParse(response['monto_minimo']?.toString() ?? '0') ?? 0;
  }

  /// Pedidos en estado 'facturado' disponibles para agregar (sin camión activo).
  Future<List<PedidoDisponible>> getPedidosDisponibles({String? search}) async {
    final params = {if (search != null && search.isNotEmpty) 'search': search};
    final response = await _http.get(
      '$_base/pedidos-disponibles',
      params: params,
    );
    final List data = response is List ? response : [];
    return data.map((e) => PedidoDisponible.fromJson(e)).toList();
  }

  /// Agrega un pedido al camión (orden_viaje se asigna automáticamente al final).
  Future<CamionVictual> agregarPedido(int camionId, int pedidoId) async {
    final response = await _http.post('$_base/$camionId/pedidos', {
      'pedido_id': pedidoId,
    });
    return CamionVictual.fromJson(response);
  }

  /// Quita un pedido del camión.
  Future<CamionVictual> quitarPedido(int camionId, int pedidoId) async {
    final response = await _http.delete('$_base/$camionId/pedidos/$pedidoId');
    return CamionVictual.fromJson(response);
  }

  /// Reordena los pedidos del camión según la secuencia que definió el vendedor.
  /// [orden] es una lista de maps: [{'pedido_id': 1, 'orden_viaje': 1}, ...]
  Future<CamionVictual> reordenar(
    int camionId,
    List<Map<String, int>> orden,
  ) async {
    final response = await _http.patch('$_base/$camionId/reordenar', {
      'orden': orden,
    });
    return CamionVictual.fromJson(response);
  }
}
