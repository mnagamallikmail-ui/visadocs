import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _tcRequired = false;
  String _activeTcVersion = 'v1.0';
  String? _token;
  String? _email;
  String? _role;
  String? _fullName;
  String? _mobile;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  bool get tcRequired => _tcRequired;
  String get activeTcVersion => _activeTcVersion;
  String? get token => _token;
  String? get email => _email;
  String? get role => _role;
  String? get fullName => _fullName;
  String? get mobile => _mobile;
  int? get userId => _userId;

  /// Returns true if the current user is SUPER_ADMIN or legacy ADMIN
  bool get isSuperAdmin => _role == 'SUPER_ADMIN' || _role == 'ADMIN';

  AuthProvider() {
    _apiService.onTcRequired = (version) {
      _tcRequired = true;
      _activeTcVersion = version;
      notifyListeners();
    };
  }

  void forceTcRequired(String version) {
    _tcRequired = true;
    _activeTcVersion = version;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'];
        _email = data['email'];
        _role = data['role'];
        _fullName = data['fullName'];
        _mobile = data['mobileNumber'];
        _userId = data['id'];
        _apiService.token = _token;
        _isAuthenticated = true;
        _tcRequired = false;

        notifyListeners();
        return true;
      }
    } catch (e) {
      // Handle login failure
    }
    return false;
  }

  Future<bool> register(String email, String password, String role, String mobile, String fullName) async {
    try {
      final response = await _apiService.dio.post('/api/v1/auth/register', data: {
        'email': email,
        'password': password,
        'role': role,
        'mobileNumber': mobile,
        'fullName': fullName,
        'acceptedTcVersion': 'v1.0'
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> acceptTc(String version) async {
    try {
      final response = await _apiService.dio.post('/api/v1/auth/accept-tc', data: {
        'version': version,
      });
      if (response.statusCode == 200) {
        _tcRequired = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Error accepting T&C
    }
    return false;
  }

  void logout() {
    _token = null;
    _email = null;
    _role = null;
    _fullName = null;
    _mobile = null;
    _userId = null;
    _apiService.token = null;
    _isAuthenticated = false;
    _tcRequired = false;
    notifyListeners();
  }
}
