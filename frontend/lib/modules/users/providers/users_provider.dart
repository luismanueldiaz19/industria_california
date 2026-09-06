import 'package:flutter/material.dart';
import '../../../services/http_service.dart';

class UsersProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();
  
  List<dynamic> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _httpService.get('users');
      if (response != null && response is List) {
        _users = response;
      } else {
        _errorMessage = 'Formato de respuesta inválido';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await _httpService.delete('users/$id');
      if (response != null) {
        _users.removeWhere((user) => user['id'] == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error al eliminar usuario: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(int id, String name, String username, String? password, String? role) async {
    try {
      final response = await _httpService.put('users/$id', {
        'name': name.trim(),
        'username': username.trim(),
        if (password != null && password.isNotEmpty) 'password': password.trim(),
        if (role != null) 'role': role,
      });

      if (response != null) {
        await fetchUsers(); // Recargar la lista completa
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error al actualizar usuario: $e';
      notifyListeners();
      return false;
    }
  }
}
