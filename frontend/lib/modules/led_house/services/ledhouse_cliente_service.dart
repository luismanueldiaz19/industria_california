import 'package:http/http.dart' as http;
import '../models/ledhouse_cliente.dart';
import '../../../services/http_service.dart';
import '../../../core/utils/text_normalizer.dart';

class LedhouseClienteService {
  final HttpService _http = HttpService();

  Future<List<LedhouseCliente>> getClientes({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = TextNormalizer.normalizar(search);
    }

    final response = await _http.get('ledhouse/clientes', params: queryParams);

    if (response != null) {
      return (response as List)
          .map((item) => LedhouseCliente.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getPaginatedClientes({String? search, int page = 1, String sort = 'recent'}) async {
    final queryParams = <String, String>{
      'paginate': 'true',
      'page': page.toString(),
      'sort': sort,
    };
    
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = TextNormalizer.normalizar(search);
    }

    final response = await _http.get('ledhouse/clientes', params: queryParams);

    if (response != null && response is Map<String, dynamic>) {
      final List<dynamic> dataList = response['data'] ?? [];
      return {
        'data': dataList.map((item) => LedhouseCliente.fromJson(item)).toList(),
        'current_page': response['current_page'] ?? 1,
        'last_page': response['last_page'] ?? 1,
        'total': response['total'] ?? 0,
      };
    }
    
    return {
      'data': <LedhouseCliente>[],
      'current_page': 1,
      'last_page': 1,
      'total': 0,
    };
  }

  Future<LedhouseCliente> createCliente(LedhouseCliente cliente) async {
    final response = await _http.post('ledhouse/clientes', cliente.toJson());
    return LedhouseCliente.fromJson(response);
  }

  Future<LedhouseCliente> updateCliente(LedhouseCliente cliente) async {
    final response = await _http.put(
      'ledhouse/clientes/${cliente.id}',
      cliente.toJson(),
    );
    return LedhouseCliente.fromJson(response);
  }

  Future<void> deleteCliente(int id) async {
    await _http.delete('ledhouse/clientes/$id');
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

    final response = await _http.multipart(
      'ledhouse/clientes/import',
      files: [file],
    );

    return response as Map<String, dynamic>;
  }
}
