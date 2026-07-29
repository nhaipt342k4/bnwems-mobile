import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService;
  final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.uninitialized;
  AuthUser? _user;
  String? _token;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

  AuthProvider({
    AuthApiService? apiService,
    SecureStorageService? storageService,
  })  : _apiService = apiService ?? AuthApiService(),
        _storageService = storageService ?? SecureStorageService() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await _storageService.getToken();
      final savedUserJson = await _storageService.getUserJson();

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          _user = AuthUser.decode(savedUserJson);
        }

        // Validate or refresh profile with backend
        try {
          final profile = await _apiService.getProfile();
          _user = profile;
          await _storageService.saveUserJson(profile.encode());
        } catch (_) {
          // If offline or network error, keep saved user
        }

        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);
      _token = result.token;
      _user = result.user;

      await _storageService.saveToken(result.token);
      await _storageService.saveUserJson(result.user.encode());

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    await _storageService.clearAll();
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _apiService.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      _user = updatedUser;
      await _storageService.saveUserJson(updatedUser.encode());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword, String confirmNewPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.changePassword(oldPassword, newPassword, confirmNewPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestForgotPassword(String identifier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.forgotPassword(identifier);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
