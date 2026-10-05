import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/services/http_service.dart';

class ChequeFuturistaService {
  final HttpService _http = HttpService();
  final String _endpoint = 'industria-california/cheques-futuristas';

  /// Obtiene la lista de cheques futuristas (Paginada)
  Future<Map<String, dynamic>> obtenerCheques({
    int page = 1,
    String? fechaInicio,
    String? fechaFin,
    String? buscar,
    bool atrasados = false,
    String tipoFecha = 'creacion',
  }) async {
    final Map<String, String> params = {'page': page.toString()};
    if (atrasados) params['atrasados'] = 'true';
    if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) params['fecha_fin'] = fechaFin;
    if (buscar != null && buscar.trim().isNotEmpty)
      params['buscar'] = buscar.trim();
    params['tipo_fecha'] = tipoFecha;

    final response = await _http.get(_endpoint, params: params);
    return response as Map<String, dynamic>;
  }

  /// Obtiene TODOS los cheques de TODOS los vendedores (panel administrativo)
  Future<Map<String, dynamic>> obtenerChequesAdmin({
    int page = 1,
    String? fechaInicio,
    String? fechaFin,
    String? buscar,
    String? estado,
    int? idVendedor,
    bool atrasados = false,
    String tipoFecha = 'creacion',
  }) async {
    final Map<String, String> params = {'page': page.toString()};
    if (atrasados) params['atrasados'] = 'true';
    if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) params['fecha_fin'] = fechaFin;
    if (buscar != null && buscar.trim().isNotEmpty) {
      params['buscar'] = buscar.trim();
    }
    if (estado != null) params['estado'] = estado;
    if (idVendedor != null) params['id_vendedor'] = idVendedor.toString();
    params['tipo_fecha'] = tipoFecha;

    final response = await _http.get(
      'industria-california/admin/cheques-futuristas',
      params: params,
    );
    return response as Map<String, dynamic>;
  }

  /// Obtiene la URL firmada para el PDF
  Future<String> getPdfUrl({
    String? fechaInicio,
    String? fechaFin,
    String? buscar,
    String? estado,
    int? idVendedor,
    bool atrasados = false,
  }) async {
    final Map<String, String> params = {};
    if (atrasados) params['atrasados'] = 'true';
    if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) params['fecha_fin'] = fechaFin;
    if (buscar != null && buscar.trim().isNotEmpty) {
      params['buscar'] = buscar.trim();
    }
    if (estado != null) params['estado'] = estado;
    if (idVendedor != null) params['id_vendedor'] = idVendedor.toString();

    final response = await _http.get(
      'industria-california/cheques-futuristas/pdf-url',
      params: params,
    );
    return response['url'];
  }

  /// Obtiene el reporte agrupado por vendedores y estados
  Future<List<dynamic>> obtenerReporteVendedores({
    String? fechaInicio,
    String? fechaFin,
    String tipoFecha = 'creacion',
  }) async {
    final Map<String, String> params = {};
    if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) params['fecha_fin'] = fechaFin;
    params['tipo_fecha'] = tipoFecha;

    final response = await _http.get(
      'industria-california/admin/cheques-futuristas/reporte-vendedores',
      params: params,
    );
    return response as List<dynamic>;
  }

  /// Crea un nuevo cheque futurista con datos de texto (Paso 1 del upload)
  Future<Map<String, dynamic>> crear(Map<String, dynamic> payload) async {
    final response = await _http.post(_endpoint, payload);
    return response as Map<String, dynamic>;
  }

  /// Sube un documento adjunto relacionado a un cheque (Paso 2 del upload)
  Future<bool> subirDocumento(int chequeId, XFile archivo) async {
    try {
      final bytes = await archivo.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: archivo.name.isNotEmpty ? archivo.name : 'documento.jpg',
      );

      final response = await _http.multipart(
        '$_endpoint/$chequeId/documentos',
        files: [multipartFile],
      );

      return response != null;
    } catch (e) {
      print('Error al subir documento de cheque: $e');
      throw 'No se pudo subir la imagen: $e';
    }
  }

  /// Obtiene los documentos de un cheque
  Future<List<dynamic>> obtenerDocumentos(int chequeId) async {
    try {
      final response = await _http.get('$_endpoint/$chequeId/documentos');
      return response as List<dynamic>;
    } catch (e) {
      print('Error al obtener documentos: $e');
      return [];
    }
  }

  /// Actualiza el estado de un cheque
  Future<bool> actualizarEstado(int chequeId, String nuevoEstado) async {
    try {
      await _http.put('$_endpoint/$chequeId', {'estado': nuevoEstado});
      return true;
    } catch (e) {
      throw _limpiarError(e);
    }
  }

  /// Elimina un cheque (Solo Admin)
  Future<bool> eliminarCheque(int chequeId) async {
    try {
      await _http.delete('$_endpoint/$chequeId');
      return true;
    } catch (e) {
      throw _limpiarError(e);
    }
  }

  /// Elimina una imagen/evidencia de un cheque (Solo Admin)
  Future<bool> eliminarDocumento(int chequeId, int documentoId) async {
    try {
      await _http.delete('$_endpoint/$chequeId/documentos/$documentoId');
      return true;
    } catch (e) {
      throw _limpiarError(e);
    }
  }

  String _limpiarError(Object e) => e
      .toString()
      .replaceAll('Error inesperado: ', '')
      .replaceAll('Exception: ', '');
}
