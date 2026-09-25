import 'package:flutter/foundation.dart';
import '../models/role.dart';
import '../services/role_service.dart';

class RoleProvider extends ChangeNotifier {
  final RoleService _service = RoleService();
  
  List<Role> _roles = [];
  bool _isLoading = false;
  String? _error;

  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRoles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _roles = await _service.getRoles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRole(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final role = await _service.createRole(data);
      _roles.add(role);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRole(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedRole = await _service.updateRole(id, data);
      final index = _roles.indexWhere((r) => r.id == id);
      if (index != -1) {
        _roles[index] = updatedRole;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRole(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteRole(id);
      _roles.removeWhere((r) => r.id == id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
