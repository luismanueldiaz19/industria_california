import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/vendedor_alerta_model.dart';
import '../../../core/utils/constants.dart';

class VendedorCxcService {
  /// ─────────────────────────────────────────────────────────────────────────
  /// CONFIGURACIÓN DE RUTAS BASE
  /// ─────────────────────────────────────────────────────────────────────────
  /// V2 Alertas (Módulo Limpio):
  // final String _baseV2Alertas = '$host/api/v2/alertas';

  /// V2 Cuentas Por Cobrar (Módulo Limpio):
  // final String _baseV2Cxc = '$host/api/v2/cxc';

  /// V1 Legacy (Ledhouse):
  final String _base = '$host/api/v1/ledhouse/cxc';

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// ─────────────────────────────────────────────────────────────────────────
  /// 1. CREAR / AGREGAR ALERTA A UN CXC
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addAlerta({
    required int cxcId,
    required String tipo,
    required String nota,
    double? montoInformado,
    required String token,
  }) async {
    // OPCIÓN A: V2 Módulo Alertas Limpio (Recomendado)
    final uri = Uri.parse('$hostDev/alertas');

    // OPCIÓN B: V2 CXC Legacy
    // final uri = Uri.parse('$_baseV2Cxc/$cxcId/alerta');

    // OPCIÓN C: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/$cxcId/alerta');

    // OPCIÓN D: V1 Industria California Legacy
    // final uri = Uri.parse('$host/api/v1/industria-california/cxc/$cxcId/alerta');

    final bodyData = {
      'ledhouse_cxc_id': cxcId,
      'cxc_id': cxcId,
      'tipo': tipo,
      'nota': nota,
      'monto_informado': ?montoInformado,
    };

    final res = await http.post(
      uri,
      headers: {..._headers(token), 'Content-Type': 'application/json'},
      body: json.encode(bodyData),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }

    try {
      final errorJson = json.decode(res.body);
      throw Exception(
        errorJson['message'] ??
            errorJson['error'] ??
            'Error al agregar alerta (${res.statusCode})',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Error al agregar alerta (${res.statusCode}): ${res.body}',
      );
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 1.1 CREAR PAGO AGRUPADO (UNA FOTO PARA VARIAS FACTURAS)
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addAlertaLote({
    required double montoTotal,
    required String tipo,
    required String nota,
    required List<Map<String, dynamic>> items,
    required Uint8List fileBytes,
    required String fileName,
    required String token,
  }) async {
    final uri = Uri.parse('$hostDev/alertas/lote');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token))
      ..fields['monto_total'] = montoTotal.toString()
      ..fields['tipo'] = tipo
      ..fields['nota'] = nota
      ..fields['items'] = json.encode(items)
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201 || streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    }

