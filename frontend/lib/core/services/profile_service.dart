import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:industria_california/services/http_service.dart';
import '../constants.dart';

class ProfileService {
  final String _base = '$host/api/v1';

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    final token = HttpService.token;
    if (token == null) throw Exception('No hay token de sesión.');

    final uri = Uri.parse('$_base/perfil/actualizar');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    if (name != null && name.isNotEmpty) {
      req.fields['name'] = name;
    }
    if (currentPassword != null && currentPassword.isNotEmpty) {
      req.fields['current_password'] = currentPassword;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      req.fields['new_password'] = newPassword;
    }

    if (photoBytes != null && photoName != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'profile_photo',
          photoBytes,
          filename: photoName,
        ),
      );
    }

    final streamedResponse = await req.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    final jsonResponse = json.decode(responseBody);

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      return jsonResponse;
    } else {
      throw Exception(
        jsonResponse['error'] ??
            jsonResponse['message'] ??
            'Error al actualizar perfil',
      );
    }
  }
}
