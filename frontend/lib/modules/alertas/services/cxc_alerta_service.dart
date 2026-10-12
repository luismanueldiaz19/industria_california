import '../../../core/services/http_service.dart';
import '../models/cxc_alerta_model.dart';

class CxcAlertaService {
  final HttpService _http = HttpService();

  /// Lista todas las alertas (filtrado por estado, paginación, fechas)
  Future<dynamic> getAlertas({
    String? estado,
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
    String? search,
    String? tipo,
    int? vendedorId,
  }) async {
    final params = <String, String>{};
    if (estado != null) params['estado'] = estado;
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tipo != null && tipo != 'Todos') params['tipo'] = tipo;
    if (vendedorId != null) params['vendedor_id'] = vendedorId.toString();

    dynamic res;
    try {
      res = await _http.getV2('cxc/alertas', params: params);
    } catch (_) {
      res = await _http.get('ledhouse/cxc/alertas', params: params);
    }

    if (res is List) {
      return res.map((json) => CxcAlertaModel.fromJson(json)).toList();
    } else if (res is Map<String, dynamic> && res.containsKey('data')) {
      final list = (res['data'] as List)
          .map((json) => CxcAlertaModel.fromJson(json))
          .toList();
      return {
        'data': list,
        'total': res['total'] ?? 0,
        'current_page': res['current_page'] ?? 1,
        'last_page': res['last_page'] ?? 1,
      };
    }
    return <CxcAlertaModel>[];
  }

  /// Resolver una alerta (y opcionalmente actualizar el CXC)
  Future<Map<String, dynamic>> resolverAlerta({
    required int alertaId,
    required String estadoAlerta,
    bool actualizarCxc = false,
    double? montoPagado,
    String? estadoCxc,
  }) async {
    final body = <String, dynamic>{
      'estado_alerta': estadoAlerta,
      if (actualizarCxc) 'actualizar_cxc': true,
      'monto_pagado': ?montoPagado,
      'estado_cxc': ?estadoCxc,
    };

    try {
      final res = await _http.patchV2('cxc/alertas/$alertaId/resolver', body);
      return res as Map<String, dynamic>;
    } catch (_) {
      final res = await _http.patch('ledhouse/cxc/alertas/$alertaId/resolver', body);
      return res as Map<String, dynamic>;
    }
  }

  /// Actualizar el tipo de alerta manualmente (admin)
  Future<bool> updateTipoAlerta({
    required int alertaId,
    required String nuevoTipo,
  }) async {
    final body = <String, dynamic>{
      'tipo': nuevoTipo,
    };
    try {
      try {
        await _http.patchV2('cxc/alertas/$alertaId/tipo', body);
      } catch (_) {
        await _http.patch('ledhouse/cxc/alertas/$alertaId/tipo', body);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lista las evidencias de un CXC
  Future<List<dynamic>> getEvidencias(int cxcId) async {
    try {
      final res = await _http.getV2('cxc/$cxcId/evidencias');
      return (res as List?) ?? [];
    } catch (_) {
      final res = await _http.get('ledhouse/cxc/$cxcId/evidencias');
      return (res as List?) ?? [];
    }
  }

  /// Eliminar una alerta
  Future<bool> deleteAlerta(int alertaId) async {
    try {
      await _http.deleteV2('cxc/alertas/$alertaId');
      return true;
    } catch (_) {
      await _http.delete('ledhouse/cxc/alertas/$alertaId');
      return true;
    }
  }

  /// Obtiene la URL firmada para reporte PDF
  Future<String?> getReporteAlertasPdfUrl(Map<String, String> params) async {
    final queryStr = Uri(queryParameters: params).query;
    try {
      final res = await _http.get('ledhouse/cxc/alertas-pdf-url?$queryStr');
      if (res is Map && res['url'] != null) {
        return res['url'].toString();
      }
    } catch (_) {}
    return null;
  }
}
