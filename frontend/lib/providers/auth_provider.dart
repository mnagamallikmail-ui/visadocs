import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

class LoginResult {
  final bool success;
  final bool mfaSetupRequired;
  final bool mfaRequired;
  final String? setupToken;
  final String? secretKey;
  final String? otpAuthUri;
  final List<String> recoveryCodes;
  final String? mfaToken;
  final String? message;
  final String? errorMessage;

  const LoginResult({
    this.success = false,
    this.mfaSetupRequired = false,
    this.mfaRequired = false,
    this.setupToken,
    this.secretKey,
    this.otpAuthUri,
    this.recoveryCodes = const [],
    this.mfaToken,
    this.message,
    this.errorMessage,
  });

  factory LoginResult.completed() => const LoginResult(success: true);

  factory LoginResult.mfaSetup({
    required String? setupToken,
    required String? secretKey,
    required String? otpAuthUri,
    required List<String> recoveryCodes,
    String? message,
  }) => LoginResult(
    mfaSetupRequired: true,
    setupToken: setupToken,
    secretKey: secretKey,
    otpAuthUri: otpAuthUri,
    recoveryCodes: recoveryCodes,
    message: message,
  );

  factory LoginResult.mfaChallenge({
    required String? mfaToken,
    String? message,
  }) => LoginResult(
    mfaRequired: true,
    mfaToken: mfaToken,
    message: message,
  );

  factory LoginResult.failed(String error) => LoginResult(errorMessage: error);
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _tcRequired = false;
  String _activeTcVersion = 'v1.0';
  String? _token;
  String? _username;
  String? _email;
  String? _role;
  String? _fullName;
  String? _mobile;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  bool get tcRequired => _tcRequired;
  String get activeTcVersion => _activeTcVersion;
  String? get token => _token;
  String? get username => _username;
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

    // Restore persistent session from storage
    final session = TokenStorage.loadSession();
    final savedToken = session['token'] as String?;
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      _username = session['username'];
      _email = session['email'];
      _role = session['role'];
      _fullName = session['fullName'];
      _mobile = session['mobile'];
      _userId = session['userId'];
      _apiService.token = _token;
      _isAuthenticated = true;
    }
  }

  void forceTcRequired(String version) {
    _tcRequired = true;
    _activeTcVersion = version;
    notifyListeners();
  }

  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await _apiService.dio.post('/api/v1/auth/login', data: {
        'username': username.trim(),
        'email': username.trim(),
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        // 1. Mandatory MFA Enrollment Required for Privileged Accounts
        if (data['mfaSetupRequired'] == true) {
          final recoveryCodesRaw = data['recoveryCodes'];
          final recoveryCodes = recoveryCodesRaw is List
              ? List<String>.from(recoveryCodesRaw.map((e) => e.toString()))
              : <String>[];
          return LoginResult.mfaSetup(
            setupToken: data['setupToken']?.toString(),
            secretKey: data['secretKey']?.toString(),
            otpAuthUri: data['otpAuthUri']?.toString(),
            recoveryCodes: recoveryCodes,
            message: data['message']?.toString(),
          );
        }

        // 2. Standard MFA Verification Challenge
        if (data['mfaRequired'] == true) {
          return LoginResult.mfaChallenge(
            mfaToken: data['mfaToken']?.toString(),
            message: data['message']?.toString(),
          );
        }

        // 3. Direct Session Authentication Succeeded (e.g. CLIENT role)
        if (data['token'] != null) {
          _applySuccessfulLogin(data, username);
          return LoginResult.completed();
        }
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          return LoginResult.failed('Rate limit exceeded (Max 5 attempts/minute). Please wait 60 seconds.');
        } else if (e.response?.statusCode == 423) {
          return LoginResult.failed('Account temporarily locked due to consecutive failed attempts.');
        } else if (e.response?.statusCode == 401) {
          return LoginResult.failed('Invalid username or password.');
        }
      }
      return LoginResult.failed('Login failed. Please verify network connectivity.');
    }
    return LoginResult.failed('Invalid credentials.');
  }

  Future<bool> confirmMfaSetup({
    required String setupToken,
    required String secretKey,
    required String verificationCode,
    required List<String> recoveryCodes,
  }) async {
    try {
      final response = await _apiService.dio.post('/api/v1/auth/mfa/confirm-setup', data: {
        'setupToken': setupToken,
        'secretKey': secretKey,
        'verificationCode': verificationCode.trim(),
        'recoveryCodes': recoveryCodes,
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        _applySuccessfulLogin(data, data['username']?.toString() ?? '');
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> verifyMfa({
    required String mfaToken,
    required String code,
  }) async {
    try {
      final response = await _apiService.dio.post('/api/v1/auth/mfa/verify', data: {
        'mfaToken': mfaToken,
        'code': code.trim(),
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        _applySuccessfulLogin(data, data['username']?.toString() ?? '');
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _applySuccessfulLogin(Map<String, dynamic> data, String fallbackUsername) {
    _token = data['token'];
    _username = data['username'] ?? fallbackUsername.trim();
    _email = data['email'];
    _role = data['role'];
    _fullName = data['fullName'];
    _mobile = data['mobileNumber'];
    _userId = data['id'];
    _apiService.token = _token;
    _isAuthenticated = true;
    _tcRequired = false;

    if (_token != null) {
      TokenStorage.saveSession(
        token: _token!,
        username: _username,
        email: _email,
        role: _role,
        fullName: _fullName,
        mobile: _mobile,
        userId: _userId,
      );
    }
    notifyListeners();
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
    _username = null;
    _email = null;
    _role = null;
    _fullName = null;
    _mobile = null;
    _userId = null;
    _apiService.token = null;
    _isAuthenticated = false;
    _tcRequired = false;
    TokenStorage.clearSession();
    notifyListeners();
  }
}
