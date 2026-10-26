import '../../../core/services/http_service.dart';
import '../models/camion_victual.dart';

class CamionVictualService {
  final HttpService _http = HttpService();
  static const String _base = 'camiones-victuales';

  Future<String> getConducePdfUrl(int id) async {
    final response = await _http.getV2('$_base/$id/pdf-url');
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
    final response = await _http.getV2(_base, params: params);
    final List data = response is List ? response : [];
    return data.map((e) => CamionVictual.fromJson(e)).toList();
  }

  Future<CamionVictual> createCamion(Map<String, dynamic> data) async {
    final response = await _http.postV2(_base, data);
    return CamionVictual.fromJson(response);
  }

  Future<CamionVictual> updateCamion(int id, Map<String, dynamic> data) async {
    final response = await _http.putV2('$_base/$id', data);
    return CamionVictual.fromJson(response);
  }

  Future<void> deleteCamion(int id) async {
    await _http.deleteV2('$_base/$id');
  }

  /// Ver detalle de un camión con sus pedidos ordenados.
  Future<CamionVictual> getCamion(int id) async {
    final response = await _http.getV2('$_base/$id');
    return CamionVictual.fromJson(response);
  }

  /// Obtiene el monto mínimo configurado globalmente en el sistema.
  Future<double> getMontoMinimo() async {
    final response = await _http.getV2('$_base/monto-minimo');
    return double.tryParse(response['monto_minimo']?.toString() ?? '0') ?? 0;
  }

  /// Pedidos en estado 'facturado' disponibles para agregar (sin camión activo).
  Future<List<PedidoDisponible>> getPedidosDisponibles({String? search}) async {
    final params = {if (search != null && search.isNotEmpty) 'search': search};
    final response = await _http.getV2(
      '$_base/pedidos-disponibles',
      params: params,
    );
    final List data = response is List ? response : [];
    return data.map((e) => PedidoDisponible.fromJson(e)).toList();
  }

  /// Agrega un pedido al camión (orden_viaje se asigna automáticamente al final).
  Future<CamionVictual> agregarPedido(int camionId, int pedidoId) async {
    final response = await _http.postV2('$_base/$camionId/pedidos', {
      'pedido_id': pedidoId,
    });
    return CamionVictual.fromJson(response);
  }

  /// Quita un pedido del camión.
  Future<CamionVictual> quitarPedido(int camionId, int pedidoId) async {
    final response = await _http.deleteV2('$_base/$camionId/pedidos/$pedidoId');
    return CamionVictual.fromJson(response);
  }

  /// Reordena los pedidos del camión según la secuencia que definió el vendedor.
  /// [orden] es una lista de maps: [{'pedido_id': 1, 'orden_viaje': 1}, ...]
  Future<CamionVictual> reordenar(
    int camionId,
    List<Map<String, int>> orden,
  ) async {
    final response = await _http.patchV2('$_base/$camionId/reordenar', {
      'orden': orden,
    });
    return CamionVictual.fromJson(response);
  }

  Future<CamionVictual> actualizarEntrega(
    int camionId,
    int pedidoId,
    String estadoEntrega, {
    String? comentarioEntrega,
  }) async {
    final response = await _http.patchV2(
      '$_base/$camionId/pedidos/$pedidoId/entrega',
      {
        'estado_entrega': estadoEntrega,
        if (comentarioEntrega != null && comentarioEntrega.isNotEmpty)
          'comentario_entrega': comentarioEntrega,
      },
    );
    return CamionVictual.fromJson(response);
  }

  Future<CamionVictual> vaciarCamion(int camionId) async {
    final response = await _http.patchV2('$_base/$camionId/vaciar', {});
    return CamionVictual.fromJson(response);
  }

  Future<CamionVictual> ponerEnRuta(
    int camionId, {
    required int vehiculoId,
    required int choferId,
    int? cantAyudantes,
    String? nombresAyudantes,
    String? comentarios,
    List<Map<String, dynamic>>? gastos,
  }) async {
    final body = <String, dynamic>{
      'vehiculo_id': vehiculoId,
      'chofer_id': choferId,
      if (cantAyudantes != null) 'cant_ayudantes': cantAyudantes,
      if (nombresAyudantes != null && nombresAyudantes.trim().isNotEmpty)
        'nombres_ayudantes': nombresAyudantes.trim(),
      if (comentarios != null && comentarios.trim().isNotEmpty)
        'comentarios': comentarios.trim(),
      if (gastos != null && gastos.isNotEmpty) 'gastos': gastos,
    };
    final response = await _http.patchV2('$_base/$camionId/en-ruta', body);
    return CamionVictual.fromJson(response);
  }

  Future<CamionVictual> cerrar(int camionId) async {
    final response = await _http.patchV2('$_base/$camionId/cerrar', {});
    return CamionVictual.fromJson(response);
  }

  /// Guarda datos preliminares del viaje (gastos, ayudantes, comentarios)
  /// SIN cerrar el viaje ni liberar el camión.
  Future<Map<String, dynamic>> guardarDatosViaje(
    int camionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.postV2(
      '$_base/$camionId/guardar-viaje',
      data,
    );
    return response as Map<String, dynamic>;
  }

  /// Cierra el camión con liquidación de viaje (gastos, ayudantes, comentarios)
  /// y retorna el camión liberado junto con el objeto del viaje cerrado.
  Future<Map<String, dynamic>> cerrarConLiquidacion(
    int camionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.postV2(
      '$_base/$camionId/cerrar-liquidacion',
      data,
    );
    return response as Map<String, dynamic>;
  }

  /// Obtiene el historial de viajes liquidados con filtros y paginación.
  Future<Map<String, dynamic>> getHistorialViajes({
    int? choferId,
    int? vehiculoId,
    String? estado,
    String? fechaInicio,
    String? fechaFin,
    int? page,
    int? perPage,
  }) async {
    final params = {
      if (choferId != null) 'chofer_id': choferId.toString(),
      if (vehiculoId != null) 'vehiculo_id': vehiculoId.toString(),
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      if (fechaFin != null) 'fecha_fin': fechaFin,
      if (page != null) 'page': page.toString(),
      if (perPage != null) 'per_page': perPage.toString(),
    };
    final response = await _http.getV2('$_base/viajes/historial', params: params);
    return response as Map<String, dynamic>;
  }

  /// Obtiene los detalles completos de un viaje histórico.
  Future<Map<String, dynamic>> getDetalleViaje(int viajeId) async {
    final response = await _http.getV2('$_base/viajes/$viajeId');
    return response as Map<String, dynamic>;
  }
}
