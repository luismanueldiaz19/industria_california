import '../models/inventario_categoria.dart';
import '../../../services/http_service.dart';

class InventarioCategoriaService {
  final HttpService _http = HttpService();

  Future<List<InventarioCategoria>> getCategorias({String? search, bool soloActivas = true}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (!soloActivas) params['solo_activas'] = 'false';

    final response = await _http.get(
      'industria-california/inventario/categorias',
      params: params,
    );

    if (response is List) {
      return response.map((e) => InventarioCategoria.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<InventarioCategoria> createCategoria(InventarioCategoria categoria) async {
    final response = await _http.post(
      'industria-california/inventario/categorias',
      categoria.toJson(),
    );
    return InventarioCategoria.fromJson(response as Map<String, dynamic>);
  }

  Future<InventarioCategoria> updateCategoria(InventarioCategoria categoria) async {
    final response = await _http.put(
      'industria-california/inventario/categorias/${categoria.id}',
      categoria.toJson(),
    );
    return InventarioCategoria.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteCategoria(int id) async {
    await _http.delete('industria-california/inventario/categorias/$id');
  }
}
