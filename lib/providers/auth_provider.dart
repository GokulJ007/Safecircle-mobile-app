import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

/// Manages authentication state across the app.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.idle;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserData = 'userData';

  Future<bool> login({required String email, required String password}) async {
    _setLoading();
    try {
      final user = await _authService.login(email: email, password: password);
      await _persistSession(user);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading();
    try {
      // Register user on the backend
      await _authService.signup(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      // Immediately log the user in to retrieve JWT access token
      final userWithToken = await _authService.login(email: email, password: password);
      await _persistSession(userWithToken);
      _currentUser = userWithToken;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserData);
    _currentUser = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  /// Restores a persisted session, e.g. on app startup.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return false;

    final userJson = prefs.getString(_keyUserData);
    if (userJson == null) return false;

    _currentUser = UserModel.fromJson(jsonDecode(userJson));
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> updateProfile({required String fullName, required String phone}) async {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      fullName: fullName,
      email: _currentUser!.email,
      phone: phone,
      profileImageUrl: _currentUser!.profileImageUrl,
    );
    await _persistSession(_currentUser!);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.idle;
    }
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }
}