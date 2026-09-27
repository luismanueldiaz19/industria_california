import '../../../core/services/http_service.dart';
import '../models/cxc_alerta_model.dart';

class LedhouseCxcAlertaService {
  final HttpService _http = HttpService();

  /// Lista todas las alertas (filtrado por estado si se desea)
  Future<dynamic> getAlertas({
    String? estado,
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (estado != null) params['estado'] = estado;
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final res = await _http.get('ledhouse/cxc/alertas', params: params);
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

  /// Contabilidad resuelve una alerta (y opcionalmente actualiza el CXC)
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
      if (montoPagado != null) 'monto_pagado': montoPagado,
      if (estadoCxc != null) 'estado_cxc': estadoCxc,
    };
    final res = await _http.patch(
      'ledhouse/cxc/alertas/$alertaId/resolver',
      body,
    );
    return res as Map<String, dynamic>;
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
      await _http.patch('ledhouse/cxc/alertas/$alertaId/tipo', body);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lista las evidencias de un CXC
  Future<List<dynamic>> getEvidencias(int cxcId) async {
    final res = await _http.get('ledhouse/cxc/$cxcId/evidencias');
    return (res as List?) ?? [];
  }

  /// Eliminar una alerta
  Future<bool> deleteAlerta(int alertaId) async {
    await _http.delete('ledhouse/cxc/alertas/$alertaId');
    return true;
  }
}
