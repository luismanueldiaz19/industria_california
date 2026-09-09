import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart';

class VendedorCxcService {
  final String _base = '$host/api/v1/ledhouse/cxc';

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Fase 1 — Preview sin escritura en BD
  Future<Map<String, dynamic>> syncPreview({
    required Uint8List fileBytes,
    required String fileName,
    required String token,
    int? vendedorId,
  }) async {
    final uri = Uri.parse('$_base/sync-preview');
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
    throw Exception(json.decode(body)['error'] ?? 'Error en preview');
  }

  /// Fase 2 — Confirmar sincronización (transacción atómica)
  Future<Map<String, dynamic>> syncConfirm({
    required Uint8List fileBytes,
    required String fileName,
    required String token,
    int? vendedorId,
  }) async {
    final uri = Uri.parse('$_base/sync-confirm');
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
    throw Exception(json.decode(body)['error'] ?? 'Error al confirmar');
  }

  /// Lista los CXC del vendedor autenticado (paginado)
  Future<Map<String, dynamic>> getMisCxcPaginated({
    required String token,
    int page = 1,
    String search = '',
    bool vencidos = false,
    bool conAlerta = false,
  }) async {
    final uri = Uri.parse('$_base/vendedor/mis-cxc').replace(
      queryParameters: {
        'page': page.toString(),
        if (search.isNotEmpty) 'search': search,
        if (vencidos) 'vencidos': '1',
        if (conAlerta) 'con_alerta': '1',
      },
    );

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al cargar CXC');
  }

  /// Obtener URL temporal del PDF de CXC del vendedor
  Future<String> obtenerUrlPdfMisCxc({
    required String token,
    String search = '',
    bool vencidos = false,
    bool conAlerta = false,
  }) async {
    final uri = Uri.parse('$_base/vendedor/mis-cxc-pdf-url').replace(
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (vencidos) 'vencidos': '1',
        if (conAlerta) 'con_alerta': '1',
      },
    );

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return json.decode(res.body)['url'] as String;
    }
    throw Exception('Error al generar PDF URL');
  }

  /// Descargar PDF de CXC del vendedor como bytes
  Future<Uint8List> descargarPdfMisCxc({
    required String token,
    String search = '',
    bool vencidos = false,
    bool conAlerta = false,
  }) async {
    final uri = Uri.parse('$_base/vendedor/mis-cxc-pdf').replace(
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (vencidos) 'vencidos': '1',
        if (conAlerta) 'con_alerta': '1',
      },
    );

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    throw Exception('Error al descargar el PDF');
  }

  /// Obtener alertas del vendedor (y opcionalmente por estado)
  Future<List<dynamic>> getMisAlertas({
    required String token,
    String? estado,
  }) async {
    final uri = Uri.parse(
      '$_base/alertas',
    ).replace(queryParameters: {if (estado != null) 'estado': estado});
    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode == 200) {
      return json.decode(res.body) as List;
    }
    throw Exception('Error al cargar alertas');
  }

  /// Lista los vendedores (para uso del admin)
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
    throw Exception('Error al cargar vendedores');
  }

  /// Agregar alerta a un CXC
  Future<Map<String, dynamic>> addAlerta({
    required int cxcId,
    required String tipo,
    required String nota,
    double? montoInformado,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/$cxcId/alerta'),
      headers: {..._headers(token), 'Content-Type': 'application/json'},
      body: json.encode({
        'tipo': tipo,
        'nota': nota,
        if (montoInformado != null) 'monto_informado': montoInformado,
      }),
    );
    if (res.statusCode == 201)
      return json.decode(res.body) as Map<String, dynamic>;
    throw Exception('Error al agregar alerta');
  }

  /// Subir evidencia a un CXC
  Future<Map<String, dynamic>> uploadEvidencia({
    required int cxcId,
    required Uint8List fileBytes,
    required String fileName,
    int? alertaId,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/$cxcId/evidencia');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token))
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );
    if (alertaId != null) req.fields['alerta_id'] = alertaId.toString();

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201) {
      return json.decode(body) as Map<String, dynamic>;
    }
    throw Exception('Error al subir evidencia');
  }
}
