import '../../../services/http_service.dart';
import '../models/cxc_alerta_model.dart';

class LedhouseCxcAlertaService {
  final HttpService _http = HttpService();

  /// Lista todas las alertas (filtrado por estado si se desea)
  Future<List<CxcAlertaModel>> getAlertas({String? estado}) async {
    final params = <String, String>{};
    if (estado != null) params['estado'] = estado;
    final res = await _http.get('ledhouse/cxc/alertas', params: params);
    if (res is List) {
      return res.map((json) => CxcAlertaModel.fromJson(json)).toList();
    }
    return [];
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
    final res = await _http.patch('ledhouse/cxc/alertas/$alertaId/resolver', body);
    return res as Map<String, dynamic>;
  }

  /// Lista las evidencias de un CXC
  Future<List<dynamic>> getEvidencias(int cxcId) async {
    final res = await _http.get('ledhouse/cxc/$cxcId/evidencias');
    return (res as List?) ?? [];
  }
}
