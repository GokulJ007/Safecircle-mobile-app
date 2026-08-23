import '../models/user_model.dart';

/// Mock authentication service.
/// Simulates network latency and validation until FastAPI backend is ready.
class AuthService {
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock validation — any well-formed credentials succeed.
    if (password.length < 6) {
      throw Exception('Invalid email or password');
    }

    return UserModel(
      id: 'mock-user-001',
      fullName: 'Alex Morgan',
      email: email,
      phone: '+1 555 010 2030',
    );
  }

  Future<UserModel> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    return UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: phone,
    );
  }
}