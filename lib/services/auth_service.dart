import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'config_service.dart';

/// Real authentication service communicating with FastAPI backend.
class AuthService {
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ConfigService.backendBaseUrl}/auth/login');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await http.post(url, headers: headers, body: body).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      // Decode error if possible
      try {
        final errData = jsonDecode(response.body);
        throw Exception(errData['detail'] ?? "Login failed");
      } catch (_) {
        throw Exception("Login failed (${response.statusCode}): ${response.body}");
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String;

    // Fetch the user's profile details using the token
    final meUrl = Uri.parse('${ConfigService.backendBaseUrl}/auth/me');
    final meHeaders = {
      'Authorization': 'Bearer $token',
    };
    final meResponse = await http.get(meUrl, headers: meHeaders).timeout(
      const Duration(seconds: 15),
    );

    if (meResponse.statusCode != 200) {
      throw Exception("Failed to fetch user profile: ${meResponse.body}");
    }

    final meData = jsonDecode(meResponse.body) as Map<String, dynamic>;

    return UserModel(
      id: meData['id'] as String,
      fullName: meData['full_name'] as String,
      email: meData['email'] as String,
      phone: meData['phone_number'] as String?,
      token: token,
    );
  }

  Future<UserModel> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final url = Uri.parse('${ConfigService.backendBaseUrl}/auth/register');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone_number': phone,
    });

    final response = await http.post(url, headers: headers, body: body).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 201) {
      try {
        final errData = jsonDecode(response.body);
        throw Exception(errData['detail'] ?? "Registration failed");
      } catch (_) {
        throw Exception("Registration failed (${response.statusCode}): ${response.body}");
      }
    }

    final meData = jsonDecode(response.body) as Map<String, dynamic>;

    return UserModel(
      id: meData['id'] as String,
      fullName: meData['full_name'] as String,
      email: meData['email'] as String,
      phone: meData['phone_number'] as String?,
    );
  }
}