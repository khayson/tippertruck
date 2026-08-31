import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _loading = false;

  AuthProvider(this._api) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  AuthStatus get status => _status;
  User? get user => _user;
  bool get loading => _loading;

  void _handleUnauthorized() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final data = await _api.get('/auth/me');
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } on ApiException {
      await _api.clearToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _api.saveToken(data['token'] as String);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      await _api.saveToken(data['token'] as String);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Logout even if the server call fails
    }

    await _api.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _loading = false;
    notifyListeners();
  }
}
