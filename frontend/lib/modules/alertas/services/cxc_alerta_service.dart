import '../../../core/services/http_service.dart';
import '../models/cxc_alerta_model.dart';

class CxcAlertaService {
  final HttpService _http = HttpService();

  /// ─────────────────────────────────────────────────────────────────────────
  /// 1. LISTAR ALERTAS
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 Alertas (Módulo Limpio):         await _http.getV2('alertas', params: params);
  ///   • V2 CXC (Legacy V2):                 await _http.getV2('cxc/alertas', params: params);
  ///   • V1 Ledhouse (Legacy V1):            await _http.get('ledhouse/cxc/alertas', params: params);
  ///   • V1 Industria California (Legacy V1): await _http.get('industria-california/cxc/alertas', params: params);
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
      // OPCIÓN A: V2 Módulo Alertas Limpio
      res = await _http.getV2('alertas', params: params);

      // OPCIÓN B: V2 CXC Legacy
      // res = await _http.getV2('cxc/alertas', params: params);

      // OPCIÓN C: V1 Ledhouse Legacy
      // res = await _http.get('ledhouse/cxc/alertas', params: params);

      // OPCIÓN D: V1 Industria California Legacy
      // res = await _http.get('industria-california/cxc/alertas', params: params);
    } catch (_) {
      // Fallback automático por si falla V2
      res = await _http.getV2('ledhouse/cxc/alertas', params: params);
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

  /// ─────────────────────────────────────────────────────────────────────────
  /// 2. RESOLVER / PROCESAR ALERTA
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 Alertas (Módulo Limpio):         await _http.patchV2('alertas/$alertaId/resolver', body);
  ///   • V2 CXC (Legacy V2):                 await _http.patchV2('cxc/alertas/$alertaId/resolver', body);
  ///   • V1 Ledhouse (Legacy V1):            await _http.patch('ledhouse/cxc/alertas/$alertaId/resolver', body);
  ///   • V1 Industria California (Legacy V1): await _http.patch('industria-california/cxc/alertas/$alertaId/resolver', body);
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
      // OPCIÓN A: V2 Módulo Alertas Limpio
      final res = await _http.patchV2('alertas/$alertaId/resolver', body);

      // OPCIÓN B: V2 CXC Legacy
      // final res = await _http.patchV2('cxc/alertas/$alertaId/resolver', body);

      // OPCIÓN C: V1 Ledhouse Legacy
      // final res = await _http.patch('ledhouse/cxc/alertas/$alertaId/resolver', body);

      // OPCIÓN D: V1 Industria California Legacy
      // final res = await _http.patch('industria-california/cxc/alertas/$alertaId/resolver', body);

      return res as Map<String, dynamic>;
    } catch (_) {
      // Fallback
      final res = await _http.patchV2(
        'ledhouse/cxc/alertas/$alertaId/resolver',
        body,
      );
      return res as Map<String, dynamic>;
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 2.1 RESOLVER GRUPO COMPLETO DE ALERTAS (PAGO AGRUPADO)
  /// ─────────────────────────────────────────────────────────────────────────
  Future<dynamic> resolverGrupo({
    required String grupoId,
    required String estadoAlerta,
    bool actualizarCxc = false,
    List<Map<String, dynamic>>? items,
  }) async {
    final body = <String, dynamic>{
      'estado_alerta': estadoAlerta,
      if (actualizarCxc) 'actualizar_cxc': true,
      'items': ?items,
    };

    return await _http.patchV2('alertas/grupo/$grupoId/resolver', body);
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 3. ACTUALIZAR CONCEPTO / TIPO DE ALERTA
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 Alertas (Módulo Limpio):         await _http.patchV2('alertas/$alertaId/tipo', body);
  ///   • V2 CXC (Legacy V2):                 await _http.patchV2('cxc/alertas/$alertaId/tipo', body);
  ///   • V1 Ledhouse (Legacy V1):            await _http.patch('ledhouse/cxc/alertas/$alertaId/tipo', body);
  ///   • V1 Industria California (Legacy V1): await _http.patch('industria-california/cxc/alertas/$alertaId/tipo', body);
  Future<bool> updateTipoAlerta({
    required int alertaId,
    required String nuevoTipo,
  }) async {
    final body = <String, dynamic>{'tipo': nuevoTipo};
    try {
      // OPCIÓN A: V2 Módulo Alertas Limpio
      await _http.patchV2('alertas/$alertaId/tipo', body);

      // OPCIÓN B: V2 CXC Legacy
      // await _http.patchV2('cxc/alertas/$alertaId/tipo', body);

      // OPCIÓN C: V1 Ledhouse Legacy
      // await _http.patch('ledhouse/cxc/alertas/$alertaId/tipo', body);

      // OPCIÓN D: V1 Industria California Legacy
      // await _http.patch('industria-california/cxc/alertas/$alertaId/tipo', body);

      return true;
    } catch (_) {
      try {
        await _http.patchV2('ledhouse/cxc/alertas/$alertaId/tipo', body);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 4. LISTAR EVIDENCIAS DE UN CXC
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 CXC (Módulo V2):                 await _http.getV2('cxc/$cxcId/evidencias');
  ///   • V1 Ledhouse (Legacy V1):            await _http.get('ledhouse/cxc/$cxcId/evidencias');
  ///   • V1 Industria California (Legacy V1): await _http.get('industria-california/cxc/$cxcId/evidencias');
  Future<List<dynamic>> getEvidencias(int cxcId) async {
    try {
      // OPCIÓN A: V2 CXC
      final res = await _http.getV2('cxc/$cxcId/evidencias');

      // OPCIÓN B: V1 Ledhouse Legacy
      // final res = await _http.get('ledhouse/cxc/$cxcId/evidencias');

      // OPCIÓN C: V1 Industria California Legacy
      // final res = await _http.get('industria-california/cxc/$cxcId/evidencias');

      return (res as List?) ?? [];
    } catch (_) {
      final res = await _http.getV2('ledhouse/cxc/$cxcId/evidencias');
      return (res as List?) ?? [];
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 5. ELIMINAR UNA ALERTA
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 Alertas (Módulo Limpio):         await _http.deleteV2('alertas/$alertaId');
  ///   • V2 CXC (Legacy V2):                 await _http.deleteV2('cxc/alertas/$alertaId');
  ///   • V1 Ledhouse (Legacy V1):            await _http.delete('ledhouse/cxc/alertas/$alertaId');
  ///   • V1 Industria California (Legacy V1): await _http.delete('industria-california/cxc/alertas/$alertaId');
  Future<bool> deleteAlerta(int alertaId) async {
    try {
      // OPCIÓN A: V2 Módulo Alertas Limpio
      await _http.deleteV2('alertas/$alertaId');

      // OPCIÓN B: V2 CXC Legacy
      // await _http.deleteV2('cxc/alertas/$alertaId');

      // OPCIÓN C: V1 Ledhouse Legacy
      // await _http.delete('ledhouse/cxc/alertas/$alertaId');

      // OPCIÓN D: V1 Industria California Legacy
      // await _http.delete('industria-california/cxc/alertas/$alertaId');

      return true;
    } catch (_) {
      try {
        await _http.deleteV2('ledhouse/cxc/alertas/$alertaId');
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 6. OBTENER URL PARA REPORTE PDF DE ALERTAS
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 Alertas (Módulo Limpio):         await _http.getV2('alertas/pdf-url?$queryStr');
  ///   • V2 CXC (Legacy V2):                 await _http.getV2('cxc/alertas-pdf-url?$queryStr');
  ///   • V1 Ledhouse (Legacy V1):            await _http.get('ledhouse/cxc/alertas-pdf-url?$queryStr');
  ///   • V1 Industria California (Legacy V1): await _http.get('industria-california/cxc/alertas-pdf-url?$queryStr');
  Future<String?> getReporteAlertasPdfUrl(Map<String, String> params) async {
    final queryStr = Uri(queryParameters: params).query;
    try {
      // OPCIÓN A: V2 Módulo Alertas Limpio
      final res = await _http.getV2('alertas/pdf-url?$queryStr');

      // OPCIÓN B: V1 Ledhouse Legacy
      // final res = await _http.get('ledhouse/cxc/alertas-pdf-url?$queryStr');

      // OPCIÓN C: V1 Industria California Legacy
      // final res = await _http.get('industria-california/cxc/alertas-pdf-url?$queryStr');

      if (res is Map && res['url'] != null) {
        return res['url'].toString();
      }
    } catch (_) {
      try {
        final res = await _http.getV2('ledhouse/cxc/alertas-pdf-url?$queryStr');
        if (res is Map && res['url'] != null) {
          return res['url'].toString();
        }
      } catch (_) {}
    }
    return null;
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 7. RESUMEN / MÉTRICAS DE ALERTAS (NUEVO V2)
  /// ─────────────────────────────────────────────────────────────────────────
  /// Opciones de URL disponibles:
  ///   • V2 Alertas (Módulo Limpio):         await _http.getV2('alertas/resumen');
  ///   • V1 Ledhouse:                        await _http.get('ledhouse/alertas/resumen');
  ///   • V1 Industria California:            await _http.get('industria-california/alertas/resumen');
  Future<Map<String, dynamic>?> getResumenAlertas() async {
    try {
      // OPCIÓN A: V2 Módulo Alertas Limpio
      final res = await _http.getV2('alertas/resumen');

      // OPCIÓN B: V1 Ledhouse
      // final res = await _http.get('ledhouse/alertas/resumen');

      // OPCIÓN C: V1 Industria California
      // final res = await _http.get('industria-california/alertas/resumen');

      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}
    return null;
  }
}
