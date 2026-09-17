import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';

class ProductoProvider with ChangeNotifier {
  final ProductoService _service = ProductoService();

  List<Producto> _productos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Paginación
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 5000; // Cargar todo el catálogo de una vez para el POS

  // Filtros activos
  String _search = '';
  int? _categoriaId;
  String _estadoStock = '';
  bool _soloNegativos = false;
  String _orderBy = 'nombre';
  String _orderDir = 'asc';

  // Getters
  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;
  String get search => _search;
  int? get categoriaId => _categoriaId;
  String get estadoStock => _estadoStock;
  bool get soloNegativos => _soloNegativos;
  String get orderBy => _orderBy;
  String get orderDir => _orderDir;

  void setFiltros({
    String? search,
    int? categoriaId,
    String? estadoStock,
    bool? soloNegativos,
    String? orderBy,
    String? orderDir,
  }) {
    _search = search ?? _search;
    _categoriaId = categoriaId;
    _estadoStock = estadoStock ?? _estadoStock;
    _soloNegativos = soloNegativos ?? _soloNegativos;
    _orderBy = orderBy ?? _orderBy;
    _orderDir = orderDir ?? _orderDir;
  }

  void clearFiltros() {
    _search = '';
    _categoriaId = null;
    _estadoStock = '';
    _soloNegativos = false;
    _orderBy = 'nombre';
    _orderDir = 'asc';
  }

  /// Carga la primera página con los filtros actuales
  Future<void> fetchProductos() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _service.getProductos(
        search: _search.isNotEmpty ? _search.toUpperCase() : null,
        categoriaId: _categoriaId,
        estadoStock: _estadoStock.isNotEmpty ? _estadoStock : null,
        soloNegativos: _soloNegativos,
        orderBy: _orderBy,
        orderDir: _orderDir,
        page: 1,
        perPage: _perPage,
      );
      _productos = result['items'] as List<Producto>;
      _currentPage = result['current_page'] as int;
      _lastPage = result['last_page'] as int;
      _total = result['total'] as int;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Carga la siguiente página (infinite scroll / pagination)
  Future<void> fetchMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _service.getProductos(
        search: _search.isNotEmpty ? _search : null,
        categoriaId: _categoriaId,
        estadoStock: _estadoStock.isNotEmpty ? _estadoStock : null,
        soloNegativos: _soloNegativos,
        orderBy: _orderBy,
        orderDir: _orderDir,
        page: nextPage,
        perPage: _perPage,
      );
      _productos.addAll(result['items'] as List<Producto>);
      _currentPage = result['current_page'] as int;
      _lastPage = result['last_page'] as int;
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<bool> createProducto(Producto producto) async {
    try {
      final nuevo = await _service.createProducto(producto);
      _productos.insert(0, nuevo);
      _total++;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProducto(Producto producto) async {
    try {
      final actualizado = await _service.updateProducto(producto);
      final idx = _productos.indexWhere((p) => p.id == producto.id);
      if (idx != -1) _productos[idx] = actualizado;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProducto(int id) async {
    try {
      await _service.deleteProducto(id);
      _productos.removeWhere((p) => p.id == id);
      _total--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImagen(
    int productoId,
    List<int> bytes,
    String filename,
  ) async {
    try {
      final data = await _service.uploadImagen(productoId, bytes, filename);
      final idx = _productos.indexWhere((p) => p.id == productoId);
      if (idx != -1) {
        _productos[idx] = _productos[idx].copyWith(
          imagenProducto: data['imagen_producto'] as String?,
          imagenUrl: data['imagen_url'] as String?,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteImagen(int productoId) async {
    try {
      await _service.deleteImagen(productoId);
      final idx = _productos.indexWhere((p) => p.id == productoId);
      if (idx != -1) {
        _productos[idx] = _productos[idx].copyWith(
          imagenProducto: null,
          imagenUrl: null,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> importExcel(List<int> bytes, String filename) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.importExcel(bytes, filename);
      _isLoading = false;
      await fetchProductos();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> importExcelPorCategoria(
    int categoriaId,
    List<int> bytes,
    String filename,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.importExcelPorCategoria(categoriaId, bytes, filename);
      _isLoading = false;
      await fetchProductos();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> getPdfUrl() async {
    try {
      return await _service.getInventarioPdfUrl(
        search: _search.isNotEmpty ? _search : null,
        categoriaId: _categoriaId,
        estadoStock: _estadoStock.isNotEmpty ? _estadoStock : null,
        orderBy: _orderBy,
        orderDir: _orderDir,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
