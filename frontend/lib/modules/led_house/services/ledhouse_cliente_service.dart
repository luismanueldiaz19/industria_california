import 'package:http/http.dart' as http;
import '../models/ledhouse_cliente.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/text_normalizer.dart';

class LedhouseClienteService {
  final HttpService _http = HttpService();

  //   /api/v2/clientes
  // Listar clientes	GET	/api/v2/clientes
  // Ver cliente	GET	/api/v2/clientes/{id}
  // Actualizar cliente	PUT / PATCH	/api/v2/clientes/{id}
  // Eliminar cliente	DELETE	/api/v2/clientes/{id}
  // Importar Excel	POST	/api/v2/clientes/import

  Future<List<LedhouseCliente>> getClientes({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = TextNormalizer.normalizar(search);
    }

    final response = await _http.getV2('clientes', params: queryParams);

    if (response != null) {
      return (response as List)
          .map((item) => LedhouseCliente.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<LedhouseCliente> createCliente(LedhouseCliente cliente) async {
    final response = await _http.postV2('clientes', cliente.toJson());
    return LedhouseCliente.fromJson(response);
  }

  Future<LedhouseCliente> updateCliente(LedhouseCliente cliente) async {
    final response = await _http.putV2(
      'clientes/${cliente.id}',
      cliente.toJson(),
    );
    return LedhouseCliente.fromJson(response);
  }

  Future<void> deleteCliente(int id) async {
    await _http.deleteV2('clientes/$id');
  }

  Future<Map<String, dynamic>> importExcel(
    List<int> fileBytes,
    String filename,
  ) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
    );

    final response = await _http.multipartV2('clientes/import', files: [file]);

    return response as Map<String, dynamic>;
  }
}
