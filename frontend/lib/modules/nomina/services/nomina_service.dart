import '../../../core/services/http_service.dart';
import '../models/nomina.dart';
import '../models/nomina_concepto.dart';
import '../models/nomina_recurrente.dart';

class NominaService {
  final HttpService _http = HttpService();

  // ── NÓMINAS ───────────────────────────────────────────────
  Future<List<Nomina>> getNominas({String? estado, String? tipoPeriodo, int? anio}) async {
    final params = {
      if (estado != null && estado != 'todos') 'estado': estado,
      if (tipoPeriodo != null && tipoPeriodo != 'todos') 'tipo_periodo': tipoPeriodo,
      if (anio != null) 'anio': anio.toString(),
    };
    final response = await _http.getV2('nominas', params: params);
    final List data = response is List ? response : [];
    return data.map((e) => Nomina.fromJson(e)).toList();
  }

  Future<Nomina> getNomina(int id) async {
    final response = await _http.getV2('nominas/$id');
    return Nomina.fromJson(response);
  }

  Future<Nomina> createNomina(Map<String, dynamic> data) async {
    final response = await _http.postV2('nominas', data);
    return Nomina.fromJson(response);
  }

  Future<Nomina> calcularNomina(int id) async {
    final response = await _http.postV2('nominas/$id/calcular', {});
    return Nomina.fromJson(response);
  }

  Future<Nomina> aprobarNomina(int id) async {
    final response = await _http.postV2('nominas/$id/aprobar', {});
    return Nomina.fromJson(response);
  }

  Future<Nomina> pagarNomina(int id) async {
    final response = await _http.postV2('nominas/$id/pagar', {});
    return Nomina.fromJson(response);
  }

  Future<Nomina> anularNomina(int id, {String? motivo}) async {
    final response = await _http.postV2('nominas/$id/anular', {
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    });
    return Nomina.fromJson(response);
  }

  Future<void> deleteNomina(int id) async {
    await _http.deleteV2('nominas/$id');
  }

  Future<Nomina> agregarConceptoDetalle(int nominaId, int detalleId, Map<String, dynamic> data) async {
    final response = await _http.postV2('nominas/$nominaId/detalles/$detalleId/conceptos', data);
    return Nomina.fromJson(response);
  }

  Future<Nomina> eliminarConceptoDetalle(int nominaId, int detalleId, int conceptoId) async {
    final response = await _http.deleteV2('nominas/$nominaId/detalles/$detalleId/conceptos/$conceptoId');
    return Nomina.fromJson(response);
  }

  Future<String> getTokenReporteUrl({
    required String tipo,
    int? nominaId,
    int? detalleId,
    String modo = 'blade',
  }) async {
    final params = {
      'tipo': tipo,
      if (nominaId != null) 'nomina_id': nominaId.toString(),
      if (detalleId != null) 'detalle_id': detalleId.toString(),
      'modo': modo,
    };
    final response = await _http.getV2('nominas/token-reporte', params: params);
    return response['url'] as String;
  }

  Future<Map<String, dynamic>> getResumen() async {
    final response = await _http.getV2('nominas/resumen');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEscalasIsr({int? anio}) async {
    final params = {
      if (anio != null) 'anio': anio.toString(),
    };
    final response = await _http.getV2('nominas/escalas-isr', params: params);
    return response as Map<String, dynamic>;
  }

  // ── CONCEPTOS ─────────────────────────────────────────────
  Future<List<NominaConcepto>> getConceptos({String? tipo, bool? activo}) async {
    final params = {
      if (tipo != null && tipo != 'todos') 'tipo': tipo,
      if (activo != null) 'activo': activo.toString(),
    };
    final response = await _http.getV2('nomina-conceptos', params: params);
    final List data = response is List ? response : [];
    return data.map((e) => NominaConcepto.fromJson(e)).toList();
  }

  Future<NominaConcepto> createConcepto(Map<String, dynamic> data) async {
    final response = await _http.postV2('nomina-conceptos', data);
    return NominaConcepto.fromJson(response);
  }

  Future<NominaConcepto> updateConcepto(int id, Map<String, dynamic> data) async {
    final response = await _http.putV2('nomina-conceptos/$id', data);
    return NominaConcepto.fromJson(response);
  }

  Future<void> deleteConcepto(int id) async {
    await _http.deleteV2('nomina-conceptos/$id');
  }

  // ── RECURRENTES (PRÉSTAMOS / CUOTAS) ──────────────────────
  Future<List<NominaEmpleadoRecurrente>> getRecurrentes({int? empleadoId, bool? activo}) async {
    final params = {
      if (empleadoId != null) 'empleado_id': empleadoId.toString(),
      if (activo != null) 'activo': activo.toString(),
    };
    final response = await _http.getV2('nomina-recurrentes', params: params);
    final List data = response is List ? response : [];
    return data.map((e) => NominaEmpleadoRecurrente.fromJson(e)).toList();
  }

  Future<NominaEmpleadoRecurrente> createRecurrente(Map<String, dynamic> data) async {
    final response = await _http.postV2('nomina-recurrentes', data);
    return NominaEmpleadoRecurrente.fromJson(response);
  }

  Future<void> deleteRecurrente(int id) async {
    await _http.deleteV2('nomina-recurrentes/$id');
  }
}
