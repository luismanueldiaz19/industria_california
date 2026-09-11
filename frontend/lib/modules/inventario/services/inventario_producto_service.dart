import 'package:http/http.dart' as http;
import '../models/inventario_producto.dart';
import '../../../services/http_service.dart';

class InventarioProductoService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/inventario/productos';

  /// Obtiene página paginada de productos
  Future<Map<String, dynamic>> getProductos({
    String? search,
    int? categoriaId,
    String? estadoStock,
    bool soloNegativos = false,
    String orderBy = 'nombre',
    String orderDir = 'asc',
    int page = 1,
    int perPage = 24,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'order_by': orderBy,
      'order_dir': orderDir,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoriaId != null) params['categoria_id'] = categoriaId.toString();
    if (estadoStock != null && estadoStock.isNotEmpty) params['estado_stock'] = estadoStock;
    if (soloNegativos) params['solo_negativos'] = 'true';

    final response = await _http.get(_base, params: params);
    final data = response as Map<String, dynamic>;

    final items = (data['data'] as List? ?? [])
        .map((e) => InventarioProducto.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'items': items,
      'current_page': data['current_page'] ?? 1,
      'last_page': data['last_page'] ?? 1,
      'total': data['total'] ?? 0,
    };
  }

  Future<InventarioProducto> createProducto(InventarioProducto producto) async {
    final response = await _http.post(_base, producto.toJson());
    return InventarioProducto.fromJson(response as Map<String, dynamic>);
  }

  Future<InventarioProducto> updateProducto(InventarioProducto producto) async {
    final response = await _http.put('$_base/${producto.id}', producto.toJson());
    return InventarioProducto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteProducto(int id) async {
    await _http.delete('$_base/$id');
  }

  /// Sube imagen del producto (comprimida en el backend a JPEG 80%, max 800x800)
  Future<Map<String, dynamic>> uploadImagen(int productoId, List<int> bytes, String filename) async {
    final file = http.MultipartFile.fromBytes('imagen', bytes, filename: filename);
    final response = await _http.multipart('$_base/$productoId/imagen', files: [file]);
    return response as Map<String, dynamic>;
  }

  Future<void> deleteImagen(int productoId) async {
    await _http.delete('$_base/$productoId/imagen');
  }

  Future<Map<String, dynamic>> importExcel(List<int> bytes, String filename) async {
    final file = http.MultipartFile.fromBytes('file', bytes, filename: filename);
    final response = await _http.multipart(
      'industria-california/inventario/productos/import',
      files: [file],
    );
    return response as Map<String, dynamic>;
  }

  Future<String?> getInventarioPdfUrl({
    String? search,
    int? categoriaId,
    String? estadoStock,
    String orderBy = 'nombre',
    String orderDir = 'asc',
  }) async {
    final params = <String, String>{'order_by': orderBy, 'order_dir': orderDir};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoriaId != null) params['categoria_id'] = categoriaId.toString();
    if (estadoStock != null && estadoStock.isNotEmpty) params['estado_stock'] = estadoStock;

    final response = await _http.get(
      'industria-california/inventario/productos-pdf-url',
      params: params,
    );
    return response?['url'] as String?;
  }
}
