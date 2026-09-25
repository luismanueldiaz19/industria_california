import '../../../core/services/http_service.dart';
import '../models/role.dart';

class RoleService {
  final HttpService _http = HttpService();
  static const String _base = 'industria-california/roles';

  Future<List<Role>> getRoles() async {
    final response = await _http.get(_base);
    final List data = response is List ? response : [];
    return data.map((json) => Role.fromJson(json)).toList();
  }

  Future<Role> getRole(int id) async {
    final response = await _http.get('$_base/$id');
    return Role.fromJson(response);
  }

  Future<Role> createRole(Map<String, dynamic> data) async {
    final response = await _http.post(_base, data);
    return Role.fromJson(response);
  }

  Future<Role> updateRole(int id, Map<String, dynamic> data) async {
    final response = await _http.put('$_base/$id', data);
    return Role.fromJson(response);
  }

  Future<void> deleteRole(int id) async {
    await _http.delete('$_base/$id');
  }
}