    try {
      final errorJson = json.decode(body);
      throw Exception(
        errorJson['message'] ??
            errorJson['error'] ??
            'Error al registrar pago agrupado (${streamed.statusCode})',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Error al registrar pago agrupado (${streamed.statusCode}): $body',
      );
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 2. OBTENER ALERTAS DEL VENDEDOR
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMisAlertas({
    required String token,
    String? estado,
    String? search,
    String? startDate,
    String? endDate,
    String? tipo,
    int page = 1,
  }) async {
    final params = <String, String>{
      'paginate': 'true',
      'page': page.toString(),
    };
    if (estado != null && estado != 'todos') params['estado'] = estado;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (tipo != null && tipo.isNotEmpty && tipo != 'todos') {
      params['tipo'] = tipo;
    }

    // OPCIÓN A: V2 Módulo Alertas Limpio (Recomendado)
    final uri = Uri.parse('$hostDev/alertas').replace(queryParameters: params);

    // OPCIÓN B: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/alertas').replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final response = json.decode(res.body);
      final List dataList = response['data'] ?? [];
      return {
        'data': dataList.map((e) => VendedorAlertaModel.fromJson(e)).toList(),
        'current_page': response['current_page'] ?? 1,
        'last_page': response['last_page'] ?? 1,
        'total': response['total'] ?? 0,
      };
    }
    throw Exception('Error al cargar alertas (${res.statusCode})');
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 3. URL TEMPORAL DEL PDF DE ALERTAS DEL VENDEDOR
  /// ─────────────────────────────────────────────────────────────────────────
  Future<String> obtenerUrlPdfMisAlertas({
    required String token,
    String? search,
    String? estado,
    String? tipo,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (estado != null && estado != 'todos') params['estado'] = estado;
    if (tipo != null && tipo != 'todos') params['tipo'] = tipo;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    // OPCIÓN A: V2 Módulo Alertas Limpio (Recomendado)
    final uri = Uri.parse(
      '$hostDev/alertas/pdf-url',
    ).replace(queryParameters: params);

    // OPCIÓN B: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/alertas-pdf-url').replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return json.decode(res.body)['url'] as String;
    }
    throw Exception('Error al generar PDF URL (${res.statusCode})');
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 4. LISTAR CXC DEL VENDEDOR AUTENTICADO
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMisCxcPaginated({
    required String token,
    int page = 1,
    String search = '',
    bool vencidos = false,
    bool conAlerta = false,
    String? ordenMonto,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search.isNotEmpty) 'search': search,
      if (vencidos) 'vencidos': '1',
      if (conAlerta) 'con_alerta': '1',
      'orden_monto': ?ordenMonto,
    };

    // OPCIÓN A: V2 Módulo CXC Limpio
    final uri = Uri.parse(
      '$hostDev/vendedor/mis-cxc',
    ).replace(queryParameters: queryParams);

    // OPCIÓN B: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/vendedor/mis-cxc').replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al cargar CXC (${res.statusCode})');
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 5. URL TEMPORAL DEL PDF DE CXC DEL VENDEDOR
  /// ─────────────────────────────────────────────────────────────────────────
  Future<String> obtenerUrlPdfMisCxc({
    required String token,
    String search = '',
    bool vencidos = false,
    bool conAlerta = false,
    String? ordenMonto,
  }) async {
    final queryParams = {
      if (search.isNotEmpty) 'search': search,
      if (vencidos) 'vencidos': '1',
      if (conAlerta) 'con_alerta': '1',
      'orden_monto': ?ordenMonto,
    };

    // OPCIÓN A: V2 Módulo CXC Limpio
    final uri = Uri.parse(
      '$hostDev/vendedor/mis-cxc-pdf-url',
    ).replace(queryParameters: queryParams);

    // OPCIÓN B: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/vendedor/mis-cxc-pdf-url').replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return json.decode(res.body)['url'] as String;
    }
    throw Exception('Error al generar PDF URL (${res.statusCode})');
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 6. DESCARGAR PDF DE CXC DEL VENDEDOR COMO BYTES
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Uint8List> descargarPdfMisCxc({
    required String token,
    String search = '',
    bool vencidos = false,
    bool conAlerta = false,
    String? ordenMonto,
  }) async {
    final uri = Uri.parse('$_base/vendedor/mis-cxc-pdf').replace(
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (vencidos) 'vencidos': '1',
        if (conAlerta) 'con_alerta': '1',
        'orden_monto': ?ordenMonto,
      },
    );

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    throw Exception('Error al descargar el PDF (${res.statusCode})');
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 7. SUBIR EVIDENCIA A UN CXC
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadEvidencia({
    required int cxcId,
    required Uint8List fileBytes,
    required String fileName,
    int? alertaId,
    required String token,
  }) async {
    // OPCIÓN A: V2 Módulo Alertas Limpio (Recomendado)
    final uri = Uri.parse('$hostDev/alertas/$cxcId/evidencia');

    // OPCIÓN B: V2 CXC
    // final uri = Uri.parse('$_baseV2Cxc/$cxcId/evidencia');

    // OPCIÓN C: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/$cxcId/evidencia');

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token))
      ..fields['cxc_id'] = cxcId.toString()
      ..fields['ledhouse_cxc_id'] = cxcId.toString()
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );
    if (alertaId != null) req.fields['alerta_id'] = alertaId.toString();

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201 || streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    }

    try {
      final errorJson = json.decode(body);
      throw Exception(
        errorJson['message'] ??
            errorJson['error'] ??
            'Error al subir evidencia (${streamed.statusCode})',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Error al subir evidencia (${streamed.statusCode}): $body',
      );
    }
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 7.1 OBTENER EVIDENCIAS DE UN CXC
  /// ─────────────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getEvidencias({
    required int cxcId,
    required String token,
  }) async {
    final uri = Uri.parse('$hostDev/alertas/$cxcId/evidencias');
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is List) return decoded;
      return [];
    }
    return [];
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 8. SINCRONIZACIÓN MASIVA (Fase 1 Preview & Fase 2 Confirm)
  /// ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> syncPreview({
    required Uint8List fileBytes,
    required String fileName,
    required String token,
    int? vendedorId,
  }) async {
    // OPCIÓN A: V2 Módulo CXC Limpio
    final uri = Uri.parse('$hostDev/sync-preview');

    // OPCIÓN B: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/sync-preview');

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token));

    if (vendedorId != null) {
      req.fields['vendedor_id'] = vendedorId.toString();
    }

    req.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    }
    throw Exception(
      json.decode(body)['error'] ?? 'Error en preview (${streamed.statusCode})',
    );
  }

  Future<Map<String, dynamic>> syncConfirm({
    required Uint8List fileBytes,
    required String fileName,
    required String token,
    int? vendedorId,
  }) async {
    // OPCIÓN A: V2 Módulo CXC Limpio
    final uri = Uri.parse('$hostDev/sync-confirm');

    // OPCIÓN B: V1 Ledhouse Legacy
    // final uri = Uri.parse('$_base/sync-confirm');

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token));

    if (vendedorId != null) {
      req.fields['vendedor_id'] = vendedorId.toString();
    }

    req.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    }
    throw Exception(
      json.decode(body)['error'] ??
          'Error al confirmar (${streamed.statusCode})',
    );
  }

  /// ─────────────────────────────────────────────────────────────────────────
  /// 9. LISTAR VENDEDORES (Para uso de administración)
  /// ─────────────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getVendedores(String token) async {
    final res = await http.get(
      Uri.parse('$host/api/v1/users'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final List users = json.decode(res.body);
      return users.where((u) {
        final roles = u['roles'] as List? ?? [];
        return roles.any((r) => r['name'] == 'vendedor');
      }).toList();
    }
    throw Exception('Error al cargar vendedores (${res.statusCode})');
  }
}
