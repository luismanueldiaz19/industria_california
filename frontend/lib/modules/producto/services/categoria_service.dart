import '../models/categoria.dart';
import '../../../core/services/http_service.dart';

class CategoriaService {
  final HttpService _http = HttpService();
  static const String _base = 'categorias';

  Future<List<Categoria>> getCategorias({
    String? search,
    bool soloActivas = true,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (!soloActivas) params['solo_activas'] = 'false';

    final response = await _http.get(_base, params: params);

    if (response is List) {
      return response
          .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Categoria> createCategoria(Categoria categoria) async {
    final response = await _http.post(_base, categoria.toJson());
    return Categoria.fromJson(response as Map<String, dynamic>);
  }

  Future<Categoria> updateCategoria(Categoria categoria) async {
    final response = await _http.put(
      '$_base/${categoria.id}',
      categoria.toJson(),
    );
    return Categoria.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteCategoria(int id) async {
    await _http.delete('$_base/$id');
  }

  Future<Categoria> uploadImagen(int id, List<int> bytes, String filename) async {
    final response = await _http.uploadFile(
      '$_base/$id/imagen',
      bytes,
      filename,
      fieldName: 'imagen',
    );
    return Categoria.fromJson(response as Map<String, dynamic>);
  }
}
