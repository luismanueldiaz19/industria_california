import 'package:flutter/foundation.dart';
import '../models/categoria.dart';
import '../services/categoria_service.dart';

class CategoriaProvider with ChangeNotifier {
  final CategoriaService _service = CategoriaService();

  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategorias({
    String? search,
    bool soloActivas = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categorias = await _service.getCategorias(
        search: search,
        soloActivas: soloActivas,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCategoria(Categoria categoria, {List<int>? imageBytes, String? imageName}) async {
    try {
      var nueva = await _service.createCategoria(categoria);
      if (imageBytes != null && imageName != null) {
        nueva = await _service.uploadImagen(nueva.id!, imageBytes, imageName);
      }
      _categorias.add(nueva);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategoria(Categoria categoria, {List<int>? imageBytes, String? imageName}) async {
    try {
      var actualizada = await _service.updateCategoria(categoria);
      if (imageBytes != null && imageName != null) {
        actualizada = await _service.uploadImagen(actualizada.id!, imageBytes, imageName);
      }
      final idx = _categorias.indexWhere((c) => c.id == categoria.id);
      if (idx != -1) _categorias[idx] = actualizada;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategoria(int id) async {
    try {
      await _service.deleteCategoria(id);
      _categorias.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
