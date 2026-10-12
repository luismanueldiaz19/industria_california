import '../../../../core/services/http_service.dart';
import '../models/cxc_model.dart';
import '../models/cxc_soporte_model.dart';

// =========================================================================
// TERMINALES / ENDPOINTS DISPONIBLES DE CXC (API V2)
// Prefijo base: /api/v2/cxc
// =========================================================================
// [CRUD BÁSICO]
// GET    /api/v2/cxc                                 -> Listar CXC con filtros/paginación
// POST   /api/v2/cxc                                 -> Crear nuevo CXC
// GET    /api/v2/cxc/{id}                            -> Ver detalle de un CXC
// PUT    /api/v2/cxc/{id}                            -> Actualizar un CXC
// DELETE /api/v2/cxc/{id}                            -> Eliminar un CXC
//
// [RESUMEN Y AGRUPACIONES]
// GET    /api/v2/cxc/resumen                         -> Métricas globales (facturado, pendiente, vencido)
// GET    /api/v2/cxc/grouped                         -> Totales acumulados agrupados por cliente
// GET    /api/v2/cxc/vendedor/mis-cxc                -> CXC filtradas del vendedor autenticado
//
// [AUDITORÍA Y IMPORTACIÓN]
// GET    /api/v2/cxc/auditoria                       -> Chequeos de calidad, duplicados e inconsistencias
// POST   /api/v2/cxc/sync-preview                    -> Preview masivo Excel (sin guardar en BD)
// POST   /api/v2/cxc/sync-confirm                    -> Confirmar e insertar masivo Excel (transaccional)
// POST   /api/v2/cxc/import-by-cliente/{cliente_id}  -> Cargar Excel asignado a un cliente específico
//
// [ALERTAS]
// GET    /api/v2/cxc/alertas                         -> Listar alertas de cobro
// POST   /api/v2/cxc/{cxc}/alerta                    -> Crear alerta en un CXC
// PATCH  /api/v2/cxc/alertas/{alerta}/resolver       -> Resolver o procesar alerta (contabilidad)
// DELETE /api/v2/cxc/alertas/{alerta}                -> Eliminar alerta y sus archivos
//
// [SOPORTES Y EVIDENCIAS]
// GET    /api/v2/cxc/{cxc}/soporte                   -> Listar notas y visitas de cobranza
// POST   /api/v2/cxc/{cxc}/soporte                   -> Agregar nota o fecha de visita
// GET    /api/v2/cxc/{cxc}/evidencias                -> Listar archivos (fotos/PDFs) con URL
// POST   /api/v2/cxc/{cxc}/evidencia                 -> Subir archivo de evidencia
// =========================================================================

class CxcService {
  final HttpService _http = HttpService();

  // GET: /api/v2/cxc
  Future<List<CxcModel>> getCxc({
    int? vendedorId,
    bool? vencidos,
    String? startDate,
    String? endDate,
  }) async {
    String query = '';
    if (vendedorId != null ||
        (vencidos ?? false) ||
        startDate != null ||
        endDate != null) {
      query = '?';
      if (vendedorId != null) query += 'vendedor_id=$vendedorId&';
      if (vencidos == true) query += 'vencidos=1&';
      if (startDate != null) query += 'start_date=$startDate&';
      if (endDate != null) query += 'end_date=$endDate&';
    }
    final response = await _http.getV2('cxc$query');
    return (response as List).map((item) => CxcModel.fromJson(item)).toList();
  }

  // POST: /api/v2/cxc
  Future<CxcModel> createCxc(Map<String, dynamic> data) async {
    final response = await _http.postV2('cxc', data);
    return CxcModel.fromJson(response);
  }

  // PUT: /api/v2/cxc/{id}
  Future<CxcModel> updateCxc(int id, Map<String, dynamic> data) async {
    final response = await _http.putV2('cxc/$id', data);
    return CxcModel.fromJson(response);
  }

  // DELETE: /api/v2/cxc/{id}
  Future<void> deleteCxc(int id) async {
    await _http.deleteV2('cxc/$id');
  }

  // GET: /api/v2/cxc/{cxcId}/soporte
  Future<List<CxcSoporteModel>> getSoportes(int cxcId) async {
    final response = await _http.getV2('cxc/$cxcId/soporte');
    return (response as List)
        .map((item) => CxcSoporteModel.fromJson(item))
        .toList();
  }

  // POST: /api/v2/cxc/{cxcId}/soporte
  Future<CxcSoporteModel> addSoporte(
    int cxcId,
    Map<String, dynamic> data,
  ) async {
    final response = await _http.postV2('cxc/$cxcId/soporte', data);
    return CxcSoporteModel.fromJson(response);
  }

  // GET: /api/v2/cxc/grouped
  Future<List<Map<String, dynamic>>> getGroupedByCliente({
    int? vendedorId,
    bool? vencidos,
    String? startDate,
    String? endDate,
  }) async {
    String query = '';
    if (vendedorId != null ||
        (vencidos ?? false) ||
        startDate != null ||
        endDate != null) {
      query = '?';
      if (vendedorId != null) query += 'vendedor_id=$vendedorId&';
      if (vencidos == true) query += 'vencidos=1&';
      if (startDate != null) query += 'start_date=$startDate&';
      if (endDate != null) query += 'end_date=$endDate&';
    }
    final response = await _http.getV2('cxc/grouped$query');
    return List<Map<String, dynamic>>.from(response);
  }

  // POST: /api/v2/cxc/import-by-cliente/{clienteId}
  Future<Map<String, dynamic>> importarExcel(
    int clienteId,
    List<int> bytes,
    String filename,
  ) async {
    final response = await _http.uploadFile(
      'cxc/import-by-cliente/$clienteId',
      bytes,
      filename,
    );
    return response as Map<String, dynamic>;
  }
}
