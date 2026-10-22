import '../../../../core/services/http_service.dart';
import '../models/cxc_cuarentena_model.dart';

class CxcCuarentenaService {
  final HttpService _http = HttpService();

  Future<Map<String, dynamic>> getCuarentenas({
    String? estado,
    String? tipoNota,
    int? vendedorId,
    int? clienteId,
    String? search,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 25,
  }) async {
    final queryParams = <String>[];
    if (estado != null && estado != 'todos' && estado != 'Todos') {
      queryParams.add('estado=${Uri.encodeComponent(estado.toLowerCase())}');
    }
    if (tipoNota != null && tipoNota != 'todos' && tipoNota != 'Todos') {
      queryParams.add(
        'tipo_nota=${Uri.encodeComponent(tipoNota.toLowerCase())}',
      );
    }
    if (vendedorId != null) queryParams.add('vendedor_id=$vendedorId');
    if (clienteId != null) queryParams.add('cliente_id=$clienteId');
    if (search != null && search.trim().isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (startDate != null && endDate != null) {
      queryParams.add('start_date=$startDate');
      queryParams.add('end_date=$endDate');
    }
    queryParams.add('page=$page');
    queryParams.add('per_page=$perPage');

    final endpoint = 'cxc/cuarentena?${queryParams.join('&')}';
    final response = await _http.getV2(endpoint);

    final List dataList = response['data'] ?? [];
    final items = dataList.map((e) => CxcCuarentenaModel.fromJson(e)).toList();

    return {
      'data': items,
      'current_page': response['current_page'] ?? 1,
      'last_page': response['last_page'] ?? 1,
      'per_page': response['per_page'] ?? perPage,
      'total': response['total'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> getResumen() async {
    final response = await _http.getV2('cxc/cuarentena/resumen');
    return Map<String, dynamic>.from(response);
  }

  Future<CxcCuarentenaModel> getDetalle(int id) async {
    final response = await _http.getV2('cxc/cuarentena/$id');
    return CxcCuarentenaModel.fromJson(response);
  }

  Future<Map<String, dynamic>> enviarACuarentena(
    int cxcId, {
    required String tipoNota,
    required double montoNota,
    required String motivo,
    required String justificacion,
  }) async {
    final response = await _http.postV2('cxc/$cxcId/cuarentena', {
      'tipo_nota': tipoNota,
      'monto_nota': montoNota,
      'motivo': motivo,
      'justificacion': justificacion,
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enviarMasivoACuarentena({
    required List<int> ids,
    required String tipoNota,
    required String motivo,
    required String justificacion,
  }) async {
    final response = await _http.postV2('cxc/cuarentena/masivo', {
      'ids': ids,
      'tipo_nota': tipoNota,
      'motivo': motivo,
      'justificacion': justificacion,
    });
    return response as Map<String, dynamic>;
  }

  Future<CxcCuarentenaModel> aplicarNota(
    int id, {
    String? numeroNotaExterna,
    String? notaResolucion,
  }) async {
    final response = await _http.patchV2('cxc/cuarentena/$id/aplicar', {
      if (numeroNotaExterna != null && numeroNotaExterna.trim().isNotEmpty)
        'numero_nota_externa': numeroNotaExterna.trim(),
      if (notaResolucion != null && notaResolucion.trim().isNotEmpty)
        'nota_resolucion': notaResolucion.trim(),
    });
    return CxcCuarentenaModel.fromJson(response);
  }

  Future<CxcCuarentenaModel> anularNota(
    int id, {
    required String notaResolucion,
  }) async {
    final response = await _http.patchV2('cxc/cuarentena/$id/anular', {
      'nota_resolucion': notaResolucion.trim(),
    });
    return CxcCuarentenaModel.fromJson(response);
  }
}
