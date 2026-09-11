import 'package:flutter/foundation.dart';
import '../models/inventario_categoria.dart';
import '../services/inventario_categoria_service.dart';

class InventarioCategoriaProvider with ChangeNotifier {
  final InventarioCategoriaService _service = InventarioCategoriaService();

  List<InventarioCategoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  List<InventarioCategoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategorias() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categorias = await _service.getCategorias();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCategoria(String nombre, {String? descripcion}) async {
    try {
      final nueva = await _service.createCategoria(
        InventarioCategoria(nombre: nombre, descripcion: descripcion),
      );
      _categorias.add(nueva);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategoria(InventarioCategoria categoria) async {
    try {
      final actualizada = await _service.updateCategoria(categoria);
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
