import 'package:flutter/foundation.dart';
import '../models/ruta.dart';
import '../services/ruta_service.dart';

class RutaProvider extends ChangeNotifier {
  final RutaService _service = RutaService();
  
  List<Ruta> _rutas = [];
  bool _isLoading = false;
  String? _error;

  List<Ruta> get rutas => _rutas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRutas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rutas = await _service.getRutas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRuta(Map<String, dynamic> data) async {
    try {
      final nueva = await _service.createRuta(data);
      _rutas.add(nueva);
      _rutas.sort((a, b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRuta(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateRuta(id, data);
      final index = _rutas.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Just refetch to keep it simple and synchronized
        await fetchRutas();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRuta(int id) async {
    try {
      await _service.deleteRuta(id);
      _rutas.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
