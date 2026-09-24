import 'package:flutter/material.dart';
import '../models/chofer.dart';
import '../services/chofer_service.dart';

class ChoferProvider extends ChangeNotifier {
  final ChoferService _service = ChoferService();
  
  List<Chofer> _choferes = [];
  bool _isLoading = false;
  String? _error;

  List<Chofer> get choferes => _choferes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchChoferes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _choferes = await _service.getChoferes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createChofer(Map<String, dynamic> data) async {
    try {
      final newChofer = await _service.createChofer(data);
      _choferes.add(newChofer);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateChofer(int id, Map<String, dynamic> data) async {
    try {
      final updatedChofer = await _service.updateChofer(id, data);
      final index = _choferes.indexWhere((c) => c.id == id);
      if (index != -1) {
        _choferes[index] = updatedChofer;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteChofer(int id) async {
    try {
      await _service.deleteChofer(id);
      _choferes.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
