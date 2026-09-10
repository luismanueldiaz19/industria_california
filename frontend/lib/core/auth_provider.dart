import 'package:flutter/material.dart';
import '../services/http_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _username;
  String? _name;
  String? _profilePhotoUrl;
  List<String> _roles = [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get username => _username;
  String? get name => _name;
  String? get profilePhotoUrl => _profilePhotoUrl;
  List<String> get roles => _roles;
  
  String? get token => HttpService.token;
  
  bool get isVendedor => _roles.contains('vendedor');
  bool get isAdmin => _roles.contains('admin');

  final HttpService _httpService = HttpService();

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final trimmedUsername = username.trim();
    final trimmedPassword = password.trim();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
      _errorMessage = "Por favor, complete todos los campos.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await _httpService.post('login', {
        'username': trimmedUsername,
        'password': trimmedPassword,
      });

      if (response != null && response['token'] != null) {
        HttpService.token = response['token'];
        _isAuthenticated = true;
        _username = response['user']['username'] ?? trimmedUsername;
        _name = response['user']['name'];
        _profilePhotoUrl = response['user']['profile_photo_url'];
        if (response['user']['roles'] != null) {
          _roles = List<String>.from(response['user']['roles']);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Respuesta del servidor inválida.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerUser(String name, String username, String password, String? role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _httpService.post('register', {
        'name': name.trim(),
        'username': username.trim(),
        'password': password.trim(),
        if (role != null) 'role': role,
      });

      if (response != null && response['user'] != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Error al registrar el usuario.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (HttpService.token != null) {
        await _httpService.post('logout', {});
      }
    } catch (_) {
      // Ignorar errores de logout del servidor para asegurar que el frontend cierre sesión de todos modos
    } finally {
      HttpService.token = null;
      _isAuthenticated = false;
      _username = null;
      _name = null;
      _profilePhotoUrl = null;
      _roles = [];
      notifyListeners();
    }
  }

  void updateProfileData({String? newName, String? newPhotoUrl}) {
    if (newName != null) _name = newName;
    if (newPhotoUrl != null) _profilePhotoUrl = newPhotoUrl;
    notifyListeners();
  }

  Future<bool> sendResetCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simular retraso de red de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      _errorMessage = "Por favor, ingrese su correo electrónico.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simular retraso de red de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    final trimmedCode = code.trim();
    final trimmedPassword = newPassword.trim();

    if (trimmedCode.isEmpty || trimmedPassword.isEmpty) {
      _errorMessage = "Por favor, complete todos los campos.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (trimmedCode.length != 6) {
      _errorMessage = "El código de seguridad debe tener 6 dígitos.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (trimmedPassword.length < 6) {
      _errorMessage = "La contraseña debe tener al menos 6 caracteres.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
