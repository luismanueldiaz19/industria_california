import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart';

/// Servicio para sincronizar inventario desde Excel (2 fases: preview → confirm).
/// Mismo patrón que VendedorCxcService.
class InventarioSyncService {
  // host no es const, así que usamos late final
  late final String _base;

  InventarioSyncService()
    : _base = '$host/api/v1/industria-california/inventario/productos';

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// FASE 1 — Analiza el Excel SIN escribir en BD.
  /// Retorna: resumen, errores, nuevos, actualizaciones.
  Future<Map<String, dynamic>> syncPreview({
    required Uint8List fileBytes,
    required String fileName,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/sync-preview');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token))
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    }
    final decoded = json.decode(body) as Map<String, dynamic>;
    throw Exception(
      decoded['error'] ?? decoded['message'] ?? 'Error en preview',
    );
  }

  /// FASE 2 — Confirma la sincronización en transacción atómica.
  /// Si falla hace rollback total en el backend.
  Future<Map<String, dynamic>> syncConfirm({
    required Uint8List fileBytes,
    required String fileName,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/sync-confirm');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(token))
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return json.decode(body) as Map<String, dynamic>;
    }
    final decoded = json.decode(body) as Map<String, dynamic>;
    throw Exception(
      decoded['error'] ??
          decoded['message'] ??
          'Error al confirmar sincronización',
    );
  }
}
